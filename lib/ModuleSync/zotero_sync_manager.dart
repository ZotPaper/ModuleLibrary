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

  var _loadingItemsFinished = false;
  var _loadingCollectionsFinished = false;
  var _loadingTrashFinished = false;

  List<Item> _downloadingItems = [];

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

    _loadingCollectionsFinished = true;
    _finishSingleStep();
  }

  /// 从zotero中获取所有条目
  Future<void> _loadAllItems() async {
    var items = await zoteroHttp.getItems(
      zoteroDB,
      _userId,
      onProgress: (progress, total) {
        debugPrint("SyncManager加载Item进度：$progress/$total");
        // 通知下载进度
        _onProgressCallback?.call(progress, total);
      },
      onFinish: (items) {
        debugPrint("SyncManager加载Item完成，条目数量：${items.length}");

        _downloadingItems = items;

        _loadingItemsFinished = true;
        _finishSingleStep();
      },
      onError: (errorCode, msg) {
        debugPrint("加载错误：$msg");
      },
    );

    // todo 记录到数据库中，提花大
    // _showItems.addAll(_items);
    await zoteroDataSql.saveItems(items);
  }

  /// 获取zotero回收站中的条目
  Future _loadTrashedItems() async {
    await zoteroHttp.getTrashedItems(zoteroDB, _userId,
      onProgress: (progress, total) {
        debugPrint("SyncManager加载回收站中的Item进度：$progress/$total");
        // 通知下载进度
        // onProgressCallback?.call(progress, total);
      },
      onFinish: (items) {
        /// 处理回收站中的条目
        _handleItemsOfTrash(items).then((res) {
          _loadingTrashFinished = true;
          _finishSingleStep();
        });
      },
      onError: (errorCode, msg) {
        debugPrint("加载错误：$msg");
      },
    );


  }

  Future<void> _handleItemsOfTrash(List<Item> items) async {
    debugPrint("Moyear===== SyncManager获取到回收站条目：${items.length}");

    for (var item in items) {
      // 获取合集下的条目
      await zoteroDataSql.moveItemToTrash(item);
      debugPrint("Moyear===== SyncManager将条目：${item.itemKey} 放到回收站");
    }

  }

  /// 完成每一个同步都会调用一阶段
  void _finishSingleStep() {
    // debugPrint("Moyear===== 完成一阶段 $_loadingCollectionsFinished $_loadingItemsFinished $_loadingTrashFinished");

    if (_loadingCollectionsFinished && _loadingItemsFinished && _loadingTrashFinished) {
      _loadLibraryStage2().then((res) {
        _finishLibrarySync();
      });
    }
  }

  /// 第二阶段：处理回收站中的条目
  /// Checks for deleted entries on the zotero servers and mirrors those changes on the local database.
  /// we have to assume the library is loaded.
  Future<void> _loadLibraryStage2() async {
    if (!_loadingTrashFinished || !_loadingCollectionsFinished || !_loadingItemsFinished) {
      throw Exception("Error cannot proceed to stage 2 if library still loading.");
    }

    final int deletedItemsCheckVersion = await zoteroDB.getLastDeletedItemsCheckVersion();
    final int libraryVersion = await zoteroDB.getLibraryVersion();

    if (deletedItemsCheckVersion == libraryVersion) {
      debugPrint('Not checking deleted items because library hasn\'t changed. $libraryVersion');
      return; // nothing to check
    }

    try {
      final deletedEntries = await zoteroHttp.getDeletedEntries(
        _userId,
        deletedItemsCheckVersion,
      );

      debugPrint('Moyear=== SyncManager处理删除的条目 size ${deletedEntries?.items?.length} ${deletedEntries}');

      if (deletedEntries != null) {
        // 删除 item
        for (String itemKey in deletedEntries.items) {
          debugPrint('Deleting item $itemKey');
          await zoteroDataSql.deleteItem(itemKey);
        }

        // 删除 collection
        for (String collectionKey in deletedEntries.collections) {
          debugPrint('Deleting collection $collectionKey');
          await zoteroDataSql.deleteCollection(collectionKey);
        }

        debugPrint('Setting deletedLibraryVersion to $libraryVersion from $deletedItemsCheckVersion');
        await zoteroDB.setLastDeletedItemsCheckVersion(libraryVersion);
      }
    } catch (e, stack) {
      debugPrint('Error while updating deleted entries: $e\n$stack');
      rethrow;
    }
  }

  void _finishLibrarySync() {
    _onFinishCallback?.call(_downloadingItems);
  }
}


class SyncProgress {
  final int progress;
  final int total;

  SyncProgress(this.progress, this.total);
}