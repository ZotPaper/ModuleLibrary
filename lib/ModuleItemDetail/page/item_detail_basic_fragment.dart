import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bruno/bruno.dart';
import '../../LibZoteroStorage/entity/Item.dart';

class ItemDetailBasicFragment extends StatefulWidget {
  final Item item;
  const ItemDetailBasicFragment(this.item, {super.key});

  @override
  State<ItemDetailBasicFragment> createState() => _ItemDetailBasicFragmentState();
}

class _ItemDetailBasicFragmentState extends State<ItemDetailBasicFragment> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: widget.item.itemType == 'journalArticle' ? _contentJournal() : _normalInfo(),

    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 80, child: Text(label, style: TextStyle(fontWeight: FontWeight.w400))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget widgetAuthors() {
    return Row(children: [
      Text(widget.item.getAuthor()),
      // Text('2020-05-01', style: TextStyle(color: Colors.grey)),
    ],);
  }

  /// 期刊的显示样式
  Widget _contentJournal() {
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/journal_cover.jpg',
              width: 80,
              height: 120,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.getTitle(),
                    maxLines: 3,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  widgetAuthors(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.item.getItemData('journalAbbreviation') ?? "",
          style: TextStyle(fontSize:14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 12),
        const Text('摘要', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        BrnExpandableText(
          maxLines: 8,
          text: widget.item.getItemData('abstractNote') ?? "",
        ),
        const SizedBox(height: 20),
        const Text('期刊信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        infoRow('卷号', widget.item.getItemData('volume') ?? ""),
        infoRow('期号', widget.item.getItemData('issue') ?? ""),
        infoRow('页码', widget.item.getItemData('pages') ?? ""),
        infoRow('语言', widget.item.getItemData('language') ?? ""),
        infoRow('ISSN', widget.item.getItemData('ISBN') ?? ""),
        infoRow('DOI', widget.item.getItemData('DOI') ?? ""),
        infoRow('URL', widget.item.getItemData('url') ?? ""),
        const SizedBox(height: 20),
        const Text('额外信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        infoRow('修改时间', widget.item.getItemData('dateModified') ?? ""),
        infoRow('添加日期', widget.item.getItemData('dateAdded') ?? ""),
      ],
    );
  }

  Widget _normalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        infoRow('作者', widget.item.getAuthor()),
        infoRow('日期', widget.item.getMtime().toString()),
        infoRow('语言', widget.item.getItemData('language') ?? ""),
        infoRow('添加日期', widget.item.getItemData('dateAdded') ?? ""),
        infoRow('ISBN', widget.item.getItemData('ISBN') ?? ""),
        infoRow('访问日期', widget.item.getItemData('accessDate') ?? ""),
        infoRow('DOI', widget.item.getItemData('DOI') ?? ""),
        infoRow('key', widget.item.itemKey),
        infoRow('贡献目录', 'DOI.org (Crossref)'),
        infoRow('修改日期', widget.item.getItemData('dateModified') ?? ""),
        infoRow(
          'url',
          widget.item.getItemData('url') ?? "",
        ),
        infoRow('出版社', widget.item.getItemData('publisher') ?? ""),
        infoRow('图书标题', 'Drug Discovery'),
      ],
    );
  }
}
