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
    super.dispose();
    stopReceiving();
    _tc.dispose();
    _sc.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _tc.text = prefs.getString("uniqueName") ?? _tc.text;
    receivedTexts = prefs.getStringList("receivedTexts") ?? [];
    setState(() {
      Future.delayed(
          const Duration(milliseconds: 20),
          () => _sc.animateTo(_sc.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn));
    });
  }

  Future<void> addReceivedText(String text) async {
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
        onFileCallback:
            (String fileName, int fileLength, Stream<List<int>> stream) async {
          if (pendingRequest == null) {
            debugPrint("No Active Request");
            return;
          }

          if (pendingRequest!.fileNameAndLength[fileName] != fileLength) {
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
          try {
            await for (final chunk in stream) {
              sink.add(chunk);
              setState(() {
                _progresses[fileName]?.addProgress(chunk.length);
              });
            }

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

            pendingRequest = null;
          }
        },
        onFileShareRequest: (SharemFileShareRequest request) async {
          if (pendingRequest != null) {
            debugPrint(
                "WARN: Ignoring request from ${request.uniqueName} because already in a transaction with ${pendingRequest!.uniqueName}");
            return false;
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
    final message = SharemPeerMessage(server.port, uniqueName).toJSON();
    final timer = Timer.periodic(const Duration(seconds: 1),
        (_) => sendBroadcast(message, InternetAddress("255.255.255.255")));
    setState(() {
      _server = server;
      _broadcastTimer = timer;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("uniqueName", uniqueName);
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
        Row(
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
        Expanded(
          child: ProgressesWidget(
            progresses: Map.unmodifiable(_progresses),
          ),
          // child: Builder(
          // builder: (context) {
          // final entries = _progresses.entries.toList();

          // return ListView.builder(
          //     itemCount: entries.length,
          //     itemBuilder: (context, i) {
          //       final progress = entries[i].value;
          //       final value =
          //           progress.bytesTransferred / progress.totalBytes;
          //       return Padding(
          //         padding: const EdgeInsets.all(8.0),
          //         child: Column(children: [
          //           Text("${entries[i].key} ${progress.toPrettyString()}"),
          //           LinearProgressIndicator(
          //             value: value,
          //           )
          //         ]),
          //       );
          //     });
          // },
          // ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _sc,
            reverse: true,
            shrinkWrap: true,
            itemCount: receivedTexts.length,
            itemBuilder: (context, i) => ListTile(
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
