import 'package:flutter/cupertino.dart';
import 'package:module_base/utils/tracking/dot_tracker.dart';

import '../LibZoteroStorage/entity/Item.dart';
import '../LibZoteroStorage/entity/Note.dart';
import '../routers.dart';

class NoteEditManager {
  static NoteEditManager? _instance;
  static NoteEditManager get instance => _instance ??= NoteEditManager();
  NoteEditManager._();
  NoteEditManager();

  /// 编辑笔记
  void editNote(BuildContext context, Note note) {
    // 埋点上报
    DotTracker
        .addDot("VIEW_NOTE", description: "查看笔记")
        .addParam("itemKey", note.key)
        .report();

    MyRouter.instance.pushNamed(context, MyRouter.PAGE_NOTE_EDIT, arguments: {
      "note": note,
    });
  }

  void editNoteItem(BuildContext context, Item noteItem) {
    noteItem.isNoteItem();
    Note note = Note.create(noteItem.data['note'] ?? "", noteItem.getParentItemKey());
    editNote(context, note);
  }

}