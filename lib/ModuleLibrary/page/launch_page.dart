import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_library/routers.dart';
import 'package:module_library/utils/webdav_configuration.dart';

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
        /// 跳转到同步设置页面
        _jumpToSyncSetupPage();
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
  }
}
