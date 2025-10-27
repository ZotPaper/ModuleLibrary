import 'package:flutter/material.dart';
import 'package:bruno/bruno.dart';
import 'package:module_base/view/dialog/neat_dialog.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/utils/sheet_item_helper.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';

/// 条目操作面板
/// 
/// 显示条目的各种操作选项，包括：
/// - 在线查看
/// - 添加/移除收藏
/// - 移动到回收站/还原
/// - 删除已下载的附件
/// - 更改所属集合
/// 
/// 使用示例：
/// ```dart
/// ItemOperationPanel.show(
///   context: context,
///   item: myItem,
///   viewModel: viewModel,
/// );
/// ```
class ItemOperationPanel {
  /// 显示条目操作面板
  static void show({
    required BuildContext context,
    required Item item,
    required LibraryViewModel viewModel,
  }) {
    final operationItems = _buildOperationItems(
      context: context,
      item: item,
      viewModel: viewModel,
    );

    // 转换为BrnCommonActionSheetItem
    final actionSheetItems = operationItems.map((ele) {
      var actionStyle = BrnCommonActionSheetItemStyle.normal;
      if (ele.actionStyle != null && ele.actionStyle == "alert") {
        actionStyle = BrnCommonActionSheetItemStyle.alert;
      }
      return BrnCommonActionSheetItem(
        ele.title,
        desc: ele.desc,
        actionStyle: actionStyle,
      );
    }).toList();

    // 展示actionSheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (BuildContext bottomSheetContext) {
        return BrnCommonActionSheet(
          title: item.getTitle(),
          actions: actionSheetItems,
          cancelTitle: "取消",
          clickCallBack: (int index, BrnCommonActionSheetItem actionEle) {
            operationItems[index].onClick?.call();
          },
        );
      },
    );
  }

  /// 构建操作项列表
  static List<ItemClickProxy> _buildOperationItems({
    required BuildContext context,
    required Item item,
    required LibraryViewModel viewModel,
  }) {
    List<ItemClickProxy> items = [];

    // 1. 在线查看
    items.add(ItemClickProxy(
      title: "在线查看",
      desc: "在线查看条目的最新信息",
      onClick: () {
        viewModel.viewItemOnline(context, item);
      },
    ));

    // 2. 收藏/取消收藏
    final isStared = viewModel.isItemStarred(item);
    if (isStared) {
      items.add(ItemClickProxy(
        title: "从收藏夹中移除",
        desc: "从收藏夹中移除该条目",
        actionStyle: "alert",
        onClick: () {
          viewModel.removeStar(item: item);
        },
      ));
    } else {
      items.add(ItemClickProxy(
        title: "添加到收藏",
        onClick: () {
          viewModel.addToStaredItem(item);
        },
      ));
    }

    // 3. 回收站/还原
    final isItemDeleted = viewModel.isItemDeleted(item);
    if (isItemDeleted) {
      items.add(ItemClickProxy(
        title: "还原到文献库中",
        onClick: () {
          viewModel.restoreItem(context, item);
        },
      ));
    } else {
      items.add(ItemClickProxy(
        title: "移动到回收站",
        actionStyle: "alert",
        onClick: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            viewModel.moveItemToTrash(context, item);
          });
        },
      ));
    }

    // 4. 删除已下载的附件
    if (item.hasAttachments() || viewModel.isPdfAttachmentItem(item)) {
      items.add(ItemClickProxy(
        title: "删除已下载的附件",
        actionStyle: "alert",
        onClick: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            _showDeleteAttachmentsDialog(
              context: context,
              item: item,
              viewModel: viewModel,
            );
          });
        },
      ));
    }

    // 5. 更改所属集合
    if (!isItemDeleted) {
      items.add(ItemClickProxy(
        title: "更改所属集合",
        onClick: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            viewModel.showChangeCollectionSelector(context, item: item);
          });
        },
      ));
    }

    return items;
  }

  /// 显示删除附件确认对话框
  static void _showDeleteAttachmentsDialog({
    required BuildContext context,
    required Item item,
    required LibraryViewModel viewModel,
  }) {
    NeatDialogManager.showConfirmDialog(
      context,
      title: "删除下载的附件",
      confirm: "确定",
      cancel: "取消",
      message: "是否删除《${item.getTitle()}》中已下载的附件",
      onConfirm: (dialogContext) async {
        Navigator.of(dialogContext).pop();
        await viewModel.deleteAllDownloadedAttachmentsOfItems(
          dialogContext,
          item,
          onCallback: () {
            MyLogger.d('所有附件删除操作完成');
          },
        );
      },
      onCancel: (dialogContext) {
        Navigator.of(dialogContext).pop();
      },
    );
  }
} 