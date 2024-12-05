import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sharem/components/gatherer.dart';
import 'package:sharem/components/progresses_widget.dart';
import 'package:sharem/services/prefs.dart';
import 'package:sharem_cli/sharem_cli.dart';
import 'package:sharem_cli/unique_name.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final _tc = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _tc.dispose();
  }

  void onTap(SharemPeer peer) async {
    final text = _tc.text;
    if (text.isNotEmpty) {
      await peer.sendText(
          (await getOrSetUniqueName(generateUniqueName()))!, text);
      debugPrint("Sent text $text to ${peer.uniqueName}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Sent $text to ${peer.uniqueName}"),
        ));
      }
    }

    if (filePathsAndLengths.isNotEmpty) {
      final files = filePathsAndLengths.keys.map(SharemFile.fromPath).toList();
      peer.sendFiles(generateUniqueName(), files,
          progressCallback: (fileName, progress) {
        setState(() {
          _progresses[fileName] = progress;
        });
      });
    }
  }

  final Map<String, Progress> _progresses = {};
  final Map<String, int> filePathsAndLengths = {};

  Future<void> pickFiles() async {
    filePathsAndLengths.clear();
    _progresses.clear();
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      filePathsAndLengths.addEntries(await Future.wait(
          result.xFiles.map((e) async => MapEntry(e.path, await e.length()))));

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.3;
    final body = Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Text("Text: "),
            Expanded(
              child: TextField(
                controller: _tc,
              ),
            ),
          ],
        ),
      ),
      TextButton(onPressed: pickFiles, child: const Text("Pick Files")),
      SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _progresses.isNotEmpty
              ? Expanded(
                  child: ProgressesWidget(
                    progresses: Map.unmodifiable(_progresses),
                  ),
                )
              : filePathsAndLengths.isNotEmpty
                  ? Builder(builder: (context) {
                      final entries = filePathsAndLengths.entries.toList();
                      return ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(entries[index].key),
                          subtitle: Text(formatBytes(entries[index].value)),
                        ),
                      );
                    })
                  : const SizedBox(),
        ),
      ),
      SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GathererWidget(onTap: onTap),
        ),
      ),
    ]);
    // return Scaffold(
    //   appBar: AppBar(
    //     title: const Text("Sharem"),
    //   ),
    //   body: body,
    // );

    return body;
  }
}
