import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_base/view/toast/neat_toast.dart';
import 'package:module_library/LibZoteroAttachment/attachment_strategy_manager.dart';
import 'package:module_library/LibZoteroAttachDownloader/default_attachment_storage.dart';
import 'package:module_library/LibZoteroAttachDownloader/model/transfer_info.dart';

import '../../LibZoteroStorage/entity/Item.dart';

class ItemDetailAttachmentFragment extends StatefulWidget {
  final Item item;
  const ItemDetailAttachmentFragment(this.item, {super.key});

  @override
  State<ItemDetailAttachmentFragment> createState() => _ItemDetailAttachmentFragmentState();
}

class _ItemDetailAttachmentFragmentState extends State<ItemDetailAttachmentFragment> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<Item> attachments = [];
  
  // 下载状态回调，用于监听下载进度
  DownloadStateCallback? _downloadStateCallback;
  DownloadStateRemoveCallback? _downloadStateRemoveCallback;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    widget.item.attachments.forEach((attachment) {
      attachments.add(attachment);
    });
    
    // 设置下载状态回调
    _setupDownloadCallbacks();
  }
  
  void _setupDownloadCallbacks() {
    final manager = AttachmentStrategyManager.instance;
    
    // 监听下载状态更新
    _downloadStateCallback = (downloadInfo) {
      if (mounted) {
        setState(() {
          // 触发重建以更新进度显示
        });
      }
    };
    
    _downloadStateRemoveCallback = (itemKey) {
      if (mounted) {
        setState(() {
          // 触发重建以清除进度显示
        });
      }
    };
    
    // 注册监听器
    manager.addDownloadStateUpdateListener(_downloadStateCallback!);
    manager.addDownloadStateRemoveListener(_downloadStateRemoveCallback!);
  }

  @override
  void dispose() {
    _controller.dispose();
    
    // 清理监听器，避免内存泄漏
    final manager = AttachmentStrategyManager.instance;
    if (_downloadStateCallback != null) {
      manager.removeDownloadStateUpdateListener(_downloadStateCallback!);
    }
    if (_downloadStateRemoveCallback != null) {
      manager.removeDownloadStateRemoveListener(_downloadStateRemoveCallback!);
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Text('附件列表', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 4),
            ...attachments.map((attachment) => _attachmentItem(attachment)),
            _addAttachmentButton(),
          ],
        ));
  }

  Widget _attachmentItem(Item attachment) {
    // 获取下载状态
    final downloadInfo = AttachmentStrategyManager.instance.getDownloadStatus(attachment.itemKey);
    final isDownloading = AttachmentStrategyManager.instance.isAttachmentDownloading(attachment.itemKey);
    
    return Card(
      color: Colors.grey[100],
      elevation: 0,
      child: InkWell(
        onTap: () {
          _openOrDownload(context, attachment);
        },
        child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                // 根据下载状态显示不同的图标
                _buildAttachmentIcon(attachment, isDownloading, downloadInfo),
                const SizedBox(width: 8),
                Expanded(child: Text(attachment.getTitle(), overflow: TextOverflow.ellipsis,)),
              ],
            )
        ),
      ),
    );
  }
  
  /// 构建附件图标，下载时显示进度
  Widget _buildAttachmentIcon(Item attachment, bool isDownloading, AttachmentDownloadInfo? downloadInfo) {
    if (isDownloading && downloadInfo != null) {
      // 显示下载进度（环形进度条）
      final progress = downloadInfo.progressPercent / 100;
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.5,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          backgroundColor: Colors.grey[300],
        ),
      );
    } else {
      // 显示普通附件图标
      return const Icon(Icons.attach_file, size: 20, color: Colors.blue);
    }
  }

  Widget _addAttachmentButton() {
    return InkWell(
      onTap: () {
        context.toastNormal("添加附件，功能待开发！！！");
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              "添加附件",
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _openOrDownload(BuildContext context, Item attachment) {
    try {
      // 使用 AttachmentStrategyManager 处理打开或下载
      // 这会自动处理：1. 如果正在下载则取消 2. 如果已下载则打开 3. 如果未下载则开始下载
      AttachmentStrategyManager.instance.openOrDownloadPdf(context, attachment);
    } catch (e) {
      context.toastError("操作失败: $e");
    }
  }

}
