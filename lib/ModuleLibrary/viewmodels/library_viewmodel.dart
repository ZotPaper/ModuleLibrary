import 'dart:async';

import 'package:flutter/material.dart';
import 'package:module/ModuleLibrary/model/page_type.dart';
import '../../LibZoteroStorage/entity/Collection.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../LibZoteroStorage/entity/ItemData.dart';
import '../../LibZoteroStorage/entity/ItemInfo.dart';
import '../api/ZoteroDataHttp.dart';
import '../api/ZoteroDataSql.dart';
import '../share_pref.dart';
import '../page/LibraryUI/drawer.dart';
import 'package:rxdart/rxdart.dart';

class LibraryViewModel with ChangeNotifier {
  final ZoteroDataSql zoteroDataSql = ZoteroDataSql();

  PageType curPage = PageType.library;

  List<Item> _items = [];
  List<Collection> _collections = [];
  late final List<Item> _showItems = [];

  LibraryViewModel() : super() {
  }

  final BehaviorSubject<PageType> _curPageController = BehaviorSubject<PageType>.seeded(PageType.blank);
  Stream<PageType> get curPageStream => _curPageController.stream;

  final StreamController<List<Item>> _showItemsController = StreamController<List<Item>>.broadcast();
  Stream<List<Item>> get showItemsStream => _showItemsController.stream;

  List<Item> get items => _items;
  List<Collection> get collections => _collections;
  List<Item> get showItems => _showItems;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void init() async {
    setLoading(true);
    await SharedPref.init();
    bool isFirstStart = SharedPref.getBool(PrefString.isFirst, true);

    if (isFirstStart) {
      debugPrint("=============isFirstStart");
      // todo 切换到同步页面
      navigateToPage(PageType.sync);
    } else {
      // 从数据库加载数据
      await _loadDataFromLocalDatabase();
      // 切换到列表页面
      navigateToPage(PageType.library);
    }

    setLoading(false);
  }


  void navigateToPage(PageType page) {
    curPage = page;
    notifyListeners();
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

  void dispose() {
    _showItemsController.close();
    _curPageController.close();
  }

  Future<void> _loadDataFromLocalDatabase() async {
    _items = await zoteroDataSql.getItems();
    var collections = await zoteroDataSql.getCollections();
    _collections = collections;

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
    _notifyShowItems();
  }
}