import 'package:flutter/material.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';

/// 修改附件提示栏
/// 用于在检测到附件修改时显示提示信息
class ModifiedAttachmentsBanner extends StatelessWidget {
  /// 修改的附件数量
  final int modifiedCount;
  
  /// 点击提示栏时的回调
  final VoidCallback onTap;
  
  /// 点击关闭按钮时的回调
  final VoidCallback onDismiss;

  const ModifiedAttachmentsBanner({
    super.key,
    required this.modifiedCount,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ResColor.bgAccent.withOpacity(0.12),
            ResColor.bgAccent.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ResColor.bgAccent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // 上传图标
                _buildIcon(),
                const SizedBox(width: 12),
                // 文案内容
                Expanded(
                  child: _buildTextContent(),
                ),
                // 右侧操作按钮
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建图标
  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ResColor.bgAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.cloud_upload_outlined,
        color: ResColor.bgAccent,
        size: 20,
      ),
    );
  }

  /// 构建文案内容
  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '附件发生了修改，请上传',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ResColor.textMain,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '检测到 $modifiedCount 个附件已被修改',
          style: TextStyle(
            fontSize: 12,
            color: ResColor.textMain,
          ),
        ),
      ],
    );
  }

  /// 构建右侧操作按钮
  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 查看详情按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ResColor.bgAccent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '查看',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 关闭按钮
        InkWell(
          onTap: onDismiss,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.close,
              size: 18,
              color: ResColor.textMain,
            ),
          ),
        ),
      ],
    );
  }
}

