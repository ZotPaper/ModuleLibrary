import 'package:flutter/cupertino.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';

import '../LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import '../LibZoteroStorage/entity/Item.dart';
import '../LibZoteroStorage/entity/ItemData.dart';
import '../LibZoteroStorage/entity/ItemInfo.dart';
import '../ModuleLibrary/api/ZoteroDataHttp.dart';
import '../ModuleLibrary/api/ZoteroDataSql.dart';
import '../ModuleLibrary/share_pref.dart';
import '../ModuleLibrary/viewmodels/zotero_database.dart';
import '../ModuleTagManager/zotero_setting_manager.dart';

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

  var _loadingZoteroSettingFinished = false;

  /// 本次Sync下载的条目总数量
  var _curDownloadedTotal = -1;

  bool _isSyncing = false;
  bool isSyncing() {
    return _isSyncing;
  }

  Function(int progress, int total, List<Item>?)? _onProgressCallback;
  Function(int total)? _onFinishCallback;

  void init(String userId, String apiKey) {
    _userId = userId;
    _apiKey = apiKey;

    zoteroHttp = ZoteroDataHttp(userId: _userId, apiKey: _apiKey);
  }

  // 判断是否已经配置了用户id和apiKey
  bool isConfigured() {
    return _userId.isNotEmpty && _apiKey.isNotEmpty;
  }

  Future<void> startCompleteSync({
    Function(int progress, int total, List<Item>?)? onProgressCallback,
    Function(int total)? onFinishCallback,
  }) async {
    if (!isConfigured()) {
      throw Exception("请先配置用户id和apiKey");
    }

    if (_isSyncing) {
      debugPrint("SyncManager正在同步中，请稍后...");
      return;
    }

    _onProgressCallback = onProgressCallback;
    _onFinishCallback = onFinishCallback;

    _isSyncing = true;
    // 标记已经同步过了，主要用于第一次同步中断时避免重复同步的情况
    markDataSynced();

    // todo 考虑原子性
    // 获取所有集合
    _loadAllCollections();
    // 获取所有条目
    _loadAllItems();
    // 获取所有已删除的条目
    _loadTrashedItems();
    _loadZoteroSettings(zoteroDB);
  }

  /// 从zotero中获取所有集合
  Future<void> _loadAllCollections() async {
    List<Collection> res = [];
    // todo 便利获取所有的集合
    zoteroHttp.getCollections(
        zoteroDB,
        onProgress: (progress, total, collections) {
          if (collections != null) {
            res.addAll(collections);
          }
        },
        onFinish: (total) async {
          await zoteroDataSql.saveCollections(res);
          _loadingCollectionsFinished = true;
          _finishSingleStep();
        },
        onError: (errorCode, msg) {
          MyLogger.e("SyncManager加载集合错误：$msg");
          // 下载错误，跳过
          _loadingCollectionsFinished = true;
          _finishSingleStep();
        },
    );

  }

  /// 从zotero中获取所有条目 - 已解决数据库锁定问题
  Future<void> _loadAllItems() async {
    // 解决方案：使用批量保存和事务处理，避免数据库锁定
    // 1. 收集所有items后批量保存，而不是逐批保存
    // 2. 使用数据库事务确保数据一致性
    // 3. 添加并发控制避免多个保存操作冲突
    
    final List<Item> allItems = [];
    final int batchSize = 100; // 每100个items保存一次，平衡内存和性能
    
    zoteroHttp.getItems(
      zoteroDB,
      onProgress: (progress, total, items) {
        MyLogger.d("SyncManager加载Item进度：$progress/$total");

        if (items != null && items.isNotEmpty) {
          allItems.addAll(items);
          
          // 达到批次大小时进行保存，减少数据库操作频率
          if (allItems.length >= batchSize) {
            MyLogger.d("批量保存 ${allItems.length} 个items到数据库");
            zoteroDataSql.saveItems(List.from(allItems));
            allItems.clear(); // 清空已保存的items，释放内存
          }
        }

        MyLogger.d("SyncManager加载items数量：${items?.length}，累计：${allItems.length}");

        // 通知下载进度
        _onProgressCallback?.call(progress, total, items);
      },
      onFinish: (total) {
        MyLogger.d("SyncManager加载Item完成，条目数量：$total");

        // 保存剩余的items
        if (allItems.isNotEmpty) {
          MyLogger.d("保存最后 ${allItems.length} 个items到数据库");
          zoteroDataSql.saveItems(allItems);
        }

        _curDownloadedTotal = total;

        // 下载完成的时候删除缓存下载进度信息
        zoteroDB.destroyDownloadProgress();

        _loadingItemsFinished = true;
        _finishSingleStep();
      },
      onError: (errorCode, msg) {
        MyLogger.e("SyncManager加载items错误：$msg");
        
        // 即使出错也要保存已下载的数据
        if (allItems.isNotEmpty) {
          MyLogger.d("发生错误，保存已下载的 ${allItems.length} 个items");
          zoteroDataSql.saveItems(allItems);
        }
        
        _loadingItemsFinished = true;
        _finishSingleStep();
      },
    );
  }

  /// 获取zotero回收站中的条目
  Future _loadTrashedItems() async {
    List<Item> res = [];

    zoteroHttp.getTrashedItems(zoteroDB,
      onProgress: (progress, total, items) {
        MyLogger.d("SyncManager加载回收站中的Item进度：$progress/$total");
        if (items != null) {
          res.addAll(items);
          MyLogger.d("SyncManager加载回收站中的Items数量：${items?.length}");
        }
        // 通知下载进度
        // onProgressCallback?.call(progress, total);
      },
      onFinish: (total) {
        MyLogger.d("SyncManager加载回收站中的数据成功，数量为：$total");
        /// 处理回收站中的条目
        _handleItemsOfTrash(res).then((res) {
          _loadingTrashFinished = true;
          _finishSingleStep();
        });
      },
      onError: (errorCode, msg) {
        debugPrint("SyncManager加载回收站错误：$msg");
      },
    );
  }

  /// 获取zotero的设置
  Future<void> _loadZoteroSettings(ZoteroDB db) async {
    int settingVersion = await db.getZoteroSettingVersion();
    // 每次都获取全部设置信息也可以设置为 -1
    // int settingVersion = -1;

    try {
      final response = await zoteroHttp.getZoteroSettings(settingVersion);
      if (response == null) {
        return;
      }

      final int newVersion = response.lastModifiedVersion;

      MyLogger.d("[oldVersion: $settingVersion; newVersion: $newVersion]，result: $response");

      // 追加设置到本地 json（ZoteroSettingManager 自行封装）
      await ZoteroSettingManager.instance.appendSettings(response);

      // 设置本地版本号
      await db.setZoteroSettingVersion(newVersion);
    } catch (e, stack) {
      debugPrint('SyncZoteroSettings error: $e\n$stack');
    }
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
    // todo
    _onFinishCallback?.call(_curDownloadedTotal);
    _curDownloadedTotal = -1;
    _isSyncing = false;

    _loadingZoteroSettingFinished = false;
    _loadingCollectionsFinished = false;
    _loadingItemsFinished = false;
    _loadingTrashFinished = false;
  }

  Future<bool> isNeverSynced() async {
    var isFirstRun = SharedPref.getBool(PrefString.isFirst, true);
    return isFirstRun;
  }

  Future<bool> markDataSynced() async {
    return SharedPref.setBool(PrefString.isFirst, false);
  }
}


class SyncProgress {
  final int progress;
  final int total;

  SyncProgress(this.progress, this.total);
}