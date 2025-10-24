
import 'package:module_library/LibZoteroAttachDownloader/model/status.dart';

/// 附件下载信息
class AttachmentDownloadInfo {
  final String itemKey;
  final String filename;
  final int progress;
  final int total;
  final DownloadStatus status;
  final String? errorMessage;
  final double progressPercent;

  AttachmentDownloadInfo({
    required this.itemKey,
    required this.filename,
    required this.progress,
    required this.total,
    required this.status,
    this.errorMessage,
  }) : progressPercent = total > 0 ? (progress / total * 100) : 0.0;

  AttachmentDownloadInfo copyWith({
    String? itemKey,
    String? filename,
    int? progress,
    int? total,
    DownloadStatus? status,
    String? errorMessage,
  }) {
    return AttachmentDownloadInfo(
      itemKey: itemKey ?? this.itemKey,
      filename: filename ?? this.filename,
      progress: progress ?? this.progress,
      total: total ?? this.total,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'AttachmentDownloadInfo{itemKey: $itemKey, filename: $filename, progress: $progress/$total (${progressPercent.toStringAsFixed(1)}%), status: $status}';
  }
}

/// 附件上传信息
class AttachmentUploadInfo {
  final String itemKey;
  final String filename;
  final int currentIndex;
  final int totalCount;
  final UploadStatus status;
  final String? errorMessage;

  AttachmentUploadInfo({
    required this.itemKey,
    required this.filename,
    required this.currentIndex,
    required this.totalCount,
    required this.status,
    this.errorMessage,
  });

  AttachmentUploadInfo copyWith({
    String? itemKey,
    String? filename,
    int? currentIndex,
    int? totalCount,
    UploadStatus? status,
    String? errorMessage,
  }) {
    return AttachmentUploadInfo(
      itemKey: itemKey ?? this.itemKey,
      filename: filename ?? this.filename,
      currentIndex: currentIndex ?? this.currentIndex,
      totalCount: totalCount ?? this.totalCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'AttachmentUploadInfo{itemKey: $itemKey, filename: $filename, progress: $currentIndex/$totalCount, status: $status}';
  }
}