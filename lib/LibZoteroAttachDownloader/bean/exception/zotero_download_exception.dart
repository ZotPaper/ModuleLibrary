
/// 自定义下载异常类
class DownloadException implements Exception {
  final String message;
  final String? originalError;
  final DownloadErrorType errorType;

  const DownloadException({
    required this.message,
    this.originalError,
    required this.errorType,
  });

  @override
  String toString() => message;
}

/// 下载错误类型枚举
enum DownloadErrorType {
  network,          // 网络错误
  timeout,          // 超时
  notFound,         // 文件未找到
  unauthorized,     // 未授权
  forbidden,        // 无权限
  storage,          // 存储错误
  permission,       // 权限错误
  alreadyDownloading, // 正在下载中
  notInitialized,   // 未初始化
  unknown,          // 未知错误
}


class ZipException implements Exception {
  final String message;
  ZipException(this.message);
}