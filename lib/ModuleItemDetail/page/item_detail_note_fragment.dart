import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_base/view/toast/neat_toast.dart';
import 'package:module_library/LibZoteroStorage/entity/Note.dart';
import 'package:module_library/ModuleItemDetail/common_epmty_view.dart';

import '../../LibZoteroStorage/entity/Item.dart';

class ItemDetailNoteFragment extends StatefulWidget {
  final Item item;
  const ItemDetailNoteFragment(this.item, {super.key});

  @override
  State<ItemDetailNoteFragment> createState() => _ItemDetailNoteFragmentState();
}

class _ItemDetailNoteFragmentState extends State<ItemDetailNoteFragment> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    widget.item.notes.forEach((note) {
      notes.add(note);
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
              child: Text('笔记列表', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 4),
            if (notes.isNotEmpty) ...notes.map((note) => _attachmentItem(note)) else CommonEmptyView(text: "该条目记录下无笔记",)
            // _addAttachmentButton(),
          ],
        ));
  }

  Widget _attachmentItem(Note note) {
    return Card(
      color: Colors.grey[100],
      elevation: 0,
      child: InkWell(
        onTap: () {
          context.toastNormal("查看笔记，功能待开发！！！");
        },
        child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(note.note, overflow: TextOverflow.ellipsis,)),
              ],
            )
        ),
      ),
    );
  }

  Widget _addAttachmentButton() {
    return InkWell(
      onTap: () {
        context.toastNormal("添加标签，功能待开发！！！");
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              "添加笔记",
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

}
