import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:module_library/ModuleSync/zotero_sync_manager.dart';
import '../../../LibZoteroStorage/entity/Item.dart';
import '../../../utils/local_zotero_credential.dart';
import '../../share_pref.dart';
import '../../utils/my_logger.dart';

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

    zoteroSyncManager.init(_userId, _apiKey);

    // 判断是否初次启动,没有就开始完整同步数据
    bool isNeverSynced = await zoteroSyncManager.isNeverSynced();
    if (isNeverSynced) {
      debugPrint("=============isNeverSynced userId: $_userId apiKey: $_apiKey");
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