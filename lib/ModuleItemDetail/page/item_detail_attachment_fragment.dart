import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../LibZoteroStorage/entity/Item.dart';

class ItemDetailAttachmentFragment extends StatefulWidget {
  final Item item;
  const ItemDetailAttachmentFragment(this.item, {super.key});

  @override
  State<ItemDetailAttachmentFragment> createState() => _ItemDetailAttachmentFragmentState();
}

class _ItemDetailAttachmentFragmentState extends State<ItemDetailAttachmentFragment> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<Item> attachments = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    widget.item.attachments.forEach((attachment) {
      attachments.add(attachment);
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
              child: Text('附件列表', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 4),
            ...attachments.map((attachment) => _attachmentItem(attachment)),
            _addAttachmentButton(),
          ],
        ));
  }

  Widget _attachmentItem(Item attachment) {
    return Card(
      color: Colors.grey[100],
      elevation: 0,
      child: InkWell(
        onTap: () {},
        child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(attachment.getTitle(), overflow: TextOverflow.ellipsis,)),
              ],
            )
        ),
      ),
    );
  }

  Widget _addAttachmentButton() {
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
              "添加附件",
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

}
