import 'dart:async';

import 'package:flutter/material.dart';
import '../../LibZoteroStorage/entity/Collection.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../LibZoteroStorage/entity/ItemData.dart';
import '../../LibZoteroStorage/entity/ItemInfo.dart';
import '../api/ZoteroDataHttp.dart';
import '../api/ZoteroDataSql.dart';
import '../share_pref.dart';
import '../page/LibraryUI/drawer.dart';

class LibraryViewModel with ChangeNotifier {
  final String _userId = "16082509";
  final String _apiKey = "KsmSAwR7P4fXjh6QNjRETcqy";

  late final ZoteroDataHttp zoteroData;

  final ZoteroDataSql zoteroDataSql = ZoteroDataSql();

  List<Item> _items = [];
  final List<Collection> _collections = [];
  late final List<Item> _showItems = [];

  LibraryViewModel() : super() {
    zoteroData = ZoteroDataHttp(apiKey: _apiKey);
  }

  final StreamController<List<Item>> _showItemsController = StreamController<List<Item>>.broadcast();
  Stream<List<Item>> get showItemsStream => _showItemsController.stream;

  List<Item> get items => _items;
  List<Collection> get collections => _collections;
  List<Item> get showItems => _showItems;

  void init() async {
    await SharedPref.init();
    bool isFirstStart = SharedPref.getBool(PrefString.isFirst, true);

    if (isFirstStart) {
      debugPrint("=============isFirstStart");
      // 初次启动，从网络获取数据并保存到数据库
      await _performCompleteSync();
    } else {
      // 从数据库加载数据
      await _loadDataFromLocalDatabase();
    }

    /// 通知更新列表
    _notifyShowItems();
  }

  /// 处理抽屉按钮点击事件
  void handleDrawerItemTap(DrawerBtn drawerBtn) {
    switch (drawerBtn) {
      case DrawerBtn.home:
        _resetShowItems();
        for (var collection in _collections) {
          _showItems.add(Item(
            itemInfo: ItemInfo(id: 0, itemKey: collection.key, groupId: collection.groupId,
              version: collection.version, deleted: false),
            itemData: [ItemData(id: 0, parent: collection.key, name: 'title', value: collection.name, valueType: "String")],
            creators: [],
            tags: [],
            collections: [],
          ));
        }
        _showItems.addAll(_items);
        break;
      case DrawerBtn.favourites:
        // TODO: Handle this case.
      case DrawerBtn.library:
        _resetShowItems();
        _showItems.addAll(_items);
        break;
      case DrawerBtn.unfiled:
        _resetShowItems();
        final tempItems = _items.where((item) => item.collections.isEmpty).toList();
        _showItems.addAll(tempItems);
        break;
      case DrawerBtn.publications:
        _resetShowItems();
        final tempItems = _items.where((item) {
          return item.data.containsKey("inPublications") && item.data["inPublications"] == "true";
        }).toList();
        _showItems.addAll(tempItems);
        break;
      case DrawerBtn.trash:
        // TODO: Handle this case.
    }
    _notifyShowItems();
  }

  void _resetShowItems() {
    _showItems.clear();
  }

  void _notifyShowItems() {
    _showItemsController.add(_showItems);
    notifyListeners();
  }

  /// 首次运行，完整同步数据，从服务器
  Future<void> _performCompleteSync() async {
    // 获取所有集合
    await _loadAllCollections();
    // 获取所有条目
    await _loadAllItems();
  }

  void dispose() {
    _showItemsController.close();
  }

  Future<void> _loadDataFromLocalDatabase() async {
    _items = await zoteroDataSql.getItems();
    var collections = await zoteroDataSql.getCollections();
    _collections.addAll(collections);

    _resetShowItems();
    for (var collection in collections) {
      _showItems.add(Item(
        itemInfo: ItemInfo(id: 0, itemKey: collection.key, groupId: collection.groupId,
            version: collection.version, deleted: false),
        itemData: [ItemData(id: 0, parent: collection.key, name: "title", value: collection.name, valueType: "String")],
        creators: [],
        tags: [],
        collections: [],
      ));
    }

    _showItems.addAll(_items);
  }

  Future<void> _loadAllCollections() async {
    var collections = await zoteroData.getCollections(0, _userId, 0);
    await zoteroDataSql.saveCollections(collections);
    _collections.addAll(collections);

    for (var collection in collections) {
      _showItems.add(Item(
        itemInfo: ItemInfo(id: 0, itemKey: collection.key, groupId: collection.groupId,
            version: collection.version, deleted: false),
        itemData: [ItemData(id: 0, parent: collection.key, name: 'title', value: collection.name, valueType: "String")],
        creators: [],
        tags: [],
        collections: [],
      ));
    }
  }

  Future<void> _loadAllItems() async {
    _items = await zoteroData.getItems(_userId);
    _showItems.addAll(_items);
    await zoteroDataSql.saveItems(_items);
    await SharedPref.setBool(PrefString.isFirst, false);
  }
}