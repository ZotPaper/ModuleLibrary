import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bruno/bruno.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../LibZoteroStorage/entity/ItemTag.dart';

class TagsManagerPage extends StatefulWidget {
  const TagsManagerPage({super.key});

  @override
  State<TagsManagerPage> createState() => _ItemDetailTagFragmentState();
}

class _ItemDetailTagFragmentState extends State<TagsManagerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// 这个集合存储所有的标签，是包含重复的
  List<ItemTag> tags = [];

  /// 这个集合存储所有的标签，是去重复的
  Set<String> uniqueTags = LinkedHashSet();

  List<Item> items = [];

  ZoteroDB zoteroDB = ZoteroDB();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    /// 去除重复的标签
    zoteroDB.itemTags.forEach((tag) {
      tags.add(tag);
      uniqueTags.add(tag.tag);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrnAppBar(
        title: '标签管理',
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const Padding(
              //   padding: EdgeInsets.only(left: 12.0),
              //   child: Text('标签列表', style: TextStyle(fontSize: 16)),
              // ),
              _addTagButton(),
              const SizedBox(height: 10),
              // ...tags.map((tag) => _tagItem(tag)),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...uniqueTags.map((tag) => _tagItem(tag)),
                ],
              ),

            ],
          )),
    );
  }

  Widget _tagItem(String tag) {
    return BrnTagCustom(
      tagText: tag,
      fontSize: 14,
      backgroundColor: const Color(0xFFF1F2FA),
      textColor: const Color(0xFF4B5162),
      textPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    );
  }

  Widget _addTagButton() {
    return InkWell(
      onTap: () {

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

}
