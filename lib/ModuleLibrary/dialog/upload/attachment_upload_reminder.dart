import 'package:flutter/material.dart';
import 'package:module_base/utils/tracking/dot_tracker.dart';
import 'package:module_base/view/dialog/neat_dialog.dart';
import 'package:bruno/bruno.dart';
import 'package:dio/dio.dart';

import '../../../LibZoteroAttachDownloader/dialog/attachment_transfer_dialog_manager.dart';
import '../../../LibZoteroAttachDownloader/model/status.dart';
import '../../../LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import '../../../LibZoteroAttachDownloader/zotero_attachment_transfer.dart';
import '../../../LibZoteroStorage/database/dao/RecentlyOpenedAttachmentDao.dart';
import '../../../LibZoteroStorage/entity/Item.dart';
import '../../../utils/log/module_library_log_helper.dart';
import '../../utils/my_logger.dart';
import '../../viewmodels/library_viewmodel.dart';
import '../../widget/modified_attachments_banner.dart';

/// 附件上传提醒管理类
/// 负责管理修改附件的检测、提示栏显示、对话框显示以及上传逻辑
class AttachmentUploadReminder extends ChangeNotifier {
  // 修改的附件信息
  List<Item>? _modifiedItems;
  List<RecentlyOpenedAttachment>? _modifiedAttachments;
  bool _showModifiedBanner = false;

  // ViewModel 引用
  final LibraryViewModel _viewModel;

  // 刷新回调
  final VoidCallback? onNeedRefresh;

  AttachmentUploadReminder({
    required LibraryViewModel viewModel,
    this.onNeedRefresh,
  }) : _viewModel = viewModel;

  /// 获取是否显示提示栏
  bool get showModifiedBanner => _showModifiedBanner;

  /// 获取修改的条目数量
  int get modifiedCount => _modifiedItems?.length ?? 0;

  /// 获取修改的条目列表
  List<Item>? get modifiedItems => _modifiedItems;

  /// 获取修改的附件列表
  List<RecentlyOpenedAttachment>? get modifiedAttachments => _modifiedAttachments;

  /// 当发现修改的附件时的回调处理
  void onModifiedAttachmentsFound(
      List<Item> modifiedItems,
      List<RecentlyOpenedAttachment> attachments,
  ) {
    _modifiedItems = modifiedItems;
    _modifiedAttachments = attachments;

    MyLogger.d("AttachmentUploadReminder=== modifiedItems数量：${_modifiedItems?.length} "
        "RecentlyOpenedAttachment数量：${_modifiedAttachments?.length}");

    // 判断是否显示提示栏
    final shouldShow = _modifiedItems?.isNotEmpty == true && _modifiedItems?.isNotEmpty == true;
    _showModifiedBanner = shouldShow;
    
    notifyListeners();
  }

  /// 关闭修改附件提示栏
  void dismissModifiedBanner() {
    _showModifiedBanner = false;
    notifyListeners();

    // 清除修改标记
    if (_modifiedAttachments != null) {
      _viewModel.clearModifiedAttachmentsMarks(_modifiedAttachments!);
    }
  }

  /// 构建修改附件提示栏 Widget
  Widget buildModifiedBanner({
    required BuildContext context,
    // VoidCallback? onTap,
  }) {
    if (!_showModifiedBanner) {
      return const SizedBox.shrink();
    }

    return ModifiedAttachmentsBanner(
      modifiedCount: modifiedCount,
      onTap: () => showModifiedAttachmentsDialog(context),
      onDismiss: dismissModifiedBanner,
    );
  }

  /// 显示修改的附件对话框
  void showModifiedAttachmentsDialog(BuildContext context) {
    if (_modifiedItems == null || _modifiedAttachments == null) return;

    MyLogger.d("AttachmentUploadReminder=== 显示修改的附件对话框");

    final strModified = _modifiedItems!
        .map((item) => "\<font color = '#8ac6d1'\>${item.getTitle()}</font>")
        .join(', ');

    NeatDialogManager.showConfirmDialog(
      context,
      cancel: "稍后处理",
      confirm: "立即上传",
      title: "检测到附件修改",
      message: "检测到 ${_modifiedItems!.length} 个附件已被修改，是否需要上传到Zotero服务器？",
      messageWidget: Padding(
        padding: const EdgeInsets.only(top: 6, left: 24, right: 24),
        child: BrnCSS2Text.toTextView(
          "检测到 ${_modifiedItems!.length} 个附件已被修改，是否需要上传到服务器进行更新？\n"
              "修改的附件：\n $strModified",
        ),
      ),
      showIcon: true,
      onConfirm: (BuildContext dialogContext) {
        // 隐藏提示栏
        _showModifiedBanner = false;
        notifyListeners();

        Navigator.of(dialogContext).pop();

        // 开始上传修改的附件（会显示进度对话框）
        _startUploadModifiedAttachments(context, _modifiedItems!, _modifiedAttachments!);

        // 关闭附件改变提示栏
        dismissModifiedBanner();
      },
      onCancel: (BuildContext dialogContext) {
        // 隐藏提示栏
        _showModifiedBanner = false;
        notifyListeners();

        Navigator.of(dialogContext).pop();
      },
    );
  }

  /// 开始上传修改的附件
  Future<void> _startUploadModifiedAttachments(
      BuildContext context,
      List<Item> modifiedItems,
      List<RecentlyOpenedAttachment> attachments,
  ) async {
    final totalCount = modifiedItems.length;
    int successCount = 0;
    Map<String, String> failedItemsWithErrors = {}; // 保存失败的附件和错误信息

    try {
      // 逐个上传附件
      for (int i = 0; i < modifiedItems.length; i++) {
        final item = modifiedItems[i];

        try {
          MyLogger.d('开始上传附件 ${i + 1}/$totalCount: ${item.getTitle()}');

          // 更新上传状态到ViewModel（会自动通知全局指示器更新）
          _viewModel.updateUploadProgress(
            item: item,
            currentIndex: i + 1,
            totalCount: totalCount,
          );

          // 上传单个附件
          await _viewModel.uploadSingleAttachment(item);

          // 从最近打开的附件列表中移除
          await _viewModel.zoteroDB.removeRecentlyOpenedAttachment(item.itemKey);

          // 上传完成后移除该附件的上传状态
          _viewModel.removeUploadProgress(item.itemKey);

          successCount++;
          MyLogger.d('附件上传成功: ${item.getTitle()}');

          // 附件上传成功 日志与埋点上报
          ModuleLibraryLogHelper.attachmentTransfer.logUploadSuccess(item);

        } catch (e) {
          final errorMsg = _parseUploadError(e);
          MyLogger.e('附件上传失败: ${item.getTitle()}, 错误: $errorMsg');
          failedItemsWithErrors[item.getTitle()] = errorMsg;

          // 更新为失败状态，显示在全局指示器中
          _viewModel.updateUploadProgress(
            item: item,
            currentIndex: i + 1,
            totalCount: totalCount,
            status: UploadStatus.failed,
            errorMessage: errorMsg,
          );

          // 延迟移除失败状态，让用户有时间看到
          Future.delayed(const Duration(seconds: 3), () {
            _viewModel.removeUploadProgress(item.itemKey);
          });
        }
      }

      // 显示结果
      if (!context.mounted) return;

      var needRefresh = false;
      if (failedItemsWithErrors.isEmpty) {
        // 全部成功
        BrnToast.show('所有附件上传成功！', context);

        var isZotero = ZoteroAttachDownloaderHelper.instance.transfer is ZoteroAttachmentTransfer;

        // 埋点上报
        DotTracker
            .addBot("UPLOAD_ALL_MODIFIED_SUCCESS", description: "所有附件上传成功")
            .addParam("total", modifiedItems.length)
            .addParam("service", isZotero ? "Zotero" : "WEBDAV")
            .report();

        needRefresh = true;
      } else if (successCount > 0) {
        // 部分成功 - 显示详细错误信息
        AttachmentTransferDialogManager.showUploadErrorInfo(
          context: context,
          successCount: successCount,
          totalCount: totalCount,
          failedItems: failedItemsWithErrors,
        );
        needRefresh = true;
      } else {
        // 全部失败 - 显示详细错误信息
        AttachmentTransferDialogManager.showUploadErrorInfo(
          context: context,
          successCount: 0,
          totalCount: totalCount,
          failedItems: failedItemsWithErrors,
        );
      }
      
      if (needRefresh) {
        // 有上传成功的附件，执行刷新回调（同步操作）
        onNeedRefresh?.call();
      }
    } catch (e) {
      MyLogger.e('上传附件时发生错误: $e');
      // 清除所有上传状态
      for (var item in modifiedItems) {
        _viewModel.removeUploadProgress(item.itemKey);
      }
      if (context.mounted) {
        final errorMsg = _parseUploadError(e);
        BrnToast.show('上传失败：$errorMsg', context);
      }
    }
  }

  /// 解析上传错误信息，返回用户友好的错误描述
  String _parseUploadError(dynamic error) {
    String errorStr = error.toString();
    if (error is DioException) {
      errorStr = "errorCode[${error.response?.statusCode}], message: ${error.message}";
    }

    if (errorStr.contains('NetworkException')) {
      return '网络连接失败: $errorStr';
    } else if (errorStr.contains('timeout') || errorStr.contains('TimeoutException')) {
      return '连接超时: $errorStr';
    } else if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return '认证失败，请重新登录: $errorStr';
    } else if (errorStr.contains('404') || errorStr.contains('not found') || errorStr.contains("PathNotFoundException")) {
      return '文件未找到: $errorStr';
    } else if (errorStr.contains('500') || errorStr.contains('server error')) {
      return '服务器错误: $errorStr';
    } else {
      // 返回简化的错误信息
      return errorStr;
    }
  }
}
