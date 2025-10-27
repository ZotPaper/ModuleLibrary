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

class AttachmentStrategyManager {
  // 单例模式
  static final AttachmentStrategyManager instance = AttachmentStrategyManager._internal();
  AttachmentStrategyManager._internal();

  final ZoteroDB zoteroDB = ZoteroProvider.getZoteroDB();

  // 下载状态跟踪
  final Map<String, AttachmentDownloadInfo> _downloadStates = {};

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
}