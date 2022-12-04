import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/material.dart';

class DownloadFailed extends StatelessWidget {
  final String name;
  const DownloadFailed({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: const Text(
        'failed :(',
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}
