import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:module_library/ModuleLibrary/utils/color_utils.dart';

import '../../../LibZoteroApi/Model/ZoteroSettingsResponse.dart';

class TagSelectorPage extends StatefulWidget {
  final List<TagColor> tags;
  final Set<String> selectedTags;

  const TagSelectorPage({
    super.key,
    required this.tags,
    this.selectedTags = const {},
  });

  @override
  State<TagSelectorPage> createState() => _TagSelectorPageState();
}

class _TagSelectorPageState extends State<TagSelectorPage> {
  late Set<String> _selected;
  late List<TagColor> _filtered;

  BrnSearchTextController searchController = BrnSearchTextController();
  TextEditingController textController = TextEditingController();

  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedTags};
    _filtered = widget.tags;
  }

  void _onTagTap(TagColor tag) {
    setState(() {
      if (_selected.contains(tag.name)) {
        _selected.remove(tag.name);
      } else {
        _selected.add(tag.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrnAppBar(
        //默认显示返回按钮
        automaticallyImplyLeading: true,
        title: Text('选中${_selected.length}条'),
        //自定义的右侧文本
        actions: BrnTextAction(
          '确定',
          //设置为深色背景，则显示白色
          themeData: BrnAppBarConfig.dark(),
          iconPressed: () {
            Navigator.pop(context, _selected);
          },
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // 移除焦点
          FocusScope.of(context).unfocus();
          focusNode.unfocus();
        },
        behavior: HitTestBehavior.opaque, //
        child: Column(
          children: [
            _widgetSearchBar(),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, index) {
                  final tag = _filtered[index];
                  final isSelected = _selected.contains(tag.name);
                  return ListTile(
                    onTap: () => _onTagTap(tag),
                    leading: CircleAvatar(
                      backgroundColor: ColorUtils.hexToColor(tag.color),
                      radius: 8,
                    ),
                    title: Text(tag.name),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : const Icon(Icons.radio_button_unchecked),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _widgetSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: BrnSearchText(
        hintText: "搜索标签",
        focusNode: focusNode,
        controller: textController,
        onTextClear: () {
          return false;
        },
        autoFocus: false,
        onActionTap: () {
          focusNode.unfocus();
        },
        onTextChange: (text) {
              setState(() {
                _filtered = widget.tags
                    .where((tag) =>
                    tag.name.toLowerCase().contains(text.toLowerCase()))
                    .toList();
              });
        },
      ),
    );
  }
}
