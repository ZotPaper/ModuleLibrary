import 'package:flutter/material.dart';
import 'package:module_base/stores/hive_stores.dart';
import 'package:module_base/view/expand_tile.dart';
import 'package:module_base/view/store_switch.dart';
import 'package:module_library/ModuleLibrary/dialog/sorting_direction_icon.dart';

import '../store/library_settings.dart';
import '../viewmodels/library_viewmodel.dart';
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

  Color defaultColor = Colors.grey;

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

  static const double _maxDialogWidth = 600.0;

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
    // setState(() {
    //   _selectedViewIndex = index;
    //   _isReverse = revere;
    // });

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
    defaultColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const Text(
              //   "视图",
              //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              // ),
              // const SizedBox(height: 12),
              // GridView.builder(
              //   shrinkWrap: true,
              //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //     crossAxisCount: 3, // 每行显示3个子项
              //     crossAxisSpacing: 8, // 水平间距
              //     mainAxisSpacing: 8, // 垂直间距
              //   ),
              //   itemCount: _viewOptions.length,
              //   physics: const NeverScrollableScrollPhysics(),
              //   itemBuilder: (context, index) {
              //     return _buildViewOption(index);
              //   },
              // ),
              // const SizedBox(height: 16),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  "排序",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_sortOptions.length, (index) {
                  return _buildSortOption(index);
                }),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  "其他",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              _buildOtherOptions(),
              // Align(
              //   alignment: Alignment.bottomRight,
              //   child: TextButton(
              //     onPressed: () => Navigator.pop(context),
              //     child: const Text("关闭"),
              //   ),
              // )
            ],
          ),
        ),
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
                size: 30, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text(
              _viewOptions[index]["text"],
              style: TextStyle(
                  fontSize: 12, color: isSelected ? Colors.blue : defaultColor),
            ),
          ],
        )));
  }

  /// 构建排序选项
  Widget _buildSortOption(int index) {
    bool isSelected = _selectedSortIndex == index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _sortOptions[index],
          style: TextStyle(
              fontSize: 14, color: isSelected ? Colors.blue : defaultColor),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            _setLibrarySort(index, false);
            setState(() {
              _selectedSortIndex = index;
              _isReverse = false;
            });
          },
          child: SortingDirectionIcon(checked: (isSelected && !_isReverse), reverse: false)
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            setState(() {
              _selectedSortIndex = index;
              _isReverse = true;
            });
            _setLibrarySort(index, true);
          },
          child: SortingDirectionIcon(checked: (isSelected && _isReverse), reverse: true)
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