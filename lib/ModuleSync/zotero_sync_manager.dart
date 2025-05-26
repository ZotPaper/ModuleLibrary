import 'package:flutter/cupertino.dart';

import '../LibZoteroStorage/entity/Item.dart';
import '../LibZoteroStorage/entity/ItemData.dart';
import '../LibZoteroStorage/entity/ItemInfo.dart';
import '../ModuleLibrary/api/ZoteroDataHttp.dart';
import '../ModuleLibrary/api/ZoteroDataSql.dart';
import '../ModuleLibrary/share_pref.dart';
import '../ModuleLibrary/viewmodels/zotero_database.dart';

class ZoteroSyncManager {
  static final ZoteroSyncManager _singleton = ZoteroSyncManager._internal();
  static ZoteroSyncManager get instance => _singleton;

  late final ZoteroDataHttp zoteroHttp;

  final ZoteroDataSql zoteroDataSql = ZoteroDataSql();

  ZoteroSyncManager._internal();

  String _userId = "";
  String _apiKey = "";

  ZoteroDB zoteroDB = ZoteroDB();

  Function(int progress, int total)? _onProgressCallback;
  Function(List<Item> items)? _onFinishCallback;

  void init(String userId, String apiKey) {
    _userId = userId;
    _apiKey = apiKey;

    zoteroHttp = ZoteroDataHttp(apiKey: _apiKey);
  }

  // 判断是否已经配置了用户id和apiKey
  bool isConfigured() {
    return _userId.isNotEmpty && _apiKey.isNotEmpty;
  }

  Future<void> startCompleteSync({
    Function(int progress, int total)? onProgressCallback,
    Function(List<Item> items)? onFinishCallback,
  }) async {
    if (!isConfigured()) {
      throw Exception("请先配置用户id和apiKey");
    }

    _onProgressCallback = onProgressCallback;
    _onFinishCallback = onFinishCallback;

    // todo 考虑原子性
    // 获取所有集合
    await _loadAllCollections();
    // 获取所有条目
    await _loadAllItems();
    // 获取所有已删除的条目
    await _loadTrashedItems();
  }

  /// 从zotero中获取所有集合
  Future<void> _loadAllCollections() async {
    var collections = await zoteroHttp.getCollections(zoteroDB, _userId);
    await zoteroDataSql.saveCollections(collections);
  }

  /// 从zotero中获取所有条目
  Future<void> _loadAllItems() async {
    var items = await zoteroHttp.getItems(
      zoteroDB,
      _userId,
      onProgress: (progress, total) {
        debugPrint("加载Item进度：$progress/$total");
        // 通知下载进度
        _onProgressCallback?.call(progress, total);
      },
      onFinish: (items) {
        debugPrint("加载Item完成，条目数量：${items.length}");
        // 更新本地的文库版本
      },
      onError: (errorCode, msg) {
        debugPrint("加载错误：$msg");
      },
    );

    // todo 记录到数据库中，提花大
    // _showItems.addAll(_items);
    await zoteroDataSql.saveItems(items);
    await SharedPref.setBool(PrefString.isFirst, false);
  }

  /// 获取zotero回收站中的条目
  Future _loadTrashedItems() async {
    var items = await zoteroHttp.getTrashedItems(zoteroDB, _userId,
      onProgress: (progress, total) {
        debugPrint("加载回收站中的Item进度：$progress/$total");
        // 通知下载进度
        // onProgressCallback?.call(progress, total);
      },
      onFinish: (items) {
        debugPrint("加载回收站中的Item完成，条目数量：${items.length}");
      },
      onError: (errorCode, msg) {
        debugPrint("加载错误：$msg");
      },
    );

    await _loadingLibraryStage2(items);
  }

  /// 第二阶段：处理回收站中的条目
  Future<void> _loadingLibraryStage2(List<Item> items) async {
    debugPrint("Moyear===== 获取到回收站条目：${items.length}");

    for (var item in items) {
      // 获取合集下的条目
      await zoteroDataSql.moveItemToTrash(item);
      debugPrint("Moyear===== 将条目：${item.itemKey} 放到回收站");
    }

    // todo 解决下载中断或者其他类型的错误导致无法跳转的问题
    _onFinishCallback?.call(items);
  }

}