// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:sharem/bin/server.dart';
import 'package:sharem/screens/recieved_files.dart';
import 'package:sharem/screens/recieving_files.dart';
import 'package:sharem/utils/show_snackbar.dart';
import 'package:sharem/widgets/connection.dart';
import 'package:sharem/widgets/local_ip_address.dart';
import 'package:sharem/widgets/send_files.dart';
import 'package:shelf/shelf.dart';

class HomePage extends StatefulWidget {
  final Directory dir;
  final GlobalKey<RecievingFilesState> downloadsKey;
  final GlobalKey<RecievedFilesState> downloadedKey;
  const HomePage(
      {Key? key,
      required this.dir,
      required this.downloadsKey,
      required this.downloadedKey})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  VoidCallback? stopServer;
  final connectionDetailsKey = GlobalKey<ConnectionDetailsState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    stopServer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Center(child: Text(stopServer != null ? 'Online' : 'Offline')),
      LocalIpAddress(onReset: onReset),
      ConnectionDetails(key: connectionDetailsKey),
      ElevatedButton(
          onPressed: syncClipBoard,
          child: const Text('Sync Last Copied Value From Clipboard')),
      SendFilesButton(sendFiles: sendFiles),
    ]);
  }

  void syncClipBoard() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null) {
      sendTextToClipboard(data.text!);
    }
  }

  String getUrl() {
    final state = connectionDetailsKey.currentState!;
    final ipAddr = state.ipController.text;
    final port = state.portController.text;
    return "http://$ipAddr:$port";
  }

  void onReset([int? port]) async {
    stopServer?.call();
    setState(() {
      stopServer = null;
    });

    if (port != null) {
      stopServer = await createHttpServer(port, requestHandler);
      setState(() {});
    }
  }

  void sendText(String text) async {
    final response = await http.put(Uri.parse(getUrl()),
        body: text, headers: {'content-type': 'text'});
    if (response.statusCode != HttpStatus.ok) {
      showSnackBar(context, 'Failed to Send Data');
    }
  }

  void sendTextToClipboard(String text) async {
    final response = await http.put(Uri.parse(getUrl()),
        body: text, headers: {'content-type': 'text/clip'});
    if (response.statusCode != HttpStatus.ok) {
      showSnackBar(context, 'Failed to Send Data');
    }
  }

  void sendFiles(
      Iterable<File> files, void Function(double) uploadProgress) async {
    if (files.isEmpty) {
      throw "no files selected";
    }
    final client = dio.Dio();
    if (files.length == 1) {
      final response = await client.put(
        getUrl(),
        data: files.first.openRead(),
        options: dio.Options(headers: {
          'content-length': (await files.first.length()).toString(),
          'content-type': 'file/${files.first.path.split('/')}',
        }),
        onSendProgress: (count, total) => uploadProgress(count / total),
      );
      if (response.statusCode == 200) {
        showSnackBar(context, "Sending File...");
      }
    } else {
      final futures = files.map((file) async {
        {
          final response = await client.put(
            getUrl(),
            data: file.openRead(),
            options: dio.Options(headers: {
              'content-length': await file.length(),
              'content-type':
                  'file/${file.path.substring(file.path.lastIndexOf('/') + 1)}',
            }),
            onSendProgress: (count, total) => uploadProgress(count / total),
          );
          if (response.statusCode == 200) {
            showSnackBar(context, "Sending Files...");
          }
        }
      });
      await Future.wait(futures);
    }
  }

  Future<Response> requestHandler(Request request) async {
    // print(request);
    final contentType = request.headers['content-type'];
    if (contentType != null) {
      if (contentType.startsWith('file/')) {
        final filename = contentType.substring(5);
        final stream = request.read();

        final filePath = "${widget.dir.path}$filename";

        try {
        final file = await File(filePath).create(recursive: true);
        widget.downloadsKey.currentState!.onRequest(
            file,
            int.parse(request.headers['content-length']!),
            stream,
            widget.downloadedKey.currentState!.onFile);
        print("created a file $filePath");
        //   await for (var chunk in stream) {
        //     sink.add(chunk);
        //   }
        //   await sink.flush();
        //   await sink.close();
        //   showSnackBar(context, "Recived a File, Saved at ${file.path}");
        //   print(await file.readAsString());
        } catch (e) {
          print("[stream] $e");
        }

        return Response.ok(null);
      } else if (contentType.startsWith('clip')) {
        request.readAsString().then((value) {
          showSnackBar(context, "Recieved a Clipboard value");
          Clipboard.setData(ClipboardData(text: value));
        });
        return Response.ok(null);
      }
    }
    return Response.badRequest();
  }
  
  @override
  bool get wantKeepAlive => true;
}
