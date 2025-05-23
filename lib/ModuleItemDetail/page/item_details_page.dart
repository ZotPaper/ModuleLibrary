import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module/ModuleItemDetail/page/item_detail_basic_fragment.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import 'package:bruno/bruno.dart';

class ItemDetailsPage extends StatefulWidget {

  final Item item;
  const ItemDetailsPage(this.item, {super.key});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> with SingleTickerProviderStateMixin {
  GlobalKey globalKey = GlobalKey();

  BrnCloseWindowController? closeWindowController;

  var tabs = <BadgeTab>[];
  late TabController tabController;

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    closeWindowController = BrnCloseWindowController();
    tabs.add(BadgeTab(text: "基本"));
    tabs.add(BadgeTab(text: "标签"));
    tabs.add(BadgeTab(text: "笔记"));
    tabs.add(BadgeTab(text: "附件"));
    tabController = TabController(length: tabs.length, vsync: this);

    scrollController.addListener(() {
      closeWindowController!.closeMoreWindow();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: BrnAppBar(
            title: '条目详情',
          ),
          body: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverOverlapAbsorber(
                  handle:
                  NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverPersistentHeader(
                    pinned: false,
                    delegate: StickyTabBarDelegate(
                        child: BrnTabBar(
                          controller: tabController,
                          tabs: tabs,
                          // showMore: true,
                          moreWindowText: "Tabs描述",
                          onTap: (state, index) {
                            state.refreshBadgeState(index);
                            scrollController.animateTo(
                                globalKey.currentContext!.size!.height,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.linear);
                          },
                          onMorePop: () {},
                          closeController: closeWindowController,
                        )),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: tabController,
              children: <Widget>[
                ItemDetailBasicFragment(widget.item),
                Center(child: Text('标签')),
                Center(child: Text('笔记')),
                Center(child: Text('附件')),
              ],
            ),
          ),
        ),
        onWillPop: () {
          if (closeWindowController!.isShow) {
            closeWindowController!.closeMoreWindow();
            return Future.value(false);
          }
          return Future.value(true);
        });
  }

}

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final BrnTabBar child;

  StickyTabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) {
    return this.child;
  }

  @override
  double get maxExtent => this.child.tabHeight ?? 50;

  @override
  double get minExtent => this.child.tabHeight ?? 50;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

