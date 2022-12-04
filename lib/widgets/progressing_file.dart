import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharem/utils/show_snackbar.dart';

class DownloadingFile extends StatefulWidget {
  final Stream<List<int>> stream;
  final int size;
  final File file;
  final void Function(File) onDone;
  final void Function(File) onError;
  const DownloadingFile({
    super.key,
    required this.stream,
    required this.size,
    required this.onDone,
    required this.onError,
    required this.file,
  });

  @override
  State<DownloadingFile> createState() => _DownloadingFileState();
}

class _DownloadingFileState extends State<DownloadingFile> {
  var bytesDownloaded = 0;
  late final StreamSubscription sub;
  late final IOSink sink;
  late final fileName = widget.file.path.substring(widget.file.path.lastIndexOf('/') + 1);

  @override
  void initState() {
    sink = widget.file.openWrite();
    sub = widget.stream.listen(listen);
    sub.onDone(() async {
      await sink.flush();
      await sink.close();
      widget.onDone(widget.file);
    });
    sub.onError((_) => {widget.onError(widget.file), showSnackBar(context, _.toString())});
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void listen(List<int> chunk) {
    setState(() {
      bytesDownloaded += chunk.length;
    });
    print("chunk ${chunk.length}");
    sink.add(chunk);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(fileName),
      subtitle: LinearProgressIndicator(
        backgroundColor: Colors.lightBlueAccent,
        color: Colors.red,
        minHeight: 5,
        value: bytesDownloaded / widget.size,
      ),
    );
  }
}
