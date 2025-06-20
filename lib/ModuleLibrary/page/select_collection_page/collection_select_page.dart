import 'dart:collection';

import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';

import '../../../LibZoteroStorage/entity/Collection.dart';

class CollectionSelector extends StatefulWidget {

  List<String> initialSelected = [];
  final bool isMultiSelect;

  CollectionSelector({
    List<String>? parentCollections,
    this.isMultiSelect = true,
  }): initialSelected = parentCollections ?? [];

  @override
  _CollectionSelectorState createState() => _CollectionSelectorState();
}

class _CollectionSelectorState extends State<CollectionSelector> {

  final List<CollectionSelection> collections = [];
  final ZoteroDB zoteroDB = ZoteroDB();

  final HashSet<String> selectedCollections = HashSet();

  @override
  void initState() {
    super.initState();

    for (var collectionKey in widget.initialSelected) {
      selectedCollections.add(collectionKey);
    }

    print("是否支持多选: ${widget.isMultiSelect} , 默认选中的：${widget.initialSelected}");

    List<CollectionSelection> res = [];
    // 递归遍历整个集合，映射父子关系

    // todo 处理单选和多选的情况

    var topCollections = zoteroDB.collections.where((it) {
      return !it.hasParent();
    }).toList();
    recurseCollection(res, topCollections);

    setState(() {
      collections.addAll(res);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrnAppBar(
        //默认显示返回按钮
        automaticallyImplyLeading: true,
        title: '集合选择',
        //自定义的右侧文本
        actions: BrnTextAction(
          '确定',
          //设置为深色背景，则显示白色
          themeData: BrnAppBarConfig.dark(),
          iconPressed: () {
            Navigator.pop(context, selectedCollections.toList());
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: ListView(
          children: _buildCollectionList(collections, 0),
        ),
      ),
    );
  }

  List<Widget> _buildCollectionList(List<CollectionSelection> collections, int depth) {
    List<Widget> widgets = [];

    for (var collection in collections) {
      widgets.add(_buildCollectionItem(collection, depth));

      if (collection.children.isNotEmpty) {
        widgets.addAll(_buildCollectionList(collection.children, depth + 1));
      }
    }

    return widgets;
  }

  Widget _buildCollectionItem(CollectionSelection collection, int depth) {
    return Container(
      color: collection.isSelected ? Colors.grey.shade300 : null,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.only(left: (16 * depth).toDouble()),
          child: const Icon(Icons.folder_outlined),
        ),
        title: Row(
          children: [
            const SizedBox(width: 16.0),
            Expanded(child: Text(collection.collection.name)),
          ],
        ),
        trailing: BrnCheckbox(
          radioIndex: 0,
          isSelected: collection.isSelected,
          childOnRight: false,
          onValueChangedAtIndex: (index, value) {
            setState(() {
              changeCollectionChecked(collection, value);
            });
          },
        ),
        onTap: () {
          setState(() {
            changeCollectionChecked(collection, !collection.isSelected);
            // collection.isExpanded = !collection.isExpanded;
          });
        },
      ),
    );
  }

  void recurseCollection(List<CollectionSelection> res, List<Collection>? value) {
    if (value == null || value.isEmpty) {
      return;
    }

    for (var child in value) {
      var sub = CollectionSelection(collection: child);

      // 默认选中的逻辑
      if (selectedCollections.contains(child.key)) {
        sub.isSelected = true;
      }

      recurseCollection(sub.children, child.subCollections);
      res.add(sub);
    }
  }

  void changeCollectionChecked(CollectionSelection collection, bool checked) {
    if (widget.isMultiSelect) {
      collection.isSelected = checked;
      if (checked) {
        if (!selectedCollections.contains(collection.collection.key)) {
          selectedCollections.add(collection.collection.key);
        }
      } else {
        selectedCollections.remove(collection.collection.key);
      }
    } else {
      uncheckAllCollections(collections);
      collection.isSelected = checked;

      selectedCollections.clear();
      selectedCollections.add(collection.collection.key);
    }
  }

  void uncheckAllCollections(List<CollectionSelection>? collections) {
    if (collections == null || collections.isEmpty) return;

    for (var it in collections) {
      it.isSelected = false;
      uncheckAllCollections(it.children);
    }

  }
}

class CollectionSelection {
  final Collection collection;
  bool isSelected;
  bool isExpanded;
  final List<CollectionSelection> children;

  CollectionSelection({
    required this.collection,
    this.isSelected = false,
    this.isExpanded = false,
    List<CollectionSelection>? children,
  }) : children = children ?? [];

  void setSelected(bool value) {
    isSelected = value;
  }

  void setExpanded(bool value) {
    isExpanded = value;
  }

}