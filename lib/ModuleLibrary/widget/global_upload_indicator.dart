import 'package:flutter/material.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';

/// 全局上传进度指示器组件
/// 
/// 用于在页面底部显示所有正在进行的附件上传任务
/// 特性：
/// - 跨目录显示，切换目录时上传进度不会消失
/// - 自动监听上传状态变化
/// - 最多显示3个上传任务，超过时显示总数
/// - 上传完成后自动隐藏
class GlobalUploadIndicator extends StatelessWidget {
  final LibraryViewModel viewModel;

  const GlobalUploadIndicator({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final activeUploads = viewModel.getActiveUploads();
        
        if (activeUploads.isEmpty) {
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
                  _buildHeader(activeUploads.length),
                  const SizedBox(height: 8),
                  ..._buildUploadItems(activeUploads),
                  if (activeUploads.length > 3)
                    _buildMoreIndicator(activeUploads.length),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题栏
  Widget _buildHeader(int uploadCount) {
    return Row(
      children: [
        Icon(Icons.cloud_upload_outlined, color: ResColor.bgAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          '正在上传 $uploadCount 个附件',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: ResColor.textMain,
          ),
        ),
      ],
    );
  }

  /// 构建上传项列表（最多显示3个）
  List<Widget> _buildUploadItems(List<AttachmentUploadInfo> uploads) {
    return uploads.take(3).map((uploadInfo) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildUploadItem(uploadInfo),
      );
    }).toList();
  }

  /// 构建单个上传项
  Widget _buildUploadItem(AttachmentUploadInfo uploadInfo) {
    final isFailed = uploadInfo.status == UploadStatus.failed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 失败时显示错误图标
            if (isFailed) ...[
              const Icon(
                Icons.error_outline,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                uploadInfo.filename,
                style: TextStyle(
                  fontSize: 12,
                  color: isFailed ? Colors.red : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isFailed ? '失败' : '${uploadInfo.currentIndex}/${uploadInfo.totalCount}',
              style: TextStyle(
                fontSize: 12,
                color: isFailed ? Colors.red : Colors.grey.shade600,
                fontWeight: isFailed ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (isFailed && uploadInfo.errorMessage != null) ...[
          Text(
            uploadInfo.errorMessage!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.red.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        _buildProgressBar(uploadInfo),
      ],
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(AttachmentUploadInfo uploadInfo) {
    final isFailed = uploadInfo.status == UploadStatus.failed;
    final progress = uploadInfo.totalCount > 0 
        ? uploadInfo.currentIndex / uploadInfo.totalCount 
        : 0.0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation<Color>(
          isFailed ? Colors.red : ResColor.bgAccent,
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
        '还有 ${totalCount - 3} 个上传任务...',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

