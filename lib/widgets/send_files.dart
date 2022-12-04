import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sharem/bin/directories.dart';
import 'package:url_launcher/url_launcher.dart';

class SendFilesButton extends StatefulWidget {
  final void Function(File) sendFile;
  const SendFilesButton({super.key, required this.sendFile});

  @override
  State<SendFilesButton> createState() => _SendFilesButtonState();
}

class _SendFilesButtonState extends State<SendFilesButton> {
  var progressText = '0%';

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: pickAndSendFiles, child: const Text('Send Files'));
  }

  void pickAndSendFiles() async {
    getDownloadedDirectory().then((value) => launchUrl(value.uri));
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      result.paths.map((e) => widget.sendFile(File(e!)));
    }
  }
}
