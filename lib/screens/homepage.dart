// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:sharem/bin/multipart.dart';
import 'package:sharem/bin/server.dart';
import 'package:sharem/utils/show_snackbar.dart';
import 'package:sharem/widgets/connection.dart';
import 'package:sharem/widgets/local_ip_address.dart';
import 'package:shelf/shelf.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VoidCallback? stopServer;
  final connectionDetailsKey = GlobalKey<ConnectionDetailsState>();
  late final String externalMediaDirectoryPath;

  @override
  void initState() {
    if (Platform.isAndroid) {
      getExternalStorageDirectory()
          .then((value) => externalMediaDirectoryPath = value!.path)
          .catchError((e) => externalMediaDirectoryPath = "");
    } else {
      getDownloadsDirectory()
          .then((value) => externalMediaDirectoryPath = value!.path)
          .catchError((e) => externalMediaDirectoryPath = "");
    }
    super.initState();
  }

  @override
  void dispose() {
    stopServer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Sharem")),
        body: Column(mainAxisSize: MainAxisSize.min,
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Text(stopServer != null ? 'Online' : 'Offline')),
              LocalIpAddress(onReset: onReset),
              ConnectionDetails(key: connectionDetailsKey),
              ElevatedButton(
                  onPressed: syncClipBoard,
                  child: const Text('Sync Last Copied Value From Clipboard')),
            ]));
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
      final multiFile = await getMultiFileFromFiles(files);
      final response = await client.put(
        getUrl(),
        data: multiFile.stream,
        options: dio.Options(headers: {
          'content-length': multiFile.size.toString(),
          'content-type': 'multifile',
          'meta': multiFile.metas.toString(),
        }),
        onSendProgress: (count, total) => uploadProgress(count / total),
      );
      if (response.statusCode == 200) {
        showSnackBar(context, "Sending Files...");
      }
    }
  }

  Future<Response> requestHandler(Request request) async {
    // print(request);
    final contentType = request.headers['content-type'];
    if (contentType != null) {
      if (contentType.startsWith('file/')) {
        final filename = contentType.substring(5);
        final stream = request.read();
        if (Platform.isAndroid) {
          getExternalStorageDirectory().then((value) async {
            if (value != null) {
              final file = await File('$externalMediaDirectoryPath/$filename')
                  .create(recursive: true);
              final sink = file.openWrite();
              await sink.addStream(stream);
              await sink.flush();
              await sink.close();
              showSnackBar(context, "Recived a File, Saved at ${file.path}");
            } else {
              print("no external directory found");
            }
          }).catchError((e) {
            print("[ext-dir] $e");
          });
        } else {
          getDownloadsDirectory().then((downloadsDir) async {
            if (downloadsDir != null) {
              final file = await File('${downloadsDir.path}/$filename')
                  .create(recursive: true);
              final sink = file.openWrite();
              await sink.addStream(request.read());
              await sink.flush();
              await sink.close();

              showSnackBar(context, "Recived a File, Saved at ${file.path}");
            }
          });
        }

        return Response.ok(null);
      } else if (contentType.startsWith('multifile|')) {
        final metas = List<String>.from(jsonDecode(contentType.substring(9)))
            .map(MultiFilePartMeta.fromString)
            .toList();
        getFilesFromMultiFileStream(request.read(), metas)
            .toList()
            .then((value) {
          final url = value.first.parent.uri;
          launchUrl(url);
        });
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
