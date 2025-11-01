import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:module_base/utils/tracking/dot_tracker.dart';
import 'package:module_library/ModuleSync/zotero_sync_manager.dart';
import '../../../LibZoteroStorage/entity/Item.dart';
import '../../../utils/local_zotero_credential.dart';
import '../../share_pref.dart';
import '../../utils/my_logger.dart';
import '../../zotero_provider.dart';

class SyncViewModel with ChangeNotifier {

  String _userId = "";
  String _apiKey = "";

  final ZoteroSyncManager zoteroSyncManager = ZoteroSyncManager.instance;

  Function(int progress, int total, List<Item>?)? onProgressCallback;

  // 1. 使用 BehaviorSubject 发送路由跳转指令
  final StreamController<String> _navigationController = StreamController();

  // 2. 暴露 Stream 供 View 监听
  Stream<String> get navigationStream => _navigationController.stream;

  SyncViewModel() : super();

  void init() async {
    // 获取本地保存的 Zotero 用户信息
    await fetchZoteroUserCredential();

    // 初始化zotero api
    ZoteroProvider.initZoteroProvider(_userId, _apiKey);
    zoteroSyncManager.init(_userId, _apiKey);

    // 判断是否初次启动,没有就开始完整同步数据
    bool isNeverSynced = await zoteroSyncManager.isNeverSynced();
    if (isNeverSynced) {
      MyLogger.d("=============isNeverSynced userId: $_userId apiKey: $_apiKey");

      // 完整同步埋点
      DotTracker
          .addBot("FIRST_COMPLETE_SYNC", description: "初次启动时完整同步数据")
          .report();

      // 初次启动，从网络获取数据并保存到数据库
      await _performCompleteSync();
    }
  }

  /// 首次运行，完整同步数据，从服务器
  Future<void> _performCompleteSync() async {
    zoteroSyncManager.startCompleteSync(
      onProgressCallback: onProgressCallback,
      onFinishCallback: (total) {
        _onSyncComplete();

        // 完整同步埋点
        DotTracker
            .addBot("FIRST_COMPLETE_SYNC_FINISH", description: "初次完整同步完成")
            .addParam("totalItemCount", total)
            .report();
      },
    );
  }


  void _navigateToLibrary() {
    _navigationController.add("libraryPage");
  }

  Future<void> _onSyncComplete() async {
    // await SharedPref.setBool(PrefString.isFirst, false);
    // 跳转到 Library 页面
    _navigateToLibrary();
  }

  Future<void> fetchZoteroUserCredential() async {
    _userId = await LocalZoteroCredential.getUserId();
    _apiKey = await LocalZoteroCredential.getApiKey();
  }


}