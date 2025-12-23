import 'package:flutter/material.dart';
import 'package:module_base/stores/hive_stores.dart';
import 'package:module_base/view/expand_tile.dart';
import 'package:module_base/view/store_switch.dart';
import 'package:module_library/ModuleLibrary/dialog/sorting_direction_icon.dart';

import '../store/library_settings.dart';
import '../viewmodels/library_viewmodel.dart';
import '../res/ResColor.dart';
import 'package:provider/provider.dart';


class LibraryLayoutDialog extends StatefulWidget {
  const LibraryLayoutDialog({super.key});

  @override
  State<LibraryLayoutDialog> createState() => _LibraryLayoutDialogState();
}

class _LibraryLayoutDialogState extends State<LibraryLayoutDialog> {
  // 选中的视图模式索引
  int? _selectedViewIndex;

  // 选中的排序模式索引
  int? _selectedSortIndex;

  bool _isReverse = false;

  late LibraryViewModel _viewModel;

  // 视图模式选项
  final List<Map<String, dynamic>> _viewOptions = [
    {"text": "图标(大)", "icon": Icons.grid_view},
    {"text": "图标(中)", "icon": Icons.grid_on},
    {"text": "图标(小)", "icon": Icons.apps},
    {"text": "列表(大)", "icon": Icons.list},
    {"text": "列表(中)", "icon": Icons.reorder},
    {"text": "列表(小)", "icon": Icons.view_list},
    {"text": "详情(大)", "icon": Icons.format_list_bulleted},
    {"text": "详情(中)", "icon": Icons.view_headline},
    {"text": "详情(小)", "icon": Icons.menu},
  ];

  // 排序选项
  final List<String> _sortOptions = ["标题", "作者", "日期", "添加日期"];

  final LibraryStore _setStore = Stores.get(Stores.KEY_LIBRARY) as LibraryStore;

  static const double _maxDialogWidth = 480.0;

  @override
  void initState() {
    super.initState();

    // 在这里通过 Provider 获取 ViewModel
    _viewModel = Provider.of<LibraryViewModel>(context, listen: false);

    setState(() {

      var store_sort_method = "TITLE";
      if (_setStore != null && _setStore is LibraryStore) {
        _isReverse = _setStore.sortDirection.get() != "ASCENDING";
        store_sort_method = _setStore.sortMethod.get();
      }


      switch (store_sort_method) {
        case "AUTHOR":
          _selectedSortIndex = 1;
          break;
        case "DATE":
          _selectedSortIndex = 2;
          break;
        case "DATE_ADDED":
          _selectedSortIndex = 3;
          break;
        case "TITLE":
        default:
          _selectedSortIndex = 0;
      }
    });
  }

  _setLibrarySort(int index, bool revere) {
    _setStore.sortDirection.set(revere ? "DESCENDING" : "ASCENDING");

    if (index == 0) {
      _setStore.sortMethod.set("TITLE");
    } else if (index == 1) {
      _setStore.sortMethod.set("AUTHOR");
    } else if (index == 2) {
      _setStore.sortMethod.set("DATE");
    } else if (index == 3) {
      _setStore.sortMethod.set("DATE_ADDED");
    } else {
      _setStore.sortMethod.set("TITLE");
    }
    
    // 通知ViewModel刷新数据以应用新的排序设置
    _viewModel.refreshInCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildDialogHeader(),
            
            // 内容区域
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  _buildSortSection(),
                  const SizedBox(height: 12),
                  _buildFilterSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: ResColor.selectedBgColor.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: ResColor.selectedTextColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '排序与筛选',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ResColor.textMain,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: ResColor.textMain.withOpacity(0.6),
              size: 20,
            ),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.sort,
              color: ResColor.selectedTextColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '排序方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ResColor.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical:8, horizontal: 8),
          decoration: BoxDecoration(
            color: ResColor.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ResColor.divideColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_sortOptions.length, (index) {
              return Expanded(
                child: _buildSortOption(index),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_alt,
              color: ResColor.selectedTextColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '筛选条件',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ResColor.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ResColor.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ResColor.divideColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildFilterOption(
                icon: Icons.picture_as_pdf_outlined,
                title: "含PDF附件",
                store: _setStore.showOnlyWithPdfs,
                onChanged: (val) => _viewModel.filterItemsOnlyWithPdfs(val),
              ),
              Container(
                height: 1,
                color: ResColor.divideColor.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildFilterOption(
                icon: Icons.note_alt_outlined,
                title: "含笔记",
                store: _setStore.showOnlyWithNotes,
                onChanged: (val) => _viewModel.filterItemsOnlyWithNotes(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String title,
    required dynamic store,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ResColor.selectedBgColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: ResColor.selectedTextColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: ResColor.textMain,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          StoreSwitch(
            prop: store,
            callback: (val) async {
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  /// 构建视图模式选项
  Widget _buildViewOption(int index) {
    bool isSelected = _selectedViewIndex == index;
    return InkWell(
        onTap: () {
          setState(() {
            _selectedViewIndex = (_selectedViewIndex == index) ? null : index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Center(
            child: Column(
          children: [
            Icon(_viewOptions[index]["icon"],
                size: 30, color: isSelected ? ResColor.selectedTextColor : ResColor.textMain.withOpacity(0.6)),
            const SizedBox(height: 4),
            Text(
              _viewOptions[index]["text"],
              style: TextStyle(
                  fontSize: 12, color: isSelected ? ResColor.selectedTextColor : ResColor.textMain.withOpacity(0.8)),
            ),
          ],
        )));
  }

  /// 构建排序选项
  Widget _buildSortOption(int index) {
    bool isSelected = _selectedSortIndex == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _sortOptions[index],
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? ResColor.selectedTextColor : ResColor.textMain.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 升序按钮
            InkWell(
              onTap: () {
                _setLibrarySort(index, false);
                setState(() {
                  _selectedSortIndex = index;
                  _isReverse = false;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: SortingDirectionIcon(
                  checked: (isSelected && !_isReverse), 
                  reverse: false,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // 降序按钮
            InkWell(
              onTap: () {
                setState(() {
                  _selectedSortIndex = index;
                  _isReverse = true;
                });
                _setLibrarySort(index, true);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: SortingDirectionIcon(
                  checked: (isSelected && _isReverse), 
                  reverse: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherOptions() {
    return ExpandTile(
      leading: const Icon(Icons.filter_alt_outlined),
      title: Text("筛选"),
      children: [
        _buildShowItemWithPDF(),
        _buildShowItemWithNote(),
      ],
    );
  }

  Widget _buildShowItemWithPDF() {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: const Text("含PDF附件"),
      trailing: StoreSwitch(
        prop: _setStore.showOnlyWithPdfs,
        callback: (val) async {
          // 设置文库列表是否筛选只含PDF附件的Item（Colletion不进行筛选）
          _viewModel.filterItemsOnlyWithPdfs(val);
        },
      ),
    );
  }

  Widget _buildShowItemWithNote() {
    return ListTile(
      leading: const Icon(Icons.note_alt_outlined),
      title: const Text("含笔记"),
      trailing: StoreSwitch(
        prop: _setStore.showOnlyWithNotes,
        callback: (val) async {
          // 设置文库列表是否筛选只含笔记的Item（Colletion不进行筛选）
          _viewModel.filterItemsOnlyWithNotes(val);
        },
      ),
    );
  }

}