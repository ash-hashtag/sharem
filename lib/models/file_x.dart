
class DownloadProgress {
  final String fileName;
  int bytesRecieved;
  final int totalBytes;
  final void Function() cancel;

  DownloadProgress(
      {required this.fileName,
      required this.bytesRecieved,
      required this.totalBytes,
      required this.cancel});
}
