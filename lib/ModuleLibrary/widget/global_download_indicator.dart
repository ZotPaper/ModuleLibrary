import 'package:flutter/material.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';

import '../../LibZoteroAttachDownloader/model/status.dart';
import '../../LibZoteroAttachDownloader/model/transfer_info.dart';

/// 全局下载进度指示器组件
/// 
/// 用于在页面底部显示所有正在进行的附件下载任务
/// 特性：
/// - 跨目录显示，切换目录时下载进度不会消失
/// - 自动监听下载状态变化
/// - 最多显示3个下载任务，超过时显示总数
/// - 下载完成后自动隐藏
class GlobalDownloadIndicator extends StatelessWidget {
  final LibraryViewModel viewModel;

  const GlobalDownloadIndicator({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final activeDownloads = viewModel.getActiveDownloads();
        
        if (activeDownloads.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(activeDownloads.length),
                  const SizedBox(height: 8),
                  ..._buildDownloadItems(activeDownloads),
                  if (activeDownloads.length > 3)
                    _buildMoreIndicator(activeDownloads.length),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题栏
  Widget _buildHeader(int downloadCount) {
    return Row(
      children: [
        Icon(Icons.download_outlined, color: ResColor.textMain, size: 20),
        const SizedBox(width: 8),
        Text(
          '正在下载 $downloadCount 个附件',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: ResColor.textMain,
          ),
        ),
      ],
    );
  }

  /// 构建下载项列表（最多显示3个）
  List<Widget> _buildDownloadItems(List<AttachmentDownloadInfo> downloads) {
    return downloads.take(3).map((downloadInfo) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildDownloadItem(downloadInfo),
      );
    }).toList();
  }

  /// 构建单个下载项
  Widget _buildDownloadItem(AttachmentDownloadInfo downloadInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                downloadInfo.filename,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${downloadInfo.progressPercent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildProgressBar(downloadInfo),
      ],
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(AttachmentDownloadInfo downloadInfo) {
    final isExtracting = downloadInfo.status == DownloadStatus.extracting;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: downloadInfo.progressPercent / 100,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation<Color>(
          isExtracting ? Colors.orange : Colors.blue,
        ),
        minHeight: 4,
      ),
    );
  }

  /// 构建"更多"提示
  Widget _buildMoreIndicator(int totalCount) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '还有 ${totalCount - 3} 个下载任务...',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
} 