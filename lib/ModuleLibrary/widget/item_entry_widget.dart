import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bruno/bruno.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/ModuleLibrary/model/list_entry.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';
import 'package:module_library/ModuleLibrary/utils/color_utils.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/ModuleLibrary/widget/attachment_indicator.dart';
import 'package:module_library/ModuleLibrary/widget/item_type_icon.dart';

/// Item条目列表组件
/// 
/// 用于在列表中显示Zotero条目，包括：
/// - 条目类型图标
/// - 标题和作者
/// - 重要标签
/// - PDF附件指示器
/// - 更多操作按钮
class ItemEntryWidget extends StatelessWidget {
  final Item item;
  final LibraryViewModel viewModel;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;
  final VoidCallback? onPdfTap;

  const ItemEntryWidget({
    super.key,
    required this.item,
    required this.viewModel,
    this.onTap,
    this.onMorePressed,
    this.onPdfTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        child: Row(
          children: [
            _buildEntryIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.getTitle(),
                    maxLines: 2,
                    style: TextStyle(color: ResColor.textMain),
                  ),
                  Text(
                    item.getAuthor(),
                    maxLines: 1,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  _buildImportantTags(),
                ],
              ),
            ),
            if (_hasPdfAttachment()) _buildAttachmentIndicator(),
            IconButton(
              onPressed: onMorePressed,
              icon: Icon(
                Icons.more_vert_sharp,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建条目图标
  Widget _buildEntryIcon() {
    return Container(
      height: 42,
      width: 42,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(26),
      ),
      child: ItemTypeIcon.fromItemType(
        itemType: item.itemType,
        size: 16,
      ),
    );
  }

  /// 条目是否有PDF附件
  bool _hasPdfAttachment() {
    return viewModel.itemHasPdfAttachment(item);
  }

  /// 构建附件指示器
  Widget _buildAttachmentIndicator() {
    return AttachmentIndicator(
      item: item,
      viewModel: viewModel,
      onTap: onPdfTap ?? () {},
    );
  }

  /// 构建重要标签
  Widget _buildImportantTags() {
    if (item.getTagList().isEmpty) {
      return Container();
    }

    // 获取item的标签
    final tags = viewModel.getImportTagOfItemSync(item);
    if (tags.isEmpty) {
      return Container();
    }

    return Row(
      children: tags.map<Widget>((tag) {
        return Container(
          margin: const EdgeInsets.only(right: 2),
          child: BrnTagCustom(
            tagText: tag.name,
            textColor: ColorUtils.hexToColor(tag.color),
            backgroundColor: const Color(0xFFF1F2FA),
          ),
        );
      }).toList(),
    );
  }
} 