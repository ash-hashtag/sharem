import 'package:flutter/material.dart';
import 'package:sharem_cli/sharem_cli.dart';

class ProgressesWidget extends StatelessWidget {
  final Map<String, Progress> progresses;

  const ProgressesWidget({super.key, this.progresses = const {}});

  @override
  Widget build(BuildContext context) {
    final entries = progresses.entries.toList();

    return ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final progress = entries[i].value;
          final value = progress.bytesTransferred / progress.totalBytes;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Text("${entries[i].key} ${progress.toPrettyString()}"),
              LinearProgressIndicator(
                value: value,
              )
            ]),
          );
        });
  }
}
