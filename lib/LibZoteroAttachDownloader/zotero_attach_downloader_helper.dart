import 'dart:async';
import 'package:module_library/LibZoteroAttachDownloader/default_attachment_storage.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';

import '../LibZoteroStorage/entity/Item.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attachment_transfer.dart';

/// 下载状态枚举
enum DownloadStatus {
  idle,        // 空闲
  downloading, // 下载中
  extracting,  // 解压中
  completed,   // 完成
  failed,      // 失败
  cancelled,   // 取消
}

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

/// 进度回调函数类型定义
typedef ProgressCallback = void Function(AttachmentDownloadInfo downloadInfo);
typedef CompletionCallback = void Function(AttachmentDownloadInfo downloadInfo, bool success);
typedef ErrorCallback = void Function(AttachmentDownloadInfo downloadInfo, Exception errorMsg);

class ZoteroAttachDownloaderHelper {

  // 单例模式
  static final ZoteroAttachDownloaderHelper instance = ZoteroAttachDownloaderHelper._internal();
  factory ZoteroAttachDownloaderHelper() => instance;
  ZoteroAttachDownloaderHelper._internal();

  // 实现这个附件存储类
  DefaultAttachmentStorage defaultStorageManager = DefaultAttachmentStorage.instance;

  late ZoteroAttachmentTransfer transfer;

  var _userId = "";
  var _apiKey = "";
  bool _isInitialized = false;

  // 下载状态管理
  final Map<String, AttachmentDownloadInfo> _downloadStates = {};
  final Map<String, StreamSubscription> _downloadSubscriptions = {};

  // 回调函数
  ProgressCallback? _onProgressUpdate;
  CompletionCallback? _onDownloadComplete;
  ErrorCallback? _onDownloadError;

  /// 初始化下载器
  void initialize(String userId, String apiKey) {
    _userId = userId;
    _apiKey = apiKey;
    _isInitialized = true;

    // 创建下载器
    transfer = ZoteroAttachmentTransfer(
        userID: _userId,
        API_KEY: _apiKey,
        attachmentStorageManager: defaultStorageManager
    );

    MyLogger.d('ZoteroAttachDownloaderHelper initialized for user: $userId');
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 设置进度回调
  void setProgressCallback(ProgressCallback? callback) {
    _onProgressUpdate = callback;
  }

  /// 设置完成回调
  void setCompletionCallback(CompletionCallback? callback) {
    _onDownloadComplete = callback;
  }

  /// 设置错误回调
  void setErrorCallback(ErrorCallback? callback) {
    _onDownloadError = callback;
  }

  /// 获取当前下载状态
  AttachmentDownloadInfo? getDownloadStatus(String itemKey) {
    return _downloadStates[itemKey];
  }

  /// 获取所有下载状态
  Map<String, AttachmentDownloadInfo> getAllDownloadStates() {
    return Map.unmodifiable(_downloadStates);
  }

  /// 检查附件是否正在下载
  bool isDownloading(String itemKey) {
    final state = _downloadStates[itemKey];
    return state?.status == DownloadStatus.downloading || 
           state?.status == DownloadStatus.extracting;
  }

  /// 检查附件是否已存在
  Future<bool> isAttachmentExists(Item item) async {
    try {
      return await defaultStorageManager.attachmentExists(item);
    } catch (e) {
      return false;
    }
  }

  /// 将原始错误转换为友好的错误消息和错误类型
  DownloadException _createFriendlyException(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (error is ZoteroNotFoundException) {
      return DownloadException(
        message: '服务器找不到文件',
        originalError: error.message,
        errorType: DownloadErrorType.notFound,
      );
    }
    
    // if (errorStr.contains('network') || errorStr.contains('connection')) {
    //   return const DownloadException(
    //     message: '网络连接失败，请检查网络设置',
    //     errorType: DownloadErrorType.network,
    //   );
    // } else if (errorStr.contains('timeout')) {
    //   return const DownloadException(
    //     message: '下载超时，请重试',
    //     errorType: DownloadErrorType.timeout,
    //   );
    // } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
    //   return const DownloadException(
    //     message: 'API密钥无效，请重新登录',
    //     errorType: DownloadErrorType.unauthorized,
    //   );
    // } else if (errorStr.contains('forbidden') || errorStr.contains('403')) {
    //   return const DownloadException(
    //     message: '无权限访问此附件',
    //     errorType: DownloadErrorType.forbidden,
    //   );
    // }
    return DownloadException(
      message: '下载失败: ${error.toString()}',
      originalError: error.toString(),
      errorType: DownloadErrorType.unknown,
    );
  }

  /// 开始下载附件
  Future<void> startDownloadAttachment(Item item, {
    ProgressCallback? onProgress,
    CompletionCallback? onComplete,
    ErrorCallback? onError,
  }) async {
    if (!_isInitialized) {
      throw const DownloadException(
        message: '下载器未初始化，请先调用initialize方法',
        errorType: DownloadErrorType.notInitialized,
      );
    }

    final itemKey = item.itemKey;
    
    // 检查是否已在下载
    if (isDownloading(itemKey)) {
      MyLogger.d('附件 $itemKey 正在下载中，跳过');
      throw const DownloadException(
        message: '该附件正在下载中',
        errorType: DownloadErrorType.alreadyDownloading,
      );
    }

    // 检查附件是否已存在
    if (await isAttachmentExists(item)) {
      MyLogger.d('附件 $itemKey 已存在，跳过下载');
      final downloadInfo = AttachmentDownloadInfo(
        itemKey: itemKey,
        filename: await defaultStorageManager.getFilenameForItem(item),
        progress: 100,
        total: 100,
        status: DownloadStatus.completed,
      );
      _downloadStates[itemKey] = downloadInfo;
      onComplete?.call(downloadInfo, true);
      _onDownloadComplete?.call(downloadInfo, true);
      return;
    }

    try {
      final filename = await defaultStorageManager.getFilenameForItem(item);

      MyLogger.d('开始下载附件 $itemKey 附件文件名: $filename');
      
      // 初始化下载状态
      var downloadInfo = AttachmentDownloadInfo(
        itemKey: itemKey,
        filename: filename,
        progress: 0,
        total: 0,
        status: DownloadStatus.downloading,
      );
      _downloadStates[itemKey] = downloadInfo;

      // 通知开始下载
      onProgress?.call(downloadInfo);
      _onProgressUpdate?.call(downloadInfo);

      // 开始下载并监听进度
      final downloadStream = transfer.downloadItemRx(item);
      
      final subscription = downloadStream.listen(
        (progress) {
          // 更新下载进度
          downloadInfo = downloadInfo.copyWith(
            progress: progress.progress,
            total: progress.total,
            status: DownloadStatus.downloading,
          );
          _downloadStates[itemKey] = downloadInfo;

          // 通知进度更新
          onProgress?.call(downloadInfo);
          _onProgressUpdate?.call(downloadInfo);
        },
        onDone: () async {
          // 下载完成，开始处理文件
          await _handleDownloadComplete(item, downloadInfo, onProgress, onComplete);
        },
        onError: (error) {
          // 下载失败
          _handleDownloadError(item, error, downloadInfo, onProgress, onComplete, onError);
        },
      );

      _downloadSubscriptions[itemKey] = subscription;

    } catch (e) {
      _handleDownloadError(item, e, null, onProgress, onComplete, onError, shouldThrow: true);
    }
  }

  /// 处理下载完成
  Future<void> _handleDownloadComplete(
    Item item, 
    AttachmentDownloadInfo downloadInfo,
    ProgressCallback? onProgress,
    CompletionCallback? onComplete,
  ) async {
    final itemKey = item.itemKey;
    
    try {
      MyLogger.d('附件下载完成，开始处理文件: $itemKey');
      
      // 获取临时文件路径
      final tempFile = await defaultStorageManager.getDownloadTempFile(item);
      
      if (await tempFile.exists()) {
        MyLogger.d('临时文件存在，开始重命名: ${tempFile.path}');
        
        // 将临时文件重命名为最终文件
        await defaultStorageManager.completeDownload(item, tempFile);
        
        MyLogger.d('文件重命名完成: $itemKey');
      } else {
        MyLogger.w('临时文件不存在: ${tempFile.path}');
      }

      // 下载和处理完成
      downloadInfo = downloadInfo.copyWith(
        status: DownloadStatus.completed,
        progress: downloadInfo.total,
      );
      _downloadStates[itemKey] = downloadInfo;

      // 清理订阅
      _downloadSubscriptions.remove(itemKey)?.cancel();

      // 通知完成
      onComplete?.call(downloadInfo, true);
      _onDownloadComplete?.call(downloadInfo, true);

      MyLogger.d('附件下载完成: $itemKey');

    } catch (e) {
      MyLogger.e('处理下载完成时出错: $e');
      _handleDownloadError(item, e, downloadInfo, onProgress, onComplete, null, shouldThrow: false);
    }
  }

  /// 处理下载错误
  void _handleDownloadError(
    Item item,
    dynamic error,
    AttachmentDownloadInfo? currentInfo,
    ProgressCallback? onProgress,
    CompletionCallback? onComplete,
    ErrorCallback? onError, {
    bool shouldThrow = false,  // 是否应该抛出异常
  }) {
    final itemKey = item.itemKey;
    final friendlyException = _createFriendlyException(error);
    
    final downloadInfo = (currentInfo ?? AttachmentDownloadInfo(
      itemKey: itemKey,
      filename: 'unknown',
      progress: 0,
      total: 0,
      status: DownloadStatus.failed,
    )).copyWith(
      status: DownloadStatus.failed,
      errorMessage: friendlyException.message,
    );
    
    _downloadStates[itemKey] = downloadInfo;

    // 清理订阅
    _downloadSubscriptions.remove(itemKey)?.cancel();

    // 通知错误
    onProgress?.call(downloadInfo);
    _onProgressUpdate?.call(downloadInfo);
    onComplete?.call(downloadInfo, false);
    _onDownloadComplete?.call(downloadInfo, false);

    MyLogger.d('附件下载失败 $itemKey: $error');

    onError?.call(downloadInfo, friendlyException);
    _onDownloadError?.call(downloadInfo, friendlyException);

    // 只有在同步调用中才抛出异常
    if (shouldThrow) {
      throw friendlyException;
    }
  }

  /// 取消下载
  Future<void> cancelDownload(String itemKey) async {
    final subscription = _downloadSubscriptions.remove(itemKey);
    await subscription?.cancel();

    final currentInfo = _downloadStates[itemKey];
    if (currentInfo != null) {
      final cancelledInfo = currentInfo.copyWith(
        status: DownloadStatus.cancelled,
      );
      _downloadStates[itemKey] = cancelledInfo;
      
      _onProgressUpdate?.call(cancelledInfo);
      _onDownloadComplete?.call(cancelledInfo, false);
    }

    MyLogger.d('取消下载: $itemKey');
  }

  /// 取消所有下载
  Future<void> cancelAllDownloads() async {
    final keys = List.from(_downloadSubscriptions.keys);
    for (final key in keys) {
      await cancelDownload(key);
    }
  }

  /// 清理下载状态
  void clearDownloadStates() {
    _downloadStates.clear();
  }

  /// 清理完成的下载状态
  void clearCompletedDownloads() {
    _downloadStates.removeWhere((key, value) => 
      value.status == DownloadStatus.completed ||
      value.status == DownloadStatus.failed ||
      value.status == DownloadStatus.cancelled
    );
  }

  /// 获取活跃的下载数量
  int getActiveDownloadCount() {
    return _downloadStates.values.where((info) => 
      info.status == DownloadStatus.downloading ||
      info.status == DownloadStatus.extracting
    ).length;
  }

  /// 重试失败的下载
  Future<void> retryFailedDownload(String itemKey, Item item, {
    ProgressCallback? onProgress,
    CompletionCallback? onComplete,
  }) async {
    final currentInfo = _downloadStates[itemKey];
    if (currentInfo?.status == DownloadStatus.failed) {
      // 清除失败状态并重新开始下载
      _downloadStates.remove(itemKey);
      await startDownloadAttachment(item, onProgress: onProgress, onComplete: onComplete);
    } else {
      throw const DownloadException(
        message: '只能重试失败的下载任务',
        errorType: DownloadErrorType.unknown,
      );
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await cancelAllDownloads();
    _downloadStates.clear();
    _onProgressUpdate = null;
    _onDownloadComplete = null;
  }
}

