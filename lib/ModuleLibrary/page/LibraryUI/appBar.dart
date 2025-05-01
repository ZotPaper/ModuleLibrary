import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../res/ResColor.dart';

PreferredSizeWidget pageAppBar({required Function leadingIconTap,required Function filterMenuTap,required Function tagsTap}) {
  return AppBar(
    leading: IconButton(onPressed: () {
      leadingIconTap();
    }, icon: Icon(Icons.list)),
    toolbarHeight: 40,
    // TRY THIS: Try changing the color here to a specific color (to
    // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
    // change color while the other colors stay the same.
    backgroundColor: ResColor.bgColor,
    // Here we take the value from the MyHomePage object that was created by
    // the App.build method, and use it to set our appbar title.
    title: Center(child: Text("Home"),),
    actions: [
      PopupMenuButton<String>(
        color: ResColor.bgColor,
        onSelected: (String result) {
          // 处理选项点击事件
          switch (result) {
            case 'Filter Menu':
              print('Filter Menu');
              filterMenuTap();
              break;
            case 'Tags':
              print('Tags');
              tagsTap();
              break;
          }
        },
        itemBuilder: (BuildContext context) =>
        <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'Filter Menu',
            child: Text('Filter Menu'),
          ),
          const PopupMenuItem<String>(
            value: 'Tags',
            child: Text('Tags'),
          ),
        ],
      ),
    ],
  );
}
