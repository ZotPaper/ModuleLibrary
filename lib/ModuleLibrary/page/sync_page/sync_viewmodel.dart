import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:module_library/ModuleSync/zotero_sync_manager.dart';

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

  final ZoteroSyncManager zoteroSyncManager = ZoteroSyncManager.instance;

  Function(int progress, int total)? onProgressCallback;

  // 1. 使用 BehaviorSubject 发送路由跳转指令
  final StreamController<String> _navigationController = StreamController();

  // 2. 暴露 Stream 供 View 监听
  Stream<String> get navigationStream => _navigationController.stream;

  SyncViewModel() : super();

  void init() async {
    await SharedPref.init();
    bool isFirstStart = SharedPref.getBool(PrefString.isFirst, true);

    zoteroSyncManager.init(_userId, _apiKey);

    if (isFirstStart) {
      debugPrint("=============isFirstStart");
      // 初次启动，从网络获取数据并保存到数据库
      await _performCompleteSync();
    }
  }

  /// 首次运行，完整同步数据，从服务器
  Future<void> _performCompleteSync() async {
    zoteroSyncManager.startCompleteSync(
      onProgressCallback: onProgressCallback,
      onFinishCallback: (items) {
        _onSyncComplete();
      },
    );
  }

  void dispose() {
  }

  void _navigateToLibrary() {
    _navigationController.add("libraryPage");
  }

  Future<void> _onSyncComplete() async {
    await SharedPref.setBool(PrefString.isFirst, false);
    // 跳转到 Library 页面
    _navigateToLibrary();
  }


}