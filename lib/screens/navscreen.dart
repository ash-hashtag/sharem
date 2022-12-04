import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sharem/bin/server.dart';
import 'package:sharem/models/file_x.dart';
import 'package:sharem/screens/recieved_files.dart';
import 'package:sharem/utils/show_snackbar.dart';
import 'package:sharem/widgets/connection.dart';
import 'package:sharem/widgets/downloading_tasks.dart';
import 'package:sharem/widgets/local_ip_address.dart';
import 'package:sharem/widgets/send_files.dart';
import 'package:shelf/shelf.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;

class NavScreen extends StatefulWidget {
  final Directory directory;
  const NavScreen({super.key, required this.directory});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  VoidCallback? stopServer;
  final connectionDetailsKey = GlobalKey<ConnectionDetailsState>();

  final downloadingTasks = <DownloadProgress>[];

  @override
  void dispose() {
    stopServer?.call();
    super.dispose();
  }

  void onStopServer() {
    setState(() {
      stopServer?.call();
      stopServer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sharem"),
      ),
      body: Column(children: [
        const LocalIpAddress(),
        Center(
          child: TextButton(
            onPressed: stopServer == null ? onStart : onStopServer,
            child: Text(stopServer == null ? "Start" : "Stop"),
          ),
        ),
        ConnectionDetails(key: connectionDetailsKey),
        ElevatedButton(
            onPressed: syncClipBoard,
            child: const Text('Sync Last Copied Value From Clipboard')),
        SendFilesButton(sendFile: sendFile),
        Expanded(
          child: DownloadingTasks(tasks: downloadingTasks),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: showRecievedFiles,
        child: const Icon(Icons.folder),
      ),
    );
  }

  void showRecievedFiles() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RecievedFiles(
                  dir: widget.directory,
                )));
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

  void onStart() async {
    stopServer?.call();
    setState(() {
      stopServer = null;
    });
    createHttpServer(8080, requestHandler)
        .then((ss) => setState(() => stopServer = ss));
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

  void sendFile(File file) async {
    final client = dio.Dio();
    final progress = DownloadProgress(
        fileName: file.path.substring(file.path.lastIndexOf('/') + 1),
        bytesRecieved: 0,
        totalBytes: await file.length(),
        cancel: () => {});

    final response = await client.put(
      getUrl(),
      data: file.openRead(),
      options: dio.Options(headers: {
        'content-length': (progress.totalBytes).toString(),
        'content-type': 'file/${progress.fileName}',
      }),
      onSendProgress: (count, total) =>
          setState(() => progress.bytesRecieved = count),
    );
    if (response.statusCode == 200) {
      showSnackBar(context, "Sending File...");
    }
  }

  Future<Response> requestHandler(Request request) async {
    final contentType = request.headers['content-type'];
    if (contentType != null) {
      if (contentType.startsWith('file/')) {
        final filename = contentType.substring(5);
        showSnackBar(context, "Recieving a File $filename");
        await () async {
          final filePath = "${widget.directory.path}$filename";
          final file = await File(filePath).create(recursive: true);
          final sink = file.openWrite();
          final stream = request.read();
          final totalSize = int.parse(request.headers['content-length']!);
          final progress = DownloadProgress(
              fileName: filename,
              bytesRecieved: 0,
              totalBytes: totalSize,
              cancel: () async {
                await sink.close();
                file.delete();
                downloadingTasks
                    .removeWhere((element) => element.fileName == filename);
              });

          setState(() => downloadingTasks.add(progress));
          await for (var chunk in stream) {
            sink.add(chunk);
            print("recived chunk ${chunk.length}");
            setState(() => progress.bytesRecieved += chunk.length);
          }
          setState(() => downloadingTasks.remove(progress));
          await sink.flush();
          await sink.close();

          showSnackBar(context, "Recieved a File $filename");
        }().catchError((e) {
          print("[saving file] $e");
        });
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
}
