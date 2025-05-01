import 'dart:convert';
import 'dart:math';

class Note {
  late String parent;
  late String key;
  late String note;
  int version = -1;
  late List<String> tags;

  Note({
    required this.parent,
    required this.key,
    required this.note,
    this.version = -1,
    List<String>? tags,
  }) : tags = tags ?? [];

  Note.fromItemPOJO(ItemPOJO item) {
    parent = item.data["parentItem"] ?? "";
    key = item.data["key"] ?? (throw Exception("No Key"));
    note = item.data["note"] ?? (throw Exception("No note"));
    version = item.version;
    tags = item.tags;
  }

  Note.withValues(String note, String parent, {String noteKey = "", int version = -1}) {
    this.parent = parent;
    this.key = noteKey;
    this.note = note;
    this.version = version;
    this.tags = [];
  }

  Map<String, dynamic> getJsonNotePatch() {
    return {
      "note": note,
    };
  }

  Map<String, dynamic> asJsonObject() {
    return {
      "itemType": "note",
      "note": note,
      "parentItem": parent,
      "tags": [],
      "collections": [],
      "relations": [],
    };
  }

  List<Map<String, dynamic>> asJsonArray() {
    return [asJsonObject()];
  }

  static Note create(String note, String parent) {
    var newNote = Note.withValues(note, parent);
    newNote.key = generateRandomCode(8);
    return newNote;
  }

  static String generateRandomCode(int length) {
    const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    var random = Random();
    return List.generate(length, (index) => charset[random.nextInt(charset.length)]).join();
  }
}

class ItemPOJO {
  final Map<String, String> data;
  final int version;
  final List<String> tags;

  ItemPOJO({
    required this.data,
    required this.version,
    required this.tags,
  });
}