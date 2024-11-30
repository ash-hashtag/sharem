import 'package:flutter/material.dart';
import 'package:sharem_cli/sharem_cli.dart';

class AcceptDialog extends StatelessWidget {
  final SharemFileShareRequest request;

  const AcceptDialog({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final entries = request.fileNameAndLength.entries.toList();

    final size = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(maxHeight: size.height / 2),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  "'${request.uniqueName}' wants to send you these files",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Unique code: '${request.uniqueCode}'",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(entries[i].key),
                  subtitle: Text(formatBytes(entries[i].value)),
                ),
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("No"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
