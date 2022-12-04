import 'package:flutter/material.dart';
import 'package:sharem/extensions/int.dart';
import 'package:sharem/models/file_x.dart';

class DownloadStatus extends StatelessWidget {
  final DownloadProgress progres;
  const DownloadStatus({super.key, required this.progres});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(child: Text(progres.fileName)),
              Text('${progres.bytesRecieved.toFormattedString()}/${progres.totalBytes.toFormattedString()}')
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Expanded(
            child: LinearProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
              color: Colors.red,
              minHeight: 15,
              value: progres.bytesRecieved / progres.totalBytes,
            ),
          ),
        ),
      ],
    );
  }
}
