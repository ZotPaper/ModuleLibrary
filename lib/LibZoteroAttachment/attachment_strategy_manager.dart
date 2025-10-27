import 'dart:io';

import 'package:flutter/material.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:open_filex/open_filex.dart';

import '../LibZoteroAttachDownloader/bean/exception/zotero_download_exception.dart';
import '../LibZoteroAttachDownloader/default_attachment_storage.dart';
import '../LibZoteroAttachDownloader/model/status.dart';
import '../LibZoteroAttachDownloader/model/transfer_info.dart';
import '../LibZoteroAttachDownloader/native/attachment_native_channel.dart';
import '../LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import '../LibZoteroStorage/entity/Item.dart';
import '../ModuleLibrary/viewmodels/zotero_database.dart';
import '../ModuleLibrary/zotero_provider.dart';
import 'package:bruno/bruno.dart';

/// 下载状态更新回调类型
typedef DownloadStateCallback = void Function(AttachmentDownloadInfo);
/// 下载状态移除回调类型
typedef DownloadStateRemoveCallback = void Function(String itemKey);
/// 文件存在状态缓存更新回调类型
typedef FileExistsCacheCallback = void Function(String itemKey, bool exists);

class AttachmentStrategyManager {
  // 单例模式
  static final AttachmentStrategyManager instance = AttachmentStrategyManager._internal();
  AttachmentStrategyManager._internal();

  final ZoteroDB zoteroDB = ZoteroProvider.getZoteroDB();

  // 下载状态跟踪
  final Map<String, AttachmentDownloadInfo> _downloadStates = {};
  
  // 状态更新回调
  DownloadStateCallback? _onDownloadStateUpdate;
  DownloadStateRemoveCallback? _onDownloadStateRemove;
  FileExistsCacheCallback? _onFileExistsCacheUpdate;
  
  /// 设置下载状态更新回调
  void setDownloadStateUpdateCallback(DownloadStateCallback? callback) {
    _onDownloadStateUpdate = callback;
  }
  
  /// 设置下载状态移除回调
  void setDownloadStateRemoveCallback(DownloadStateRemoveCallback? callback) {
    _onDownloadStateRemove = callback;
  }
  
  /// 设置文件存在缓存更新回调
  void setFileExistsCacheUpdateCallback(FileExistsCacheCallback? callback) {
    _onFileExistsCacheUpdate = callback;
  }

  /// 获取附件下载状态
  AttachmentDownloadInfo? getDownloadStatus(String itemKey) {
    return _downloadStates[itemKey];
  }

  /// 打开已下载的pdf
  Future<void> openDownloadedPdf(BuildContext context, Item targetPdfAttachmentItem) async {
    bool isDownloaded = await DefaultAttachmentStorage.instance.attachmentExists(targetPdfAttachmentItem);

    if (!isDownloaded) {
      BrnToast.show('请先下载${targetPdfAttachmentItem.getTitle()}', context);
      MyLogger.d('请先下载${targetPdfAttachmentItem.getTitle()}');
      return;
    }

    // BrnToast.show('${targetPdfAttachmentItem.getTitle()}已下载, 打开pdf功能待开发...', context);
    MyLogger.d('${targetPdfAttachmentItem.getTitle()}已下载');

    final attachmentFile = await DefaultAttachmentStorage.instance.getAttachmentFile(targetPdfAttachmentItem);

    //  判断是否使用其他阅读器打开pdf
    var useExternalPdfReader = DefaultAttachmentStorage.instance.isOpenPdfExternalReader;
    if (useExternalPdfReader) {
      // 使用其他阅读器打开pdf
      openPdfWithUrlLauncher(context, attachmentFile, targetPdfAttachmentItem);
    } else {
      final res = await PdfViewerNativeChannel.openPdfViewer(
        attachmentKey: targetPdfAttachmentItem.itemKey,
        attachmentPath: attachmentFile.path,
        attachmentType: targetPdfAttachmentItem.getContentType(),
      );

      if (res != null) {
        // 添加到最近打开的附件
        zoteroDB.addRecentlyOpenedAttachments(targetPdfAttachmentItem);
      }
    }
  }

  Future<void> openPdfWithUrlLauncher(BuildContext context, File pdfFile, Item targetPdfAttachmentItem) async {
    try {
      final result = await OpenFilex.open(
        pdfFile.path,
        type: "application/pdf",
      );

      MyLogger.d('打开PDF结果: ${result.type} - ${result.message}');

      switch (result.type) {
        case ResultType.done:
          MyLogger.d('已打开 ${targetPdfAttachmentItem.getTitle()}');
          zoteroDB.addRecentlyOpenedAttachments(targetPdfAttachmentItem);
          break;
        case ResultType.noAppToOpen:
          BrnToast.show('未找到可以打开PDF的应用，请安装PDF阅读器', context);
          break;
        case ResultType.fileNotFound:
          BrnToast.show('文件不存在', context);
          break;
        case ResultType.permissionDenied:
          BrnToast.show('没有权限打开文件', context);
          break;
        case ResultType.error:
          BrnToast.show('打开失败: ${result.message}', context);
          break;
      }
    } catch (e) {
      MyLogger.e('打开PDF失败: $e');
      BrnToast.show('打开PDF失败: $e', context);
    }
  }

  /// 检查条目是否为pdf附件条目
  bool isPdfAttachmentItem(Item item) {
    return item.getFileExtension().toLowerCase() == "pdf";
  }

  /// 检查条目是否有PDF附件
  bool itemHasPdfAttachment(Item item) {
    if (isPdfAttachmentItem(item)) return true;
    return item.attachments.any((attachment) =>
        isPdfAttachmentItem(attachment)
    );
  }

  /// 检查附件是否正在下载
  bool isAttachmentDownloading(String itemKey) {
    final state = _downloadStates[itemKey];
    return state?.status == DownloadStatus.downloading ||
        state?.status == DownloadStatus.extracting;
  }
  
  /// 更新下载状态（内部方法）
  void _updateDownloadState(AttachmentDownloadInfo downloadInfo) {
    _downloadStates[downloadInfo.itemKey] = downloadInfo;
    MyLogger.d('更新下载状态: ${downloadInfo.itemKey} - ${downloadInfo.status} - ${downloadInfo.progressPercent}%');
    _onDownloadStateUpdate?.call(downloadInfo);
  }
  
  /// 移除下载状态（内部方法）
  void _removeDownloadState(String itemKey) {
    _downloadStates.remove(itemKey);
    MyLogger.d('移除下载状态: $itemKey');
    _onDownloadStateRemove?.call(itemKey);
  }
  
  /// 打开pdf或下载（如果未下载）
  /// 这是主要的入口方法，包含完整的下载、取消、打开逻辑
  Future<void> openOrDownloadPdf(BuildContext context, Item item) async {
    // 找到item对应的pdf文件
    Item? targetPdfAttachmentItem;
    // 检测item自身是否是pdf文件
    if (isPdfAttachmentItem(item)) {
      targetPdfAttachmentItem = item;
    } else {
      // 检测item的附件中是否有pdf文件
      if (itemHasPdfAttachment(item)) {
        targetPdfAttachmentItem = item.attachments.firstWhere((element) => isPdfAttachmentItem(element));
      }
    }

    if (targetPdfAttachmentItem == null) {
      throw "没有找到pdf文件";
    }

    // 检查是否正在下载，如果是则取消下载
    if (isAttachmentDownloading(targetPdfAttachmentItem.itemKey)) {
      await _cancelDownload(context, targetPdfAttachmentItem);
      return;
    }

    // 检查是否已下载
    bool isDownloaded = await DefaultAttachmentStorage.instance.attachmentExists(targetPdfAttachmentItem);
    if (isDownloaded) {
      // 打开pdf
      await openDownloadedPdf(context, targetPdfAttachmentItem);
      return;
    }

    // 开始下载
    await _startDownload(context, targetPdfAttachmentItem);
  }
  
  /// 开始下载附件
  Future<void> _startDownload(BuildContext context, Item targetPdfAttachmentItem) async {
    final downloadHelper = ZoteroAttachDownloaderHelper.instance;

    try {
      final itemKey = targetPdfAttachmentItem.itemKey;
      
      // 清除文件存在状态缓存，因为要开始下载了
      _onFileExistsCacheUpdate?.call(itemKey, false);
      
      // 立即设置初始下载状态，确保UI显示进度环
      final initialDownloadInfo = AttachmentDownloadInfo(
        itemKey: itemKey,
        filename: targetPdfAttachmentItem.getTitle(),
        progress: 0,
        total: 100,
        status: DownloadStatus.downloading,
      );
      _updateDownloadState(initialDownloadInfo);
      
      await downloadHelper.startDownloadAttachment(
        targetPdfAttachmentItem,
        onProgress: (info) {
          // 更新下载进度状态
          _updateDownloadState(info);
          MyLogger.d('下载进度 ${info.itemKey}: ${info.progressPercent.toStringAsFixed(1)}%');
        },
        onComplete: (info, success) {
          if (success) {
            // 下载完成，更新文件存在状态缓存并移除下载状态
            _onFileExistsCacheUpdate?.call(info.itemKey, true);
            _removeDownloadState(info.itemKey);
            BrnToast.show("下载完成附件: ${info.filename}", context);
            MyLogger.d('下载完成 ${info.itemKey}: ${info.filename}');
          } else {
            // 下载失败，更新状态为失败
            _updateDownloadState(info.copyWith(status: DownloadStatus.failed));
            MyLogger.e('下载失败 ${info.itemKey}');
          }
        },
        onError: (info, error) {
          // 下载错误，移除下载状态
          _removeDownloadState(info.itemKey);
          
          if (error is DownloadException) {
            switch (error.errorType) {
              case DownloadErrorType.notFound:
                BrnToast.show("在Zotero服务器找不到附件，请确认该附件是否保存在WebDAV服务器中", context);
                MyLogger.w('下载失败，附件[${info.itemKey}, ${info.filename}]不存在');
                break;
              case DownloadErrorType.network:
                BrnToast.show("网络连接失败，请检查网络设置", context);
                MyLogger.w('下载失败，网络错误: ${info.itemKey}');
                break;
              case DownloadErrorType.timeout:
                BrnToast.show("下载超时，请重试", context);
                MyLogger.w('下载失败，超时: ${info.itemKey}');
                break;
              default:
                BrnToast.show("下载出错: ${error.message}", context);
                MyLogger.e('下载出错 ${info.itemKey}: ${error.message}');
            }
          } else {
            // 处理其他类型的异常
            BrnToast.show("下载出错: $error", context);
            MyLogger.e('下载出错 ${info.itemKey}: $error');
          }
        },
      );
    } catch (e) {
      // 处理同步错误（如未初始化、正在下载等），移除下载状态
      _removeDownloadState(targetPdfAttachmentItem.itemKey);
      
      if (e is DownloadException) {
        BrnToast.show(e.message, context);
      } else {
        BrnToast.show("下载失败: $e", context);
      }
      MyLogger.e('下载启动失败: $e');
    }
  }

  /// 取消下载
  Future<void> _cancelDownload(BuildContext context, Item targetPdfAttachmentItem) async {
    final downloadHelper = ZoteroAttachDownloaderHelper.instance;
    
    try {
      await downloadHelper.cancelDownload(targetPdfAttachmentItem.itemKey);
      
      // 清理临时文件
      await _cleanupTempFiles(targetPdfAttachmentItem);
      
      // 移除下载状态
      _removeDownloadState(targetPdfAttachmentItem.itemKey);
      
      // BrnToast.show("已取消下载", context);
      MyLogger.d('取消下载: ${targetPdfAttachmentItem.itemKey}');
    } catch (e) {
      BrnToast.show("取消下载失败: $e", context);
      MyLogger.e('取消下载失败: $e');
    }
  }

  /// 清理临时文件
  Future<void> _cleanupTempFiles(Item item) async {
    try {
      final storage = DefaultAttachmentStorage.instance;
      final tempFile = await storage.getDownloadTempFile(item);
      
      if (await tempFile.exists()) {
        await tempFile.delete();
        MyLogger.d('清理临时文件: ${tempFile.path}');
      }
    } catch (e) {
      MyLogger.w('清理临时文件失败: $e');
    }
  }
}