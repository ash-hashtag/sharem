
import 'dart:io';

import 'package:mime/mime.dart';

extension MimeType on File {
  Future<String> get mimeType async {
    final mime = lookupMimeType(path);
    if (mime != null) {
      return mime;
    } else {
      final stream = openRead(0, 100);
      final headerBytes = <int>[];
      await for (var chunk in stream) {
        final endOfMagicBytes = chunk.indexOf(0);
        if (endOfMagicBytes != -1) {
          headerBytes.addAll(chunk.getRange(0, endOfMagicBytes));
          return lookupMimeType(path, headerBytes: headerBytes) ?? "application/octet-stream";
        } else {
          headerBytes.addAll(chunk);
        }
      }
    }
    return "application/octet-stream";
  }
}