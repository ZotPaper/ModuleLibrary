import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'ItemInfo.dart';
import 'ItemData.dart';
import 'Creator.dart';
import 'ItemTag.dart';
import 'ItemCollection.dart';
import 'Note.dart';

class Item {
  static const String ATTACHMENT_TYPE = "attachment";

  late ItemInfo itemInfo;
  late List<ItemData> itemData;
  late List<Creator> creators;
  late List<ItemTag> tags;
  // 这一条目所属于的Collection合集
  late List<String> collections;
  late List<Item> attachments;
  late List<Note> notes;

  Item({
    required this.itemInfo,
    required this.itemData,
    required this.creators,
    required this.tags,
    required this.collections,
    this.attachments = const [],
    this.notes = const [],
  });

  int getGroup() {
    return itemInfo.groupId;
  }

  List<Creator> getSortedCreators() {
    return creators..sort((a, b) => a.order.compareTo(b.order));
  }

  int getVersion() {
    return itemInfo.version;
  }

  String? getItemData(String key) {
    for (var data in itemData) {
      if (data.name == key) {
        return data.value;
      }
    }
    if (kDebugMode) {
      print("ItemData with key $key not found in Item.");
    }
    return null;
  }

  String get itemKey => itemInfo.itemKey;

  String get itemType => data['itemType'] ?? "error";

  Map<String, String> _mappedData = {};

  Map<String, String> get data {
    if (_mappedData.isEmpty) {
      for (var iData in itemData) {
        _mappedData[iData.name] = iData.value;
      }
    }
    return _mappedData;
  }

  String stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String getTitle() {
    String? title;
    switch (itemType) {
      case "case":
        title = data['caseName'];
        break;
      case "statute":
        title = data['nameOfAct'];
        break;
      case "note":
        var noteHtml = data['note'];
        title = stripHtml(noteHtml ?? "unknown");
        break;
      default:
        title = data['title'];
    }
    return title ?? "unknown";
  }

  String getAuthor() {
    switch (creators.length) {
      case 0:
        return "";
      case 1:
        return creators[0].lastName;
      default:
        return "${getSortedCreators()[0].lastName} et al.";
    }
  }

  String getSortableDateString() {
    var date = getItemData("date") ?? "";
    if (date.isEmpty) {
      return "ZZZZ";
    }
    return date;
  }

  bool query(String queryText) {
    var queryUpper = queryText.toUpperCase();
    return itemKey.toUpperCase().contains(queryUpper) ||
        tags.map((tag) => tag.tag).join("_").toUpperCase().contains(queryUpper) ||
        data.values.join("_").toUpperCase().contains(queryUpper) ||
        creators.map((creator) => creator.makeString().toUpperCase()).join("_").contains(queryUpper);
  }

  String getSortableDateAddedString() {
    return getItemData("dateAdded") ?? "XXXX-XX-XX";
  }

  String getMd5Key() {
    return getItemData("md5") ?? "";
  }

  List<String> getTagList() {
    return tags.map((tag) => tag.tag).toList();
  }

  bool hasParent() {
    return data.containsKey("parentItem");
  }

  int getMtime() {
    if (data.containsKey("mtime")) {
      return int.tryParse(data["mtime"]!) ?? 0;
    }
    if (kDebugMode) {
      print("no mtime available for $itemKey");
    }
    return 0;
  }

  bool isDownloadable() {
    if (itemType != "attachment") {
      return false;
    }
    if (data.containsKey("contentType")) {
      return getFileExtension() != "UNKNOWN";
    }
    return false;
  }

  String getFileExtension() {
    String? extension;
    switch (data["contentType"]) {
      case "application/pdf":
        extension = "pdf";
        break;
      case "image/vnd.djvu":
        extension = "djvu";
        break;
      case "application/epub+zip":
        extension = "epub";
        break;
      case "application/x-mobipocket-ebook":
        extension = "mobi";
        break;
      case "application/vnd.amazon.ebook":
        extension = "azw";
        break;
      default:
        extension = "UNKNOWN";
    }

    if (extension == "UNKNOWN") {
      var filename = data.containsKey("filename") ? data["filename"] : data["title"];
      return filename?.split(".").last ?? "UNKNOWN";
    }
    return extension;
  }

  String getContentType() {
    return data["contentType"] ?? "UNKNOWN";
  }

  bool hasAttachments() {
    return attachments.isNotEmpty;
  }

  bool isNoteItem() {
    return itemType == "note";
  }

  bool isWebPageItem() {
    return itemType == "attachment" && data['contentType'] == "text/html";
  }
  String getParentItemKey() {
    return data["parentItem"] ?? "";
  }
}
