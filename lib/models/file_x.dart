
class DownloadProgress {
  final String fileName;
  final int bytesRecieved;
  final int totalBytes;

  const DownloadProgress(this.fileName, this.bytesRecieved, this.totalBytes);
}