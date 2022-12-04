import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class FileWidget extends StatelessWidget {
  final File file;
  final void Function(File) onDeletion;

  static const channel = MethodChannel("channel");
  const FileWidget({super.key, required this.file, required this.onDeletion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(
                file.path.substring(file.path.lastIndexOf('/') + 1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              )),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text("Delete"),
                    onTap: () {
                      onDeletion(file);
                      file.delete(recursive: true);
                    },
                  ),
                  PopupMenuItem(
                    child: const Text("Share"),
                    onTap: () => Share.shareXFiles([XFile(file.path)]),
                  ),
                ],
              ),
            ],
          ),
          FutureBuilder(
              future: file.length(),
              builder: (_, s) => Text(s.hasData && s.data != null ? "${s.data} Bytes": "loading...", style: const TextStyle(fontSize: 10),))
        ],
      ),
    );
  }

  void openExplorer() async {
    Share.shareXFiles([XFile(file.path)]);
  }
}
