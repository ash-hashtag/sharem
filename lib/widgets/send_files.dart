
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharem/bin/directories.dart';
import 'package:url_launcher/url_launcher.dart';

class SendFilesButton extends StatefulWidget {

  final void Function(Iterable<File>, void Function(double)) sendFiles;
  const SendFilesButton({super.key, required this.sendFiles});

  @override
  State<SendFilesButton> createState() => _SendFilesButtonState();
}

class _SendFilesButtonState extends State<SendFilesButton> {

  var progressText = '0%';
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(onPressed: pickAndSendFiles, child: const Text('Send Files')),
        Text(progressText)
      ]
    );
  }

    void pickAndSendFiles() async {
      getDownloadedDirectory().then((value) => launchUrl(value.uri));
    // final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    // if (result != null) {
    //   final files = result.paths.map((e) => File(e!));
    //   // widget.sendFiles(files, (progress) => setState(() => progressText = "$progress%"));
    // }
  }
}