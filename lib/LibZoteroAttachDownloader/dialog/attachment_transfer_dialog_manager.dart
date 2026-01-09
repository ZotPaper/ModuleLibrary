import 'package:flutter/material.dart';
import 'package:module_base/utils/tracking/dot_tracker.dart';
import 'package:module_base/view/dialog/neat_dialog.dart';
import 'package:bruno/bruno.dart';

class AttachmentTransferDialogManager {

  /// 显示上传结果对话框（包含详细错误信息）
  static void showUploadErrorInfo({
    required BuildContext context,
    required int successCount,
    required int totalCount,
    required Map<String, String> failedItems,
  }) {
    final failedCount = failedItems.length;

    // 构建失败列表的HTML
    final failedListHtml = failedItems.entries
        .map((entry) =>
    "\<font color='#8ac6d1'\>${entry.key}</font>\n"
        "\<font color='#ff6b6b'\>错误：${entry.value}</font>")
        .join('\n\n');

    // 埋点上报
    DotTracker
        .addDot("SHOW_UPLOAD_ERROR_RESULT", description: "显示上传结果对话框")
        .addParam("successCount", successCount)
        .addParam("failedCount", failedCount)
        .report();

    NeatDialogManager.showConfirmDialog(
      context,
      title: "上传附件结果",
      messageWidget: Padding(
        padding: const EdgeInsets.only(top: 6, left: 24, right: 24),
        child: BrnCSS2Text.toTextView(
          successCount > 0
              ? "成功上传 $successCount 个附件\n失败 $failedCount 个附件\n\n失败详情：\n$failedListHtml"
              : "所有附件上传失败\n\n失败详情：\n$failedListHtml",
        ),
      ),
      showIcon: false,
      confirm: "确定",
      cancel: '取消',
      onConfirm: (dialogContext) {
        Navigator.of(dialogContext).pop();
      },
      onCancel: (dialogContext) {
        Navigator.of(dialogContext).pop();
      },
    );
  }

}