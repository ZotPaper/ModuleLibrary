import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module/LibZoteroStorage/entity/Collection.dart';
import 'package:module/ModuleLibrary/model/page_type.dart';
import 'package:module/ModuleLibrary/page/blank_page.dart';
import 'package:module/ModuleLibrary/page/sync_page/sync_page.dart';
import 'package:module/ModuleLibrary/res/ResColor.dart';
import 'package:module/ModuleLibrary/viewmodels/library_viewmodel.dart';

import '../../LibZoteroApi/ZoteroAPIService.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import 'LibraryUI/appBar.dart';
import 'LibraryUI/drawer.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final LibraryViewModel _viewModel = LibraryViewModel();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    // WidgetsBinding.instance.addPostFrameCallback((_) => _handleNavigation());
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: ResColor.bgColor,
          key: _scaffoldKey,
          drawerEnableOpenDragGesture: false,
          drawer: CustomDrawer(
            collections: _viewModel.collections,
            onItemTap: _viewModel.handleDrawerItemTap,
            onCollectionTap: (collection) {}, // 如果有需要再实现
          ),
          appBar: pageAppBar(
            leadingIconTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            filterMenuTap: () {},
            tagsTap: () {},
          ),
          body: StreamBuilder<PageType>(
            stream: _viewModel.curPageStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const BlankPage();
              }

              debugPrint("收到页面切换：pageType：${snapshot.data}");

              if (snapshot.data == PageType.sync) {
                return const SyncPageFragment();
              } else if (snapshot.data == PageType.library) {
                return libraryListPage();
              } else {
                return const BlankPage();
              }

            },
          ),
        );
      }
    );
  }

  /// 文库列表页面
  Widget libraryListPage() {
    return Column(
      children: [
        searchLine(),
        Expanded(
          child: Container(
            color: ResColor.bgColor,
            width: double.infinity,
            child: StreamBuilder<List<Item>>(
              stream: _viewModel.showItemsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const BlankPage();
                }
                return ListView.builder(
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return fileOneLine(item);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget searchLine() {
    return Container(
      color: ResColor.bgColor,
      height: 48,
      width: double.infinity,
      child: Row(
        children: [
          Container(width: 20),
          const Icon(Icons.search),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search as you type',
                border: InputBorder.none,
              ),
            ),
          ),
          Container(width: 20),
        ],
      ),
    );
  }

  /// 文件
  Widget fileOneLine(Item item) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset("assets/ic_round.png", width: 40, height: 40),
          ),
          Container(width: 5),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: Text(item.getTitle(), maxLines: 2),
                ),
                Container(
                  width: double.infinity,
                  child: Text(
                    item.getAuthor(),
                    maxLines: 1,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Material(
            child: Ink(
              child: InkWell(
                onTap: () {
                  print("pdf tap");
                },
                child: Container(
                  color: ResColor.bgColor,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      "assets/pdf.png",
                      width: 20,
                      height: 20,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
    );
  }

  // _handleNavigation() {
  //   // 监听 ViewModel 中的页面跳转指令
  //   final vm = Provider.of<LibraryViewModel>(context, listen: false);
  //   final pageData = vm.curPage;
  //   String routeName;
  // }
}
