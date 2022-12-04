// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharem/widgets/connection.dart';
import 'package:sharem/widgets/local_ip_address.dart';
import 'package:sharem/widgets/send_files.dart';

class HomePage extends StatelessWidget {
  final Directory dir;
  final void Function([int?]) onReset;
  final VoidCallback syncClipBoard;
  final GlobalKey connectionDetailsKey;
  final void Function(Iterable<File>, void Function(double)) sendFiles;
  const HomePage({
    Key? key,
    required this.dir,
    required this.onReset,
    required this.syncClipBoard,
    required this.connectionDetailsKey,
    required this.sendFiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      LocalIpAddress(onReset: onReset),
      ConnectionDetails(key: connectionDetailsKey),
      ElevatedButton(
          onPressed: syncClipBoard,
          child: const Text('Sync Last Copied Value From Clipboard')),
      SendFilesButton(sendFiles: sendFiles),
    ]);
  }
}
