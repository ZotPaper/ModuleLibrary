import 'package:flutter/material.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';

/// 上传进度对话框
/// 在中心显示半透明的上传进度
class UploadProgressDialog extends StatelessWidget {
  /// 当前进度（已上传数量）
  final int currentProgress;
  
  /// 总数量
  final int totalCount;
  
  /// 当前正在上传的文件名
  final String? currentFileName;
  
  /// 是否显示成功状态
  final bool isSuccess;
  
  /// 是否显示错误状态
  final bool hasError;
  
  /// 错误信息
  final String? errorMessage;

  const UploadProgressDialog({
    super.key,
    required this.currentProgress,
    required this.totalCount,
    this.currentFileName,
    this.isSuccess = false,
    this.hasError = false,
    this.errorMessage,
  });

  /// 显示上传进度对话框
  static void show(
    BuildContext context, {
    required int currentProgress,
    required int totalCount,
    String? currentFileName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // 背景透明
      builder: (context) => UploadProgressDialog(
        currentProgress: currentProgress,
        totalCount: totalCount,
        currentFileName: currentFileName,
      ),
    );
  }

  /// 更新进度（关闭旧的并显示新的）
  static void update(
    BuildContext context, {
    required int currentProgress,
    required int totalCount,
    String? currentFileName,
  }) {
    // Navigator.of(context).pop();
    show(
      context,
      currentProgress: currentProgress,
      totalCount: totalCount,
      currentFileName: currentFileName,
    );
  }

  /// 显示完成状态
  static void showSuccess(
    BuildContext context, {
    required int successCount,
    required int totalCount,
    Duration autoCloseDelay = const Duration(seconds: 2),
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent, // 背景透明
      builder: (context) => UploadProgressDialog(
        currentProgress: successCount,
        totalCount: totalCount,
        isSuccess: true,
      ),
    );
    
    // // 自动关闭
    // Future.delayed(autoCloseDelay, () {
    //   if (context.mounted) {
    //     Navigator.of(context).pop();
    //   }
    // });
  }

  /// 关闭对话框
  static void dismiss(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280), // 限制最大宽度，保持小巧
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), // 半透明暗色背景
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 12),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildProgress(),
              if (currentFileName != null && !isSuccess && !hasError) ...[
                const SizedBox(height: 8),
                _buildFileName(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图标
  Widget _buildIcon() {
    if (isSuccess) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 28,
        ),
      );
    } else if (hasError) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error,
          color: Colors.red,
          size: 28,
        ),
      );
    } else {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
  }

  /// 构建标题
  Widget _buildTitle() {
    String title;
    if (isSuccess) {
      title = '上传完成';
    } else if (hasError) {
      title = '上传失败';
    } else {
      title = '正在上传';
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  /// 构建进度
  Widget _buildProgress() {
    final progressText = '$currentProgress / $totalCount';
    
    return Column(
      children: [
        Text(
          progressText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isSuccess 
                ? Colors.green 
                : hasError 
                    ? Colors.red 
                    : Colors.white,
          ),
        ),
        if (!isSuccess && !hasError) ...[
          const SizedBox(height: 6),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? currentProgress / totalCount : 0,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ],
    );
  }

  /// 构建文件名
  Widget _buildFileName() {
    return Text(
      currentFileName!,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.7),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}

