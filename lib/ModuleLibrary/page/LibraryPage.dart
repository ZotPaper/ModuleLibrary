import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import 'package:module_library/LibZoteroStorage/database/dao/RecentlyOpenedAttachmentDao.dart';

import 'package:module_library/ModuleItemDetail/page/item_details_page.dart';
import 'package:module_library/ModuleLibrary/model/list_entry.dart';
import 'package:module_library/ModuleLibrary/model/page_type.dart';
import 'package:module_library/ModuleLibrary/page/blank_page.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_page.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';
import 'package:module_library/ModuleLibrary/utils/sheet_item_helper.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/ModuleTagManager/item_tagmanager.dart';
import 'package:module_library/routers.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../dialog/library_layout_dialog.dart';
import '../utils/color_utils.dart';
import '../utils/device_utils.dart';
import '../widget/global_download_indicator.dart';
import '../widget/attachment_indicator.dart';
import '../widget/item_entry_widget.dart';
import '../widget/collection_entry_widget.dart';
import '../widget/item_type_icon.dart';
import '../widget/bottomsheet/item_operation_panel.dart';
import 'LibraryUI/appBar.dart';
import 'LibraryUI/drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bruno/bruno.dart';
import 'package:flutter/foundation.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with WidgetsBindingObserver, RouteAware {
  late LibraryViewModel _viewModel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  BrnSearchTextController searchController = BrnSearchTextController();
  TextEditingController textController = TextEditingController();

  final focusNode = FocusNode();

  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  // RouteObserver for navigation detection
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ///initState 中添加监听，记得销毁
    textController.addListener((){
      if(focusNode.hasFocus){
        if(textController.text.isNotEmpty) {
          searchController.isClearShow = true;
          searchController.isActionShow = true;
        }
      }
    });

    focusNode.addListener((){
      if(focusNode.hasFocus){
        if(textController.text.isNotEmpty) {
          searchController.isClearShow = true;
        }
      }
    });
  }


  @override
  void didChangeDependencies() { 
    super.didChangeDependencies();

    // 在这里通过 Provider 获取 ViewModel
    _viewModel = Provider.of<LibraryViewModel>(context, listen: false);

    // 设置修改附件发现回调
    _viewModel.setOnModifiedAttachmentsFoundCallback(_onModifiedAttachmentsFound);

    // 第一次进入页面时初始化数据
    if (!_viewModel.initialized) {
      _viewModel.init();
    }

    // 注册路由观察者
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  /// 当发现修改的附件时的回调处理
  void _onModifiedAttachmentsFound(List<Item> modifiedItems, List<RecentlyOpenedAttachment> attachments) {
    _showModifiedAttachmentsDialog(modifiedItems, attachments);
  }

  /// 显示修改的附件对话框
  void _showModifiedAttachmentsDialog(List<Item> modifiedItems, List<RecentlyOpenedAttachment> attachments) {
    final strModified = modifiedItems.map((item) => "\<font color = '#8ac6d1'\>${ item.getTitle()}</font>" ).join(', ');

    BrnDialogManager.showConfirmDialog(context,
        cancel: "稍后处理",
        confirm: "立即上传",
        title: "检测到附件修改",
        message: "检测到 ${modifiedItems.length} 个附件已被修改，是否需要上传到Zotero服务器？",
        messageWidget: Padding(
          padding: const EdgeInsets.only(top: 6, left: 24, right: 24),
          child: BrnCSS2Text.toTextView(
              "检测到 ${modifiedItems.length} 个附件已被修改，是否需要上传到服务器进行更新？\n" +
                  "修改的附件：\n $strModified"
            ,
        ),),
        showIcon: true,
        onConfirm: () {
          // Navigator.of(context).pop();
          // 开始上传修改的附件
          _startUploadModifiedAttachments(modifiedItems, attachments);
        },
        onCancel: () {
          // Navigator.of(context).pop();
          // 清除修改标记，用户选择不上传
          _viewModel.clearModifiedAttachmentsMarks(attachments);
        },
    );
  }

  /// 开始上传修改的附件
  Future<void> _startUploadModifiedAttachments(List<Item> modifiedItems, List<RecentlyOpenedAttachment> attachments) async {
    try {
      // 调用ViewModel的上传方法
      final result = await _viewModel.uploadModifiedAttachments(modifiedItems, attachments);
      
      // 根据结果显示相应的提示
      if (result.hasError) {
        BrnToast.show('上传失败：${result.error}', context);
      } else if (result.isAllSuccessful) {
        BrnToast.show('所有附件上传成功！', context);
      } else if (result.successCount > 0) {
        BrnToast.show('${result.successCount}/${result.totalCount} 个附件上传成功', context);
      } else {
        BrnToast.show('附件上传失败，请检查网络连接', context);
      }

    } catch (e) {
      MyLogger.e('上传附件时发生错误: $e');
      BrnToast.show('上传失败：$e', context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用从后台返回前台时检查修改的附件
      _viewModel.checkModifiedAttachments();
    }
  }

  @override
  void didPopNext() {
    // 从其他页面返回时检查修改的附件
    super.didPopNext();
    _viewModel.checkModifiedAttachments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    textController.dispose();
    focusNode.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = DeviceUtils.shouldShowFixedDrawer(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) {
        if (didPop) {
          return;
        }
        // 如果不允许默认 pop，则在这里自定义处理（可选）
        // 例如：显示提示框或执行其他操作
        // _viewModel.backToPreviousPage();

        // 当用户尝试返回时（包括物理返回键和侧滑返回）
        if (_viewModel.viewStack.isNotEmpty) {
          // 如果栈不为空，先执行自定义返回逻辑
          _viewModel.backToPreviousPos();
        } else {
          // 栈为空时，允许返回
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // 如果栈为空且无法返回，则退出app
            SystemNavigator.pop();
          }
        }
      },
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, snapshot) {
          if (isTablet) {
            // 平板布局：固定侧边栏 + 主内容区
            return _buildTabletLayout();
          } else {
            // 手机布局：传统Scaffold + Drawer
            return _buildPhoneLayout();
          }
        }
      ),
    );
  }

  /// 手机布局：传统Scaffold + Drawer
  Widget _buildPhoneLayout() {
    return Scaffold(
      backgroundColor: ResColor.bgColor,
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawer: CustomDrawer(
        collections: _viewModel.displayedCollections,
        onItemTap: _viewModel.handleDrawerItemTap,
        onCollectionTap: (collection) {
          _viewModel.handleCollectionTap(collection);
        },
      ),
      appBar: _buildAppBar(showMenuButton: true),
      body: _viewModel.isLoading
          ? _buildLoadingContent()
          : _buildPageContent(),
    );
  }

  /// 平板布局：固定侧边栏 + 主内容区
  Widget _buildTabletLayout() {
    final drawerWidth = DeviceUtils.getDrawerWidth(context);
    
    return Scaffold(
      backgroundColor: ResColor.bgColor,
      body: Row(
        children: [
          // 固定侧边栏
          SizedBox(
            width: drawerWidth,
            child: DrawerContent(
              collections: _viewModel.displayedCollections,
              onItemTap: _viewModel.handleDrawerItemTap,
              onCollectionTap: (collection) {
                _viewModel.handleCollectionTap(collection);
              },
              isFixed: true,
            ),
          ),
          // 主内容区
          Expanded(
            child: Column(
              children: [
                _buildAppBar(showMenuButton: false),
                Expanded(
                  child: _viewModel.isLoading
                      ? _buildLoadingContent()
                      : _buildPageContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({bool showMenuButton = true}) {
    return pageAppBar(
      title: _viewModel.title,
      leadingIconTap: showMenuButton ? () {
        _scaffoldKey.currentState?.openDrawer();
      } : null,
      filterMenuTap: () {
        _showFilterMenuDialog();
      },
      tagsTap: () {
        _navigationTagManager();
      },
    );
  }


  Widget _buildPageContent() {
    if (_viewModel.curPage == PageType.sync) {
      return const SyncPageFragment();
    } else if (_viewModel.curPage == PageType.library) {
      return Stack(
        children: [
          libraryListPage(),
          // 全局下载进度指示器
          _buildGlobalDownloadIndicator(),
        ],
      );
    } else {
      return _emptyView();
    }
  }

  /// 构建全局下载进度指示器
  Widget _buildGlobalDownloadIndicator() {
    return GlobalDownloadIndicator(
      viewModel: _viewModel,
    );
  }

  /// 文库列表页面
  Widget libraryListPage() {
    return GestureDetector(
      onTap: () {
        // 移除焦点
        FocusScope.of(context).unfocus();
        focusNode.unfocus();
      },
      behavior: HitTestBehavior.opaque, // 确保整个区域都能响应点击
      child: Column(
        children: [
          searchLine(),
          Expanded(
            child: _viewModel.displayEntries.isEmpty ? _emptyView() : Container(
              color: ResColor.bgColor,
              width: double.infinity,
              child: SmartRefresher(
                enablePullDown: true,
                controller: _refreshController,
                header: _refreshHeader(),
                onRefresh: _onRefresh,
                child: ListView.builder(
                  itemCount: _viewModel.displayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _viewModel.displayEntries[index];
                    return widgetListEntry(entry);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget searchLine() {
    return BrnSearchText(
      focusNode: focusNode,
      controller: textController,
      // searchController: scontroller..isActionShow = true,
      onTextClear: () {
        return false;
      },
      autoFocus: false,
      onActionTap: () {
        // scontroller.isClearShow = false;
        // scontroller.isActionShow = false;
        focusNode.unfocus();
        // BrnToast.show('取消', context);
      },
      onTextCommit: (text) {
        _viewModel.setFilterText(text);
      },
      onTextChange: (text) {
        _viewModel.setFilterText(text);
        // BrnToast.show('输入内容 : $text', context);
      },
    );
  }

  /// 条目列表
  Widget widgetListEntry(ListEntry entry) {
    return Card(
      elevation: 0,
      color: ResColor.bgColor,
      child: entry.isItem() 
        ? ItemEntryWidget(
            item: entry.item!,
            viewModel: _viewModel,
            onTap: () {
              debugPrint("Moyear==== item click");
              _showItemInfo(context, entry.item!);
            },
            onMorePressed: () {
              ItemOperationPanel.show(
                context: context,
                item: entry.item!,
                viewModel: _viewModel,
              );
            },
            onPdfTap: () {
              try {
                _viewModel.openOrDownloadedPdf(context, entry.item!);
              } catch (e) {
                debugPrint("pdf tap error: $e");
                BrnToast.show("$e", context);
              }
            },
          )
        : CollectionEntryWidget(
            collection: entry.collection!,
            viewModel: _viewModel,
            onTap: () {
              debugPrint("Moyear==== collection click");
              _viewModel.handleCollectionTap(entry.collection!);
            },
            onMorePressed: () {
              _showCollectionEntryOperatePanel(context, entry.collection!);
            },
          ),
    );
  }

  /// 下拉刷新 Header
  Widget _refreshHeader() {
    return Consumer<LibraryViewModel>(
      builder: (context, viewModel, child) {
        return WaterDropHeader(
          refresh: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                  width: 25.0,
                  height: 25.0,
                  child: CupertinoActivityIndicator()
              ),
              const SizedBox(width: 10,),
              Text((viewModel.syncProgress == null) ? "正在同步..." : "正在同步: ${viewModel.syncProgress!.progress}/${viewModel.syncProgress!.total}.", style: TextStyle(fontSize: 12, color: Colors.grey))
            ],
          ),
          complete: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.done,
                color: Colors.grey,
              ),
              SizedBox(width: 10,),
              Text("同步完成", style: TextStyle(fontSize: 12, color: Colors.grey))
            ],
          ),
        );
      },
    );
  }

  /// 显示合集操作面板
  void _showCollectionEntryOperatePanel(BuildContext context, Collection collection) {
    List<ItemClickProxy> itemClickProxies = [];

    bool isStared = _viewModel.isCollectionStarred(collection);
    if (isStared) {
      itemClickProxies.add(ItemClickProxy(
        title: "从收藏夹中移除",
        actionStyle: 'alert',
        onClick: () {
          _viewModel.removeStar(collection: collection);
        },
      ));
    } else {
      itemClickProxies.add(ItemClickProxy(
        title: "添加到收藏夹",
        onClick: () {
          _viewModel.addToStar(collection);
        },
      ));
    }

    itemClickProxies.add(ItemClickProxy(
      title: "更改所属集合",
      onClick: () {
        Future.delayed(const Duration(milliseconds: 200), () {
          _viewModel.showChangeCollectionSelector(context, collection: collection);
        });
      },
    ));

    List<BrnCommonActionSheetItem> itemActions = itemClickProxies.map((ele) {
      var actionStyle = BrnCommonActionSheetItemStyle.normal;
      if (ele.actionStyle != null && ele.actionStyle == "alert") {
        actionStyle = BrnCommonActionSheetItemStyle.alert;
      }
      return BrnCommonActionSheetItem(
        ele.title,
        desc: ele.desc,
        actionStyle: actionStyle,
      );
    }).toList();

    var title = collection.name;

    // 展示actionSheet
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return BrnCommonActionSheet(
            title: title,
            actions: itemActions,
            cancelTitle: "取消",
            clickCallBack: (int index, BrnCommonActionSheetItem actionEle) {
              itemClickProxies[index].onClick?.call();
            },
          );
        });
  }

  void _showItemInfo(BuildContext context, Item item) {
    // BrnToast.show("item: ${item.getTitle()}", context);
    // 跳转到详情页
    try {
      MyRouter.instance.pushNamed(context, "itemDetailPage", arguments: { "item": item });
    } catch (e) {
      debugPrint(e.toString());
      BrnToast.show("跳转详情页失败", context);
    }
  }

  void _navigationTagManager() {
    MyRouter.instance.pushNamed(context, "tagsManagerPage");
  }

  void _onRefresh() async{
    // 开始与服务器同步
    _viewModel.startSync(onSyncCompleteCallback: () {
      // 关闭刷新动画
      _refreshController.refreshCompleted();
    });
  }

  Widget _emptyView() {
    return Center(child:
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 240),
            child: Image.asset(
              "assets/content_failed.png",
              package: "module_library",
              fit: BoxFit.contain,
            )
        ),
        const SizedBox(height: 18,),
        const Text('暂无数据'),
      ],
    )
    );
  }

  // 显示删除条目确认框
  void _showTrashItemConfirmDialog(BuildContext ctx, Item item) {
    BrnDialogManager.showConfirmDialog(context,
      cancel: "取消",
      confirm: "确定",
      title: "移动到回收站",
      messageWidget: Padding(
        padding: const EdgeInsets.only(top: 6, left: 24, right: 24),
        child: BrnCSS2Text.toTextView(
            "是否将条目\<font color = '#8ac6d1'\>${item.getTitle()}</font>"
                "移动到回收站？"),
      ),
      showIcon: true,
      onConfirm: () {
        _viewModel.moveItemToTrash(context, item);
        Navigator.of(ctx).pop();
      },
      onCancel: () {
        Navigator.of(ctx).pop();
      },
    );
  }

  Widget _buildLoadingContent() {
    return Center(
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
            Text("正在加载本地数据中...", style: TextStyle(fontSize: 14, color: ResColor.textMain)),
            const SizedBox(height: 12,),
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: ResColor.textMain,
                strokeWidth: 2,
              ),
            ),
          ],
        ));
    // return const Center(child: CircularProgressIndicator());
  }

  void _showFilterMenuDialog() {
    showDialog(context: context,
        builder: (BuildContext context) {
      return LibraryLayoutDialog();
    });
  }

}
