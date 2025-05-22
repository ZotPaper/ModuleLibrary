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

  String title = '';

  List<Item> _items = [];
  final List<Collection> _displayedCollections = [];

  List<Collection> get displayedCollections => _displayedCollections;

  final List<ListEntry> _listEntries = [];
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
      showListEntriesIn("library");
    }

    setLoading(false);
  }


  void navigateToPage(PageType page) {
    curPage = page;
    notifyListeners();
  }

  /// 处理抽屉按钮点击事件
  void handleDrawerItemTap(DrawerBtn drawerBtn, {String? collectionKey}) {
    switch (drawerBtn) {
      case DrawerBtn.home:
        // showListEntriesIn("home");
        break;
      case DrawerBtn.favourites:
        // showListEntriesIn("favourites");
      case DrawerBtn.library:
        showListEntriesIn("library");
        break;
      case DrawerBtn.unfiled:
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
        showListEntriesIn("trashes");
      default:
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
    // 把collections保存到内存中
    zoteroDB.setCollections(collections);

    // 只显示顶级的集合
    _displayedCollections.clear();
    _displayedCollections.addAll(collections.where((it) {
      return !it.hasParent();
    }));
  }

  /// 显示指定位置的列表entries
  Future<void> showListEntriesIn(String locationKey) async {
    List<ListEntry> list = [];
    switch (locationKey) {
      case 'library':
        list = await _getMyLibraryEntries();
        title = "我的文库";
        break;
      case 'unfiled':
        list = await _getUnfiledEntries();
        debugPrint('Moyear=== unfiled res:${list.length}');
        title = "未分类条目";
        break;
      default:
        list = await _getEntriesInCollection(locationKey);
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

  /// 获取指定集合下面的entries
  Future<List<ListEntry>> _getEntriesInCollection(String collectionKey) async {
    List<ListEntry> entries = [];
    // 获取指定集合下的item
    var res = zoteroDB.getItemsFromCollection(collectionKey).map((ele) {
      return ListEntry(item: ele);
    });
    entries.addAll(res);
    debugPrint("getEntriesInCollection: $collectionKey size: ${res.length}");
    // todo 获取子集合
    return entries;
  }

  /// 获取未分类的条目
  Future<List<ListEntry>> _getUnfiledEntries() async {
    List<ListEntry> entries = [];
    var res = zoteroDB.getUnfiledItems().map((ele) {
      return ListEntry(item: ele);
    });
    entries.addAll(res);
    return entries;
  }


  /// 处理侧边栏合集的点击事件
  Future<void> handleCollectionTap(Collection collection) async {
    // var itemKey = collection.key;
    // var entries = await _getEntriesInCollection(itemKey);
    title = collection.name;

    var res = await zoteroDataSql.getItemsInCollection(collection.key);
    var entriesItems = res.map((ele) {
      return ListEntry(item: ele);
    });
    // debugPrint('Moyear== handleCollectionTap: $itemKey size: ${entries.length}');

    var subCollections = await zoteroDB.getSubCollectionsOf(collection.key);
    var entriesCollections = subCollections.map((ele) {
      return ListEntry(collection: ele);
    });

    _listEntries.clear();
    _listEntries.addAll(entriesCollections);
    _listEntries.addAll(entriesItems);

    _notifyShowItems();
    notifyListeners();

  }


// _resetShowItems();
// final tempItems = _items.where((item) => item.collections.isEmpty).toList();
// _showItems.addAll(tempItems);

}