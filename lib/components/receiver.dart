import 'dart:async';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharem/components/accept_dialog.dart';
import 'package:sharem/components/progresses_widget.dart';
import 'package:sharem/services/prefs.dart';
import 'package:sharem_cli/sharem_cli.dart';
import 'package:sharem_cli/unique_name.dart';

const maxHistoryReceivedTexts = 50;
const purgeCountHistoryReceivedTexts = maxHistoryReceivedTexts ~/ 2;

class ReceiverWidget extends StatefulWidget {
  const ReceiverWidget({super.key});

  @override
  State<ReceiverWidget> createState() => _ReceiverWidgetState();
}

class _ReceiverWidgetState extends State<ReceiverWidget> {
  final _sc = ScrollController();
  final _tc = TextEditingController(text: generateUniqueName());

  final Map<String, Progress> _progresses = {};

  var receivedTexts = <String>[];

  Timer? _broadcastTimer;
  HttpServer? _server;

  bool get isReceiving => _broadcastTimer != null && _server != null;

  @override
  void dispose() {
    stopReceiving();
    super.dispose();
    _tc.dispose();
    _sc.dispose();

    SharedPreferences.getInstance()
        .then((prefs) => prefs.setStringList("receivedTexts", receivedTexts));
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await loadPreferences();
    await startReceiving();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _tc.text = (await getOrSetUniqueName(generateUniqueName()))!;
    receivedTexts = prefs.getStringList("receivedTexts") ?? [];
    setState(() {
      Future.delayed(
          const Duration(milliseconds: 20),
          () => _sc.animateTo(_sc.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn));
    });
  }

  Future<void> addReceivedText(
      String uniqueName, InternetAddress address, String text) async {
    if (receivedTexts.length > maxHistoryReceivedTexts) {
      receivedTexts = receivedTexts
          .sublist(receivedTexts.length - purgeCountHistoryReceivedTexts);
    }
    setState(() {
      receivedTexts.add(text);
      _sc.animateTo(_sc.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("receivedTexts", receivedTexts);
  }

  Future<void> startReceiving() async {
    SharemFileShareRequest? pendingRequest;

    final callbacks = ServerCallbacks(
        onTextCallback: addReceivedText,
        onFileCallback: (String uniqueName, String uniqueCode,
            SharemFile sharemFile) async {
          if (pendingRequest == null) {
            debugPrint("No Active Request");
            return;
          }

          final fileName = sharemFile.fileName;
          final fileLength = await sharemFile.fileLength();
          if (pendingRequest!.fileNameAndLength[fileName] != fileLength ||
              pendingRequest!.uniqueCode != uniqueCode) {
            debugPrint(
                "FIle Lengths mismatch expected: ${pendingRequest!.fileNameAndLength[fileName]} observed: $fileLength");
            return;
          }

          Directory? directory;

          if (Platform.isAndroid) {
            directory = Directory(
                await ExternalPath.getExternalStoragePublicDirectory(
                    ExternalPath.DIRECTORY_DOWNLOADS));
          } else {
            directory = await getDownloadsDirectory();
          }

          directory ??= await getApplicationDocumentsDirectory();

          if (!(await directory.exists())) {
            await directory.create(recursive: true);
          }

          final file = File(p.join(directory.path, fileName));
          final sink = file.openWrite();
          final stream = sharemFile.asStream(
              progressCallback: (progress) =>
                  setState(() => _progresses[fileName] = progress));
          try {
            await sink.addStream(stream);
            await sink.flush();
            await sink.close();

            final s = "Saved File ${file.path}";
            debugPrint(s);

            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(s)));
            }

            if (_progresses.values.every((e) => e.isComplete())) {
              pendingRequest = null;
            }
          } catch (err) {
            debugPrint("Failed to Receive File ${file.path} $err");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Failed to Receive File ${file.path}")));
            }
            await sink.close();
            await file.delete();

            setState(() {
              pendingRequest = null;
              _progresses.clear();
            });
          }
        },
        onFileShareRequest: (SharemFileShareRequest request) async {
          if (pendingRequest != null) {
            final content =
                "Ignoring request from ${request.uniqueName} because already in a transaction with ${pendingRequest!.uniqueName}";
            debugPrint("WARN: $content");
            return false;
          }

          for (final fileName in request.fileNameAndLength.keys) {
            if (!isValidFileName(fileName)) {
              final content =
                  "Rejected a File Share Request because of potential dangerous filename '$fileName'";
              debugPrint("WARN: $content");
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(content)));
              return false;
            }
          }

          if (!mounted) {
            return false;
          }

          final result = await showDialog(
              context: context,
              builder: (context) => AcceptDialog(request: request));
          if (result is bool && result) {
            pendingRequest = request;
            _progresses.clear();

            setState(() {
              for (final entry in request.fileNameAndLength.entries) {
                _progresses[entry.key] = Progress(entry.value);
              }
            });

            return true;
          }

          return false;
        });

    final server = await startHttpServer(0, callbacks: callbacks);
    debugPrint("Started Server at ${server.address.host}:${server.port}");
    final uniqueName = _tc.text.isNotEmpty ? _tc.text : generateUniqueName();
    final message = SharemPeerMessage(server.port, uniqueName, myHash).toJSON();
    final timer = Timer.periodic(const Duration(seconds: 1),
        (_) => sendBroadcast(message, InternetAddress("255.255.255.255")));
    setState(() {
      _server = server;
      _broadcastTimer = timer;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("uniqueName", uniqueName);
  }

  void stopReceiving() {
    setState(() {
      _broadcastTimer?.cancel();
      _broadcastTimer = null;
      _server?.close();
      _server = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          child: Text(isReceiving ? "Stop Receiving" : "Start Receiving"),
          onPressed: () async {
            if (isReceiving) {
              stopReceiving();
            } else {
              startReceiving();
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Text("Unique Name: "),
              Expanded(
                child: TextField(
                  enabled: !isReceiving,
                  controller: _tc,
                  onTap: () {
                    if (isReceiving) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Stop Receiving to change your name"),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ProgressesWidget(
            progresses: Map.unmodifiable(_progresses),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _sc,
            reverse: true,
            shrinkWrap: true,
            itemCount: receivedTexts.length,
            itemBuilder: (context, i) => ListTile(
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() => receivedTexts.removeAt(i)),
              ),
              title: Text(receivedTexts[i]),
              onTap: () =>
                  Clipboard.setData(ClipboardData(text: receivedTexts[i])),
            ),
          ),
        )
      ],
    );
  }
}
