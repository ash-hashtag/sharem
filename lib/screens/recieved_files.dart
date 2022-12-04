import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharem/widgets/file_widget.dart';

class RecievedFiles extends StatefulWidget {
  final Directory dir;
  const RecievedFiles({super.key, required this.dir});

  @override
  State<RecievedFiles> createState() => RecievedFilesState();
}

class RecievedFilesState extends State<RecievedFiles> with AutomaticKeepAliveClientMixin{
  var files = <File>[];

  @override
  void initState() {
    print("init state recievied files 0");
    super.initState();
  }

  Future<void> refresh() async {
    widget.dir
        .list()
        .map((e) => File(e.path))
        .toList()
        .then((value) => setState(() => files = value));
  }

  void onFile(File file) {
    setState(() => files.add(file));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Center(
            child:
                TextButton(onPressed: refresh, child: const Text("Refresh"))),
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) => FileWidget(
              file: files[index],
              onDeletion: (file) => setState(
                () => files.remove(file),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}
