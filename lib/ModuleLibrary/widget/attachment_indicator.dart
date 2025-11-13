import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';

import '../../LibZoteroAttachDownloader/model/status.dart';
import '../../LibZoteroAttachDownloader/model/transfer_info.dart';

/// 附件下载状态指示器组件
/// 
/// 用于显示PDF附件的下载状态，包括：
/// - 未下载：灰色PDF图标
/// - 下载中：蓝色圆形进度条
/// - 解压中：橙色旋转进度条
/// - 已下载：彩色PDF图标
/// - 下载失败：红色PDF图标
/// 
/// 特性：
/// - 自动缓存文件存在状态，避免重复检查
/// - 智能重建，只在状态真正变化时更新
/// - 防止并发检查同一文件
class AttachmentIndicator extends StatefulWidget {
  final Item item;
  final LibraryViewModel viewModel;
  final VoidCallback onTap;

  const AttachmentIndicator({
    super.key,
    required this.item,
    required this.viewModel,
    required this.onTap,
  });

  @override
  State<AttachmentIndicator> createState() => _AttachmentIndicatorState();
}

class _AttachmentIndicatorState extends State<AttachmentIndicator> {
  Item? targetPdfAttachmentItem;
  String? targetItemKey;
  AttachmentDownloadInfo? lastDownloadInfo;
  bool? lastFileExists;
  
  // 添加Future缓存，避免重复创建
  Future<bool>? _fileExistsCheckFuture;

  @override
  void initState() {
    super.initState();
    _findTargetPdfAttachment();
  }
  
  @override
  void didUpdateWidget(AttachmentIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果item变化了，重新查找PDF附件
    if (oldWidget.item != widget.item) {
      _findTargetPdfAttachment();
      _fileExistsCheckFuture = null; // 清除旧的Future缓存
      lastDownloadInfo = null;
      lastFileExists = null;
    }
  }

  void _findTargetPdfAttachment() {
    if (widget.viewModel.isPdfAttachmentItem(widget.item)) {
      targetPdfAttachmentItem = widget.item;
    } else if (widget.viewModel.itemHasPdfAttachment(widget.item)) {
      targetPdfAttachmentItem = widget.item.attachments.firstWhere(
        (element) => widget.viewModel.isPdfAttachmentItem(element),
      );
    }
    targetItemKey = targetPdfAttachmentItem?.itemKey;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        if (targetItemKey == null) {
          return InkWell(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: _buildNotDownloadedIndicator(),
            ),
          );
        }

        // 只获取这个特定item的状态
        final currentDownloadInfo = widget.viewModel.getDownloadStatus(targetItemKey!);
        final currentFileExists = widget.viewModel.getCachedFileExists(targetItemKey!);

        // 检查状态是否真的变化了
        final downloadInfoChanged = currentDownloadInfo != lastDownloadInfo;
        final fileExistsChanged = currentFileExists != lastFileExists;
        
        if (downloadInfoChanged || fileExistsChanged) {
          lastDownloadInfo = currentDownloadInfo;
          lastFileExists = currentFileExists;
          
          // 如果缓存状态变化了，清除Future缓存
          if (fileExistsChanged) {
            _fileExistsCheckFuture = null;
          }
        }

        return InkWell(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: _buildAttachmentIcon(currentDownloadInfo, currentFileExists),
          ),
        );
      },
    );
  }

  /// 根据下载状态构建附件图标
  Widget _buildAttachmentIcon(AttachmentDownloadInfo? downloadInfo, bool? cachedFileExists) {
    // 优先显示下载状态
    if (downloadInfo != null) {
      switch (downloadInfo.status) {
        case DownloadStatus.downloading:
          return _buildDownloadingIndicator(downloadInfo);
        case DownloadStatus.extracting:
          return _buildExtractingIndicator();
        case DownloadStatus.completed:
          return _buildCompletedIndicator();
        case DownloadStatus.failed:
          return _buildFailedIndicator();
        case DownloadStatus.cancelled:
          return _buildCancelledIndicator();
        default:
          return _buildDefaultIndicator();
      }
    }

    // 没有下载状态时，检查文件是否存在
    if (targetPdfAttachmentItem == null) {
      return _buildNotDownloadedIndicator();
    }

    // 如果有缓存值，直接使用
    if (cachedFileExists != null) {
      return cachedFileExists ? _buildDownloadedIndicator() : _buildNotDownloadedIndicator();
    }

    // 没有缓存值，需要异步检查（只创建一次Future）
    _fileExistsCheckFuture ??= widget.viewModel.checkAndCacheFileExists(targetPdfAttachmentItem!);
    
    return FutureBuilder<bool>(
      future: _fileExistsCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDefaultIndicator();
        }
        
        final isDownloaded = snapshot.data ?? false;
        return isDownloaded ? _buildDownloadedIndicator() : _buildNotDownloadedIndicator();
      },
    );
  }

  /// 下载中：圆形进度环
  Widget _buildDownloadingIndicator(AttachmentDownloadInfo downloadInfo) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: downloadInfo.progressPercent / 100,
              strokeWidth: 2.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          // 中心的取消图标
          const Icon(
            Icons.close,
            size: 10,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  /// 解压中：旋转的进度环
  Widget _buildExtractingIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      ),
    );
  }

  /// 下载完成：PDF图标（绿色）
  Widget _buildCompletedIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
        colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
      ),
    );
  }

  /// 下载失败：PDF图标（红色）
  Widget _buildFailedIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
        colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
      ),
    );
  }

  /// 下载取消：PDF图标（灰色）
  Widget _buildCancelledIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
      ),
    );
  }

  /// 默认状态：PDF图标
  Widget _buildDefaultIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
      ),
    );
  }

  /// 文件已下载：显示已下载图标
  Widget _buildDownloadedIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
      ),
    );
  }

  /// 文件未下载：显示未下载图标
  Widget _buildNotDownloadedIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf_not_download.svg",
        height: 20,
        width: 20,
        package: 'module_library',
      ),
    );
  }
} 