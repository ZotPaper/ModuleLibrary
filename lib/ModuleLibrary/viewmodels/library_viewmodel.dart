import 'dart:async';

import 'package:flutter/material.dart';
import 'package:module/ModuleLibrary/model/list_entry.dart';
import 'package:module/ModuleLibrary/model/page_type.dart';
import 'package:module/ModuleLibrary/viewmodels/zotero_database.dart';
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

  List<Collection> get collections => _collections;

  List<ListEntry> _listEntries = [];
  List<ListEntry> get listEntries => _listEntries;

  // final List<Item> _showItems = [];
  // List<Item> get showItems => _showItems;

  final ZoteroDB zoteroDB = ZoteroDB();

  LibraryViewModel() : super() {}

  final BehaviorSubject<PageType> _curPageController = BehaviorSubject<PageType>.seeded(PageType.blank);
  Stream<PageType> get curPageStream => _curPageController.stream;

  // final StreamController<List<Item>> _showItemsController = StreamController<List<Item>>.broadcast();
  // Stream<List<Item>> get showItemsStream => _showItemsController.stream;

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
      // 切换到同步页面
      navigateToPage(PageType.sync);
    } else {
      // 从数据库加载数据
      await _loadDataFromLocalDatabase();
      // 切换到列表页面
      navigateToPage(PageType.library);

      // 显示所有条目
      showListEntriesIn("all");
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
        // _resetShowItems();
        // for (var collection in _collections) {
        //   _showItems.add(Item(
        //     itemInfo: ItemInfo(id: 0, itemKey: collection.key, groupId: collection.groupId,
        //       version: collection.version, deleted: false),
        //     itemData: [ItemData(id: 0, parent: collection.key, name: 'title', value: collection.name, valueType: "String")],
        //     creators: [],
        //     tags: [],
        //     collections: [],
        //   ));
        // }
        // _showItems.addAll(_items);

        showListEntriesIn("home");
        break;
      case DrawerBtn.favourites:
        // TODO: Handle this case.
        showListEntriesIn("favourites");
      case DrawerBtn.library:
        showListEntriesIn("library");
        break;
      case DrawerBtn.unfiled:
        // _resetShowItems();
        // final tempItems = _items.where((item) => item.collections.isEmpty).toList();
        // _showItems.addAll(tempItems);
        showListEntriesIn("unfiled");
        break;
      case DrawerBtn.publications:
        // _resetShowItems();
        // final tempItems = _items.where((item) {
        //   return item.data.containsKey("inPublications") && item.data["inPublications"] == "true";
        // }).toList();
        // _showItems.addAll(tempItems);
        showListEntriesIn("publications");
        break;
      case DrawerBtn.trash:
        // TODO: Handle this case.
        showListEntriesIn("publications");
    }
    _notifyShowItems();
  }

  void _resetShowItems() {
    // _showItems.clear();
  }

  void _notifyShowItems() {
    // _showItemsController.add(_showItems);
    notifyListeners();
  }

  void dispose() {
    // _showItemsController.close();
    _curPageController.close();
  }

  /// 从本地数据库中获取数据
  Future<void> _loadDataFromLocalDatabase() async {
    _items = await zoteroDataSql.getItems();
    // 把items保存到内存中
    zoteroDB.setItems(_items);

    var collections = await zoteroDataSql.getCollections();
    _collections = collections;
    // 把collections保存到内存中
    zoteroDB.setCollections(_collections);

    // _resetShowItems();
    // for (var collection in collections) {
    //   _showItems.add(Item(
    //     itemInfo: ItemInfo(id: 0, itemKey: collection.key, groupId: collection.groupId,
    //         version: collection.version, deleted: false),
    //     itemData: [ItemData(id: 0, parent: collection.key, name: "title", value: collection.name, valueType: "String")],
    //     creators: [],
    //     tags: [],
    //     collections: [],
    //   ));
    // }

    // _showItems.addAll(_items);
  }

  /// 显示指定位置的列表entries
  Future<void> showListEntriesIn(String locationKey) async {
    List<ListEntry> list = [];
    switch (locationKey) {
      case 'all':
        list = await _getMyLibraryEntries();
        break;
      case 'unfiled':
        break;
      default:
    }

    _listEntries.clear();
    _listEntries.addAll(list);

    _notifyShowItems();
    notifyListeners();
  }

  /// 获取我的文库页面的条目数据
  Future<List<ListEntry>> _getMyLibraryEntries() async {
    List<ListEntry> entries = [];
    var res = zoteroDB.getDisplayableItems().map((ele) {
      return ListEntry(item: ele);
    });
    entries.addAll(res);
    return entries;
  }
}