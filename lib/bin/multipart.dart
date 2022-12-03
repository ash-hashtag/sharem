import 'dart:io';
import 'dart:typed_data';

class MultiFilePartMeta {
  final String name;
  final int size;

  MultiFilePartMeta(this.size, this.name);

  @override
  String toString() {
    return "$size:$name";
  }

  factory MultiFilePartMeta.fromString(String str) {
    final splits = str.split(":");
    return MultiFilePartMeta(int.parse(splits[0]), splits[1]);
  }
}

class MultiFilePart {
  final MultiFilePartMeta meta;
  final Uint8List data;

  const MultiFilePart(this.data, this.meta);
}

Stream<File> getFilesFromMultiFileStream(
    Stream<List<int>> stream, List<MultiFilePartMeta> metas, {
      int? size,
      void Function(double)? downloadProgress,
    }) async* {

  var recievedBytes = 0;
  var currentFile = 0;
  var cursor = 0;

  MultiFilePartMeta meta() => metas[currentFile];
  // var currentBuffer = Uint8List(meta().size);
  var file = await File(meta().name).create(recursive: true);
  var sink = file.openWrite();

  void setBuffer(Iterable<int> data) {
    sink.add(data.toList());
    // currentBuffer.setAll(cursor, data);
    cursor += data.length;
  }

  finishBuffer() async {
    // onFile(currentBuffer, meta().type, meta().extra);
    await sink.flush();
    await sink.close();
    final oldFile = file;
    // final part = MultiFilePart(currentBuffer, meta());

    cursor = 0;
    currentFile++;

    if (currentFile != metas.length) {
      file = await File(meta().name).create(recursive: true);
      sink = file.openWrite();
      // currentBuffer = Uint8List(meta().size);
    }

    return oldFile;
  }

  await for (var chunk in stream) {
    recievedBytes += chunk.length;
    downloadProgress!(recievedBytes / size!);
    var c = 0;
    while (currentFile < metas.length) {
      final end = meta().size - cursor + c;
      if (end < chunk.length) {
        // final buf = Uint8List.sublistView(chunk, c, end);
        final buf = chunk.getRange(c, end);
        // chunk.sublist(c, end);
        c += buf.length;
        setBuffer(buf);

        //send file;
        yield await finishBuffer();
      } else {
        // setBuffer(Uint8List.sublistView(chunk, c));
        setBuffer(chunk.getRange(c, chunk.length));
        break;
      }
    }
  }
  yield await finishBuffer();
}

class MultiFile {
  final Stream<List<int>> stream;
  final List<MultiFilePartMeta> metas;
  final int size;

  const MultiFile(this.stream, this.metas, this.size);
}

Future<MultiFile> getMultiFileFromFiles(Iterable<File> files) async {
  final fTotalLength = Future.wait(files.map((e) => e.length()))
      .then((value) => value.reduce((a, b) => a + b));

  final metaHeader = await Future.wait(files.map((e) async =>
      MultiFilePartMeta(await e.length(), e.path.split('/').last)));

  return MultiFile(mergeStreams(files.map((e) => e.openRead())), metaHeader,
      await fTotalLength);
}

Stream<T> mergeStreams<T>(Iterable<Stream<T>> streamsToMerge) async* {
  for (final stream in streamsToMerge) {
    await for (final chunk in stream) {
      yield chunk;
    }
  }
}
