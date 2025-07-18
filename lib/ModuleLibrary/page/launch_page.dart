import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_library/ModuleLibrary/page/LibraryPage.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_page.dart';
import 'package:module_library/routers.dart';

import '../share_pref.dart';

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
      final isFirstStart = await _checkFirstStart();

      if (!mounted) return;

      if (isFirstStart == true) {
        _jumpToSyncSetupPage();
      } else {
        _jumpToLibraryPage();
      }
    } catch (e, stackTrace) {
      debugPrint("LaunchPage 初始化失败: $e\n$stackTrace");
      if (!mounted) return;
      // 可以显示错误页面或提示
    }
  }


  Future<bool> _checkFirstStart() async {
    await SharedPref.init();
    return SharedPref.getBool(PrefString.isFirst, true);
  }

  void _jumpToSyncPage() {
    MyRouter.instance.pushReplacementNamed(context, "syncingPage");
  }

  void _jumpToSyncSetupPage() {
    MyRouter.instance.pushReplacementNamed(context, "syncSetupPage");
  }

  void _jumpToLibraryPage() {
    MyRouter.instance.pushReplacementNamed(context, "libraryPage");
  }
}
