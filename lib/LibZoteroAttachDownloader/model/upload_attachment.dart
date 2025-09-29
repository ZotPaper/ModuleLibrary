/// 上传结果封装类
class UploadResult {
  final int successCount;
  final int totalCount;
  final List<String> failedItems;
  final String? error;

  UploadResult({
    required this.successCount,
    required this.totalCount,
    required this.failedItems,
    this.error,
  });

  bool get isAllSuccessful => successCount == totalCount;
  bool get hasFailures => failedItems.isNotEmpty;
  bool get hasError => error != null;
}
