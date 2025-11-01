/// 下载状态枚举
enum DownloadStatus {
  idle,        // 空闲
  downloading, // 下载中
  extracting,  // 解压中
  completed,   // 完成
  failed,      // 失败
  cancelled,   // 取消
}

/// 上传状态枚举
enum UploadStatus {
  idle,       // 空闲
  uploading,  // 上传中
  completed,  // 完成
  failed,     // 失败
}