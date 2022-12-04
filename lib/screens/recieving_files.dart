import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharem/widgets/progressing_file.dart';

class RecievingFiles extends StatefulWidget {
  const RecievingFiles({super.key});

  @override
  State<RecievingFiles> createState() => RecievingFilesState();
}

class RecievingFilesState extends State<RecievingFiles>
    with AutomaticKeepAliveClientMixin {
  var widgets = <DownloadingFile>[];

  void onRequest(File file, int size, Stream<List<int>> stream,
      void Function(File) onDone) {
        print("got a request");
    // final download = DownloadingFile(
    //     stream: stream,
    //     size: size,
    //     onDone: (_) {
    //       final index =
    //           widgets.indexWhere((element) => element.file.path == _.path);
    //           print("file downloaded $_");
    //       onDone(_);
    //       if (index != -1) {
    //         setState(() => widgets.removeAt(index));
    //       }
    //     },
    //     onError: (_) {
    //       print("file stream error");
    //       final index =
    //           widgets.indexWhere((element) => element.file.path == _.path);
    //       if (index != -1) {
    //         setState(() => widgets.removeAt(index));
    //       }
    //       file.delete();
    //     },
    //     file: file);

    // setState(() => widgets.add(download));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(children: widgets);
  }

  @override
  bool get wantKeepAlive => true;
}
