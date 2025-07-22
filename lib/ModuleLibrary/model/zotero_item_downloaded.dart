class ItemsDownloadProgress {
  final int libraryVersion;
  final int nDownloaded;
  final int total;

  ItemsDownloadProgress(this.libraryVersion, this.nDownloaded, this.total);
}

// 集合下载进度
class CollectionsDownloadProgress {
  final int libraryVersion;
  final int nDownloaded;
  final int total;

  CollectionsDownloadProgress(this.libraryVersion, this.nDownloaded, this.total);
}
