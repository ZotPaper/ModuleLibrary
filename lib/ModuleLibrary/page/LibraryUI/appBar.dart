import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../res/ResColor.dart';

PreferredSizeWidget pageAppBar(
    {required String title,
      Function? leadingIconTap,
    required Function filterMenuTap,
    required Function tagsTap}) {
  return AppBar(
    leading: leadingIconTap != null ? IconButton(
        onPressed: () {
          leadingIconTap();
        },
        icon: Icon(Icons.menu, color: ResColor.textMain,)) : null,
    automaticallyImplyLeading: leadingIconTap != null,
    toolbarHeight: 46,
    // TRY THIS: Try changing the color here to a specific color (to
    // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
    // change color while the other colors stay the same.
    backgroundColor: ResColor.bgColor,
    // Here we take the value from the MyHomePage object that was created by
    // the App.build method, and use it to set our appbar title.
    title: Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 16, color: ResColor.textMain),
      ),
    ),

    actionsIconTheme: IconThemeData(color: ResColor.textMain),
    actions: [
      PopupMenuButton<String>(
        color: ResColor.bgColor,
        // splashRadius: 20,
        shadowColor: const Color(0x88FFFFFF),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        onSelected: (String result) {
          // 处理选项点击事件
          switch (result) {
            case 'Filter Menu':
              // print('Filter Menu');
              filterMenuTap();
              break;
            case 'Tags':
              // print('Tags');
              tagsTap();
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'Filter Menu',
            child: Text('筛选', style: TextStyle(color: ResColor.textMain)),
          ),
          PopupMenuItem<String>(
            value: 'Tags',
            child: Text('标签', style: TextStyle(color: ResColor.textMain)),
          ),
        ],
      ),
    ],
  );
}
