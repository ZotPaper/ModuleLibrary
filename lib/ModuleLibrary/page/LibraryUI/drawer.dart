import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';

import '../../../routers.dart';
import '../../res/ResColor.dart';

typedef DrawerItemTapCallback = void Function(DrawerBtn DrawerBtn);

class CustomDrawer extends StatefulWidget {
  final DrawerItemTapCallback onItemTap;
  final List<Collection> collections;
  final Function onCollectionTap;

  const CustomDrawer({super.key, required this.onItemTap,required this.collections,required this.onCollectionTap});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}
enum DrawerBtn {
  home,
  favourites,
  library,
  unfiled,
  publications,
  trash
}
class _CustomDrawerState extends State<CustomDrawer> {
  String _selectDrawerTitle = '';

  Widget pageDrawer(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(10),
        color: ResColor.bgColor,
        child: SafeArea(
          child: ListView(
            children: [
              drawerTitleLine(
                text: "OneMrOliver",
                onTap: () {},
              ),
              ...firstGroup(),
              Container(
                color: ResColor.divideColor,
                margin: const EdgeInsets.only(left: 20, right: 20),
                height: 1,
                width: double.infinity,
              ),
              ...secondGroup(),
              Container(
                color: ResColor.divideColor,
                margin: const EdgeInsets.only(left: 20, right: 20),
                height: 1,
                width: double.infinity,
              ),
              ...thirdGroup(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> firstGroup() {
    return [
      drawerButtonLine(
        icon: const Icon(Icons.home_outlined),
        text: "主页",
        onTap: () {
          widget.onItemTap(DrawerBtn.home);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.star_border_outlined),
        text: "收藏",
        onTap: () {
          widget.onItemTap(DrawerBtn.favourites);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.local_library_outlined),
        text: "我的文库",
        onTap: () {
          widget.onItemTap(DrawerBtn.library);
        },
      ),
    ];
  }

  List<Widget> secondGroup() {
    return widget.collections.map((item)  =>
        drawerButtonLine(icon: const Icon(Icons.folder_outlined),
            text: item.name,
            onTap: (){
              widget.onCollectionTap(item);
            })
    ).toList();

  }

  List<Widget> thirdGroup() {
    return [
      drawerButtonLine(
        icon: const Icon(Icons.newspaper),
        text: "未分类条目",
        onTap: () {
          widget.onItemTap(DrawerBtn.unfiled);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.book_outlined),
        text: "我的出版物",
        onTap: () {
          widget.onItemTap(DrawerBtn.publications);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.restore_from_trash),
        text: "回收站",
        onTap: () {
          widget.onItemTap(DrawerBtn.trash);
        },
      ),
    ];
  }

  Widget drawerButtonLine({
    required Widget icon,
    required String text,
    required Function onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Material(
        child: Ink(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectDrawerTitle = text;
              });
              print(_selectDrawerTitle);
              onTap();
            },
            child: Container(
              color: _selectDrawerTitle == text
                  ? ResColor.selectedBgColor
                  : ResColor.bgColor,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: _selectDrawerTitle == text
                            ? ResColor.selectedTextColor
                            : ResColor.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget drawerTitleLine({
    required String text,
    required Function onTap,
  }) {
    return Card(
      elevation: 0,
      color: ResColor.bgColor,
      child: InkWell(
        onTap: () {
          _jumpToAccountSetting();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          child:Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  "assets/ic_round.png",
                  package: 'module_library',
                  width: 40,
                  height: 40,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              IconButton(
                onPressed: () {
                  _jumpToSettings();
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return pageDrawer(context);
  }

  void _jumpToSettings() {
    MyRouter.instance.pushNamed(context, "settingsPage");
  }

  void _jumpToAccountSetting() {
    MyRouter.instance.pushNamed(context, "settingsPage", arguments: {"initTab": 'account'});
  }
}    