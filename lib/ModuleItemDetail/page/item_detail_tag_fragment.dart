import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_base/view/toast/neat_toast.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemTag.dart';
import 'package:module_library/ModuleLibrary/page/tags_selector_page/tags_selector_page.dart';
import 'package:module_library/ModuleSync/zotero_sync_manager.dart';
import 'package:module_library/ModuleTagManager/item_tagmanager.dart';

import '../../LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../ModuleLibrary/utils/color_utils.dart';
import '../../ModuleLibrary/utils/my_logger.dart';

class ItemDetailTagFragment extends StatefulWidget {
  final Item item;
  const ItemDetailTagFragment(this.item, {super.key});

  @override
  State<ItemDetailTagFragment> createState() => _ItemDetailTagFragmentState();
}

class _ItemDetailTagFragmentState extends State<ItemDetailTagFragment> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<String> tags = [];

  List<TagColor> showedTags = [];

  TagManager tagManger = TagManager();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    widget.item.tags.forEach((tag) {
      tags.add(tag.tag);
    });

    tagManger.getStyledTags().then((res) {
      _updateShowingTags(res, tags);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text('标签列表', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 4),
          ...showedTags.map((tag) => _tagItem(tag)),
          _addTagButton(),
        ],
    ));
  }

  Widget _tagItem(TagColor tag) {
    return Card(
      color: Colors.grey[100],
      elevation: 0,
      child: InkWell(
        onTap: () {
          context.toastNormal("功能待开发！！！");
        },
        child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            alignment: Alignment.centerLeft,
            child: Text(tag.name, style: TextStyle(color: ColorUtils.hexToColor(tag.color)))
        ),
      ),
    );
  }

  Widget _addTagButton() {
    return InkWell(
      onTap: () {
        _navigateToAddTag();
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              "添加标签",
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _updateShowingTags(List<TagColor> styledTags, List<String> uniqueTags) {
    // MyLogger.d("Moyear==== 样式标签：$styledTags");

    List<TagColor> res = [];

    styledTags.forEach((tag) {
      if (uniqueTags.contains(tag.name)) {
        res.add(tag);
      }
    });

    uniqueTags.forEach((tag) {
      if (!res.any((element) => element.name == tag)) {
        res.add(TagColor(name: tag, color: '#4B5162'));
      }
    });

    setState(() {
      showedTags.addAll(res);
    });
  }

  Future<void> _navigateToAddTag() async {
    // var importantTags = await tagManger.getStyledTags();

    context.toastNormal("添加标签，功能待开发！！！");

    Set<TagColor> styledTags = LinkedHashSet();
    Set<TagColor> unStyledTags = LinkedHashSet();

    // 获取所有标签
    for (var itemTag in ZoteroSyncManager.instance.zoteroDB.itemTags) {
      var tag = await tagManger.foundInImportantTag(itemTag.tag);
      if (tag != null) {
        styledTags.add(tag);
      } else {
        unStyledTags.add(TagColor(name: itemTag.tag, color: ''));
      }
    }

    List<TagColor> allTags = [];
    allTags.addAll(styledTags);
    allTags.addAll(unStyledTags);

    // 获取当前选中的标签

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TagSelectorPage(
            tags: allTags,
        ),
      ),
    );
  }

}
