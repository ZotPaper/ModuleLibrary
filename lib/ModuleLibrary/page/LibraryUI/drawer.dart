import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../res/ResColor.dart';

typedef DrawerItemTapCallback = void Function(DrawerBtn DrawerBtn);

class CustomDrawer extends StatefulWidget {
  final DrawerItemTapCallback onItemTap;

  const CustomDrawer({super.key, required this.onItemTap});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}
enum DrawerBtn {
  home,
  favourites,
  library,
  firstLevel,
  variousTypes,
  thirdLevel,
  attachment,
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
                height: 2,
                width: double.infinity,
              ),
              ...secondGroup(),
              Container(
                color: ResColor.divideColor,
                height: 2,
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
        text: "Home",
        onTap: () {
          widget.onItemTap(DrawerBtn.home);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.collections),
        text: "Favourites",
        onTap: () {
          widget.onItemTap(DrawerBtn.favourites);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.library_books),
        text: "My Library",
        onTap: () {
          widget.onItemTap(DrawerBtn.library);
        },
      ),
    ];
  }

  List<Widget> secondGroup() {
    return [
      drawerButtonLine(
        icon: const Icon(Icons.folder_open_rounded),
        text: "一级分类",
        onTap: () {
          widget.onItemTap(DrawerBtn.firstLevel);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.folder_open_rounded),
        text: "各种类型条目",
        onTap: () {
          widget.onItemTap(DrawerBtn.variousTypes);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.folder_open_rounded),
        text: "纯附件内容",
        onTap: () {
          widget.onItemTap(DrawerBtn.attachment);
        },
      ),
    ];
  }

  List<Widget> thirdGroup() {
    return [
      drawerButtonLine(
        icon: const Icon(Icons.newspaper),
        text: "Unfiled Items",
        onTap: () {
          widget.onItemTap(DrawerBtn.unfiled);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.book_outlined),
        text: "My Publications",
        onTap: () {
          widget.onItemTap(DrawerBtn.publications);
        },
      ),
      drawerButtonLine(
        icon: const Icon(Icons.restore_from_trash),
        text: "Trash",
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
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Material(
        child: Ink(
          child: InkWell(
            onTap: () {
              onTap();
            },
            child: Container(
              color: ResColor.bgColor,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/ic_round.png",
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(text)),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return pageDrawer(context);
  }
}    