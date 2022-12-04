import 'package:flutter/material.dart';
import 'package:sharem/models/file_x.dart';
import 'package:sharem/widgets/progressing_file.dart';

class DownloadingTasks extends StatelessWidget {
  final List<DownloadProgress> tasks;
  const DownloadingTasks({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) => DownloadStatus(progres: tasks[index]),),
    );
  }
}