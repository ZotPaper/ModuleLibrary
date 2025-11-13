import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_base/build.dart';
import 'package:module_base/utils/tracking/dot_tracker.dart';
import 'package:module_library/LibZoteroAttachDownloader/default_attachment_storage.dart';
import 'package:module_library/routers.dart';
import 'package:module_library/utils/webdav_configuration.dart';
import 'package:module_base/native/native_zotero_channel.dart';
import '../../utils/local_zotero_credential.dart';
import '../share_pref.dart';
import '../utils/my_logger.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container()
    );
  }

  Future<void> _initializeApp() async {
    try {
      await SharedPref.init();
      /// 判断是否本地保存了用户信息
      final isUserLoggedIn = await LocalZoteroCredential.isLoggedIn();

      if (!mounted) return;

      if (!isUserLoggedIn) {
        /// 检查是否由v0.0.2以下升级到新版本, 直接进行数据迁移
        var shouldMigrate = await _checkAndMigrationForV002();
        if (!shouldMigrate) {
          /// 跳转到账户设置页面
          _jumpToSyncSetupPage();
        }
      } else {
        /// 跳转到主页面
        _jumpToLibraryPage();
      }
    } catch (e, stackTrace) {
      debugPrint("LaunchPage 初始化失败: $e\n$stackTrace");
      if (!mounted) return;
      // 可以显示错误页面或提示
    }
  }

  void _jumpToSyncingPage() {
    MyRouter.instance.pushReplacementNamed(context, "syncingPage");
  }

  void _jumpToSyncSetupPage() {
    try {
      MyRouter.instance.pushReplacementNamed(context, "syncSetupPage");
    } catch (e) {
      MyLogger.e('Error: $e');
      // 测试账号登录
      testAccountLogin();
    }
  }

  void _jumpToLibraryPage() {
    MyRouter.instance.pushReplacementNamed(context, "libraryPage");
  }

  /// 测试账号登录
  void testAccountLogin() {
    if (!BuildMode.isDebug) return;
    // 是否是debug模式
    String userId = "16074844";
    String apiKey = "znrrHVJZMhSd8I9TWUxZjAFC";

    // String userId = "8120462";
    // String apiKey = "H95AVvqDvU72LC4qj9Azc5do";

    String userName = "testUserName";

    LocalZoteroCredential.saveCredential(apiKey, userId, userName).then((onValue){
      _jumpToSyncingPage();
    });

    // // webdav信息
    // String webdavAddress = "https://miya.teracloud.jp/dav/";
    // String username = "moyearzhou";
    // String password = "4Efgzy73eTr96DPS";
    //
    // WebdavConfiguration.setWebdavConfiguration(webdavAddress, username, password);
    // WebdavConfiguration.setUseWebdav(true);

    // ModuleLibrary默认使用外部pdf阅读器
    DefaultAttachmentStorage.instance.setOpenPDFWithExternalApp(true);
  }

  /// 检查是否由v0.0.2以下升级到新版本
  Future<bool> _checkAndMigrationForV002() async {
    // 是否是debug模式
    Map? credentialMap;
    try {
      credentialMap = await ZoteroChannel.getLocalCredentialV1();
    } catch (e) {
      // 没有这一方法，忽略
    }
    if (credentialMap == null) {
      MyLogger.d("找不到旧的本地凭证，忽略");
      return false;
    } else {
      String userId = credentialMap["userId"] ?? "";
      String apiKey = credentialMap["userKey"] ?? "";
      String userName = credentialMap["userName"] ?? "";

      if (userId.isEmpty || apiKey.isEmpty) {
        MyLogger.d("旧的本地凭证无效，忽略");
        return false;
      }

      // 标记为为同步过，需要完整重新同步
      await SharedPref.setBool(PrefString.isFirst, true);

      MyLogger.d("找到旧的本地凭证，开始迁移");

      LocalZoteroCredential.saveCredential(apiKey, userId, userName).then((onValue){
        // 数据迁移埋点上报
        DotTracker
            .addDot("APP_MIGRATION_V002", description: "v0.0.2升级，账户重新同步")
            .report();

        _jumpToSyncingPage();
        MyLogger.d("跳转到同步页面...");
      });
      return true;
    }
  }
}
