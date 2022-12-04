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
    return ListTile(
      title: Text(
        file.path.substring(file.path.lastIndexOf('/') + 1),
      ),
      onTap: openExplorer,
      subtitle: Text(file.path.substring(file.path.indexOf('Documents'))),
      trailing: PopupMenuButton(itemBuilder: (context) => [
        PopupMenuItem(child: const Text("Delete"), onTap: () {
          onDeletion(file);
          file.delete(recursive: true);
        },),
        PopupMenuItem(child: const Text("Share"), onTap: () => Share.shareXFiles([XFile(file.path)]),),
      ],),
    );
  }

  void openExplorer() async {
    Share.shareXFiles([XFile(file.path)]);
  }
}
