import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bruno/bruno.dart';
import 'package:module/LibZoteroStorage/entity/ItemTag.dart';
import 'package:module/ModuleLibrary/viewmodels/zotero_database.dart';
import '../../LibZoteroStorage/entity/Item.dart';

class TagsManagerPage extends StatefulWidget {
  const TagsManagerPage({super.key});

  @override
  State<TagsManagerPage> createState() => _ItemDetailTagFragmentState();
}

class _ItemDetailTagFragmentState extends State<TagsManagerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<ItemTag> tags = [];

  ZoteroDB zoteroDB = ZoteroDB();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // zoteroDB..forEach((tag) {
    //   tags.add(tag.tag);
    // });

    zoteroDB.itemTags.forEach((tag) {
      tags.add(tag);
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
                  ...tags.map((tag) => _tagItem(tag)),
                ],
              ),

            ],
          )),
    );
  }

  Widget _tagItem(ItemTag item) {
    return BrnTagCustom(
      tagText: item.tag,
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
