import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' as pp;

Future<Directory> getDownloadedDirectory() => Platform.isAndroid
    ? pp.getExternalStorageDirectories(type: pp.StorageDirectory.documents).then((value) => value!.first)
    : pp.getDownloadsDirectory().then((value) => value!);
Future<String?> getMediaDirectory() async {
  return const MethodChannel("channel").invokeMethod("getExternalDir");
}