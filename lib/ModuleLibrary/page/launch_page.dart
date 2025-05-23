import 'package:flutter/cupertino.dart';
import 'package:module_library/ModuleLibrary/page/LibraryPage.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_page.dart';

import '../share_pref.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _checkFirstStart(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {

          debugPrint("isFirstStart: ${snapshot.data}");

          if (snapshot.data == null) {
            return const Text("Error");
          }

          if (snapshot.data == true) {
            return SyncPageFragment();
          } else if (snapshot.data == false) {
            return const LibraryPage();
          } else {
            return const Text("Error");
          }
        } else {
          return const CupertinoActivityIndicator();
        }
      },
    );
  }

  Future<bool> _checkFirstStart() async {
    await SharedPref.init();
    return SharedPref.getBool(PrefString.isFirst, true);
  }
}
