import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_viewmodel.dart';
import 'package:module_library/routers.dart';
import 'package:provider/provider.dart';

import '../../res/ResColor.dart';
import '../../utils/my_logger.dart';
import '../launch_page.dart';

class SyncPageFragment extends StatefulWidget {
  const SyncPageFragment({super.key});

  @override
  State<SyncPageFragment> createState() => _SyncPageFragmentState();
}

class _SyncPageFragmentState extends State<SyncPageFragment>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late SyncViewModel _viewModel;

  var _loadingMessage = "正在加载中...";

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<SyncViewModel>(context, listen: false);
    _controller = AnimationController(vsync: this);

    MyLogger.d("Moyear=== 进入SyncPageFragment");

    _viewModel.init();
    // 监听进度
    _viewModel.onProgressCallback = _onUpdateProgress;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResColor.bgColor,
      appBar: AppBar(
        backgroundColor: ResColor.bgColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300, maxWidth: 300),
                child: Image.asset(
                  "assets/intro_zotpaper.webp",
                  package: "module_library",
                  fit: BoxFit.contain,
                )
            ),
            const SizedBox(height: 60,),
            StreamBuilder(
              stream: _viewModel.navigationStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  MyLogger.d('接收到跳转事件: ${snapshot.data}');
                  // 确保在帧结束后执行导航
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    MyLogger.d('执行页面跳转');
                    MyRouter.instance.pushReplacementNamed(context, MyRouter.PAGE_LIBRARY);
                  });
                }
                return Text(_loadingMessage);
              },
            ),
          ],
        ),
      ),
    );
  }


  void _onUpdateProgress(int progress, int total, List<Item>? items) {
    MyLogger.d('接收到进度更新: $progress/$total');
    // 更新进度
    _loadingMessage = "正在同步数据: ${progress}/${total}";
    setState(() {}); // 添加状态更新
  }

}
