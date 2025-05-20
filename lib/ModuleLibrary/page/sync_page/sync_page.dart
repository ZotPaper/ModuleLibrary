import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module/ModuleLibrary/page/sync_page/sync_viewmodel.dart';

import '../../res/ResColor.dart';
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

  var _loadingMessage = "首次运行，完整同步页面";

  @override
  void initState() {
    super.initState();
    _viewModel = SyncViewModel();
    _controller = AnimationController(vsync: this);

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
      body: StreamBuilder(
        stream: _viewModel.navigationStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            debugPrint('接收到跳转事件: ${snapshot.data}');
            // 确保在帧结束后执行导航
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint('执行页面跳转');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LaunchPage(),
                ),
              );
            });
          }
          return Center(
            child: Text(_loadingMessage),
          );
        },
      ),
    );
  }


  void _onUpdateProgress(int progress, int total) {
    debugPrint('接收到进度更新: $progress/$total');
    // 更新进度
    _loadingMessage = "正在同步数据: ${progress}/${total}";
    setState(() {}); // 添加状态更新
  }

}
