import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharem/widgets/file_widget.dart';

class RecievedFiles extends StatefulWidget {
  final Directory dir;
  const RecievedFiles({super.key, required this.dir});

  @override
  State<RecievedFiles> createState() => RecievedFilesState();
}

class RecievedFilesState extends State<RecievedFiles> {
  @override
  void initState() {
    print("init state recievied files 0");
    widget.dir
        .list()
        .map((e) => File(e.path))
        .toList()
        .then((value) => setState(() => files.addAll(value)));
    super.initState();
  }

  final files = <File>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Documents/sharem"),),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) => FileWidget(
          file: files[index],
          onDeletion: (file) => setState(
            () => files.remove(file),
          ),
        ),
      ),
    );
  }
}
