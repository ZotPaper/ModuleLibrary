import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../LibZoteroStorage/entity/Collection.dart';
import '../../../LibZoteroStorage/entity/Item.dart';
import '../../../LibZoteroStorage/entity/ItemData.dart';
import '../../../LibZoteroStorage/entity/ItemInfo.dart';
import '../../api/ZoteroDataHttp.dart';
import '../../api/ZoteroDataSql.dart';
import '../../share_pref.dart';

class SyncViewModel with ChangeNotifier {

  // final String _userId = "16082509";
  // final String _apiKey = "KsmSAwR7P4fXjh6QNjRETcqy";

  final String _userId = "16074844";
  final String _apiKey = "znrrHVJZMhSd8I9TWUxZjAFC";

  late final ZoteroDataHttp zoteroHttp;

  final ZoteroDataSql zoteroDataSql = ZoteroDataSql();

  List<Item> _items = [];
  final List<Collection> _collections = [];
  late final List<Item> _showItems = [];

  Function(int progress, int total)? onProgressCallback;

  // 1. 使用 BehaviorSubject 发送路由跳转指令
  final StreamController<String> _navigationController = StreamController();

  // 2. 暴露 Stream 供 View 监听
  Stream<String> get navigationStream => _navigationController.stream;

  SyncViewModel() : super() {
    zoteroHttp = ZoteroDataHttp(apiKey: _apiKey);
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
    }
    /// 通知更新列表
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
    // todo 考虑原子性
    // 获取所有集合
    await _loadAllCollections();
    // 获取所有条目
    await _loadAllItems();
  }

  void dispose() {
    _showItemsController.close();
  }

  Future<void> _loadAllCollections() async {
    var collections = await zoteroHttp.getCollections(0, _userId, 0);
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

  /// 从zotero中获取所有条目
  Future<void> _loadAllItems() async {
    _items = await zoteroHttp.getItems(_userId,
      onProgress: (progress, total) {
        debugPrint("加载Item进度：$progress/$total");
        // todo 通知下载进度
        onProgressCallback?.call(progress, total);
      },
      onFinish: (items) {
        debugPrint("加载Item完成，条目数量：${items.length}");
        // todo 跳转到文库页面
        _navigateToLibrary();
      },
      onError: (errorCode, msg) {
        debugPrint("加载错误：$msg");
      },
    );

    // todo 记录到数据库中
    _showItems.addAll(_items);
    await zoteroDataSql.saveItems(_items);
    await SharedPref.setBool(PrefString.isFirst, false);
  }

  void _navigateToLibrary() {
    _navigationController.add("libraryPage");
  }

}