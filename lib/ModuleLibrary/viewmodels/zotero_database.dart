
import 'package:flutter/cupertino.dart';

import '../../LibZoteroStorage/entity/Collection.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../LibZoteroStorage/entity/Note.dart';

/// 这是存放从本地数据库加载到内存的数据存放类（全局单例类）
///
class ZoteroDB {
  // todo 单例模式
  static final ZoteroDB _instance = ZoteroDB._internal();
  factory ZoteroDB() => _instance;
  ZoteroDB._internal();

  // 所有的条目数据
  final List<Item> _items = [];
  // 所有的条目数据
  List<Item> get items => _items;

  // 所有的合集数据
  final List<Collection> _collections = [];
  // 所有的合集数据
  List<Collection> get collections => _collections;

  Map<String, List<Item>>? itemsFromCollections;

  // 我的出版物
  final List<Item> myPublications  = [];

  // 附件数据
  final Map<String, List<Item>> _attcahmentItems = {};

  // 笔记数据
  final Map<String, List<Item>> notes = {};

  // 判断是否已经加载了数据
  bool isPopulated() {
    return !(_collections == null || _items == null);
  }

  // 设置条目数据
  void setItems(List<Item> items) {
    _items.clear();
    _items.addAll(items);
    // Associate items with attachments and notes
    _associateItemsWithAttachments();
    // 创建集合项映射
    _createCollectionItemMap();
    // 处理条目数据
    _processItems();
  }

  void setCollections(List<Collection> collections) {
    _collections.clear();
    _collections.addAll(collections);

    /// 建立集合之间的父子关系
    _populateCollectionChildren();
    /// 建立集合项映射
    _createCollectionItemMap();

  }

  /// 将条目数据与附件和笔记关联起来
  void _associateItemsWithAttachments() {
    Map<String, Item> itemsByKey = {};

    // Initialize items and clear attachments/notes
    for (var item in items) {
      itemsByKey[item.itemKey] = item;

      // To avoid repeatedly adding notes and attachments during updates, nullify them
      item.attachments = [];
      item.notes = [];
    }

    for (var item in items) {
      if (item.isDownloadable()) {
        var parentKey = item.data['parentItem'];
        if (parentKey != null) {
          itemsByKey[parentKey]?.attachments?.add(item);
        }
      }

      if (item.itemType == 'note') {
        try {
          var note = Note(
            parent: item.data['parentItem'] ?? '',
            key: item.data['key'] ?? '',
            note: item.data['note'] ?? '',
            version: item.getVersion(),
          );

          // Ensure that the parent exists in the map and add the note
          if (itemsByKey.containsKey(note.parent)) {
            itemsByKey[note.parent]?.notes?.add(note);
          }
        } catch (e) {
          debugPrint('Error loading note ${item.itemKey} error: ${e.toString()}');
        }
      }
    }
  }

  void _populateCollectionChildren() {
    // Check if collections is null
    if (collections == null) {
      throw Exception("called populate collections with no collections!");
    }

    // Iterate through each collection in the list
    for (var collection in collections) {
      if (collection.hasParent()) {
        // Find the parent collection and add the sub-collection
        var parentCollection = collections?.firstWhere(
              (col) => col.key == collection.parentCollection
        );

        parentCollection?.addSubCollection(collection);
      }
    }
  }

  /// Create a map of collections and their sub-collections
  void _createCollectionItemMap() {
    // Check if items are populated
    if (!isPopulated()) {
      return;
    }

    // Initialize the map to store collections
    itemsFromCollections = {};  // Using Map<String, List<Item>> for storing collections

    for (var item in items) {
      for (var collection in item.collections) {
        // If the collection doesn't already exist in the map, create a new list
        if (!itemsFromCollections!.containsKey(collection)) {
          itemsFromCollections![collection] = [];
        }
        // Add the item to the corresponding collection
        itemsFromCollections![collection]?.add(item);
      }
    }
  }

  /// Processes the items and creates a map of collections and their items
  void _processItems() {
    // Check if items are populated
    if (!isPopulated()) {
      return;
    }

    for (var item in items) {
      if (item.data.containsKey("inPublications") && item.data["inPublications"] == "true") {
        myPublications.add(item);
      }
    }
  }



  // 添加条目数据
  void addItem(Item item) {
    _items.add(item);
  }

  // 添加合集数据
 void addCollection(Collection collection) {}
  // todo 条目以及item变化的事件监听

  List<Item> getDisplayableItems() {
    if (items != null) {
      var filtered = items.where((it) { return !it.hasParent();});
      return filtered.toList();
    } else {
      // Log.e("zotero", "error. got request for getDisplayableItems() before items has loaded.")
      return [];
    }
  }

  List<Item> getItemsFromCollection(String collection) {
    // If itemsFromCollections is null, create the collection-item map
    if (itemsFromCollections == null) {
      _createCollectionItemMap();
    }

    // Return the list of items from the collection, or an empty list if not found
    return itemsFromCollections?[collection] ?? [];
  }


}