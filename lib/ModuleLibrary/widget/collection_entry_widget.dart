import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/ModuleLibrary/widget/item_type_icon.dart';

/// Collection集合列表组件
/// 
/// 用于在列表中显示Zotero集合，包括：
/// - 文件夹图标
/// - 集合名称
/// - 子项数量
/// - 更多操作按钮
class CollectionEntryWidget extends StatelessWidget {
  final Collection collection;
  final LibraryViewModel viewModel;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;

  const CollectionEntryWidget({
    super.key,
    required this.collection,
    required this.viewModel,
    this.onTap,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final int sizeSub = viewModel.getNumInCollection(collection);

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
                    collection.name,
                    maxLines: 2,
                    style: TextStyle(color: ResColor.textMain),
                  ),
                  Text(
                    "$sizeSub条子项",
                    maxLines: 1,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
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

  /// 构建文件夹图标
  Widget _buildEntryIcon() {
    return Container(
      height: 42,
      width: 42,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(26),
      ),
      child: ItemTypeIcon.folder(size: 16),
    );
  }
} 