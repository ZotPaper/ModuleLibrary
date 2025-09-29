import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';

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

class _LibraryPageState extends State<LibraryPage> with WidgetsBindingObserver {
  late LibraryViewModel _viewModel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  BrnSearchTextController searchController = BrnSearchTextController();
  TextEditingController textController = TextEditingController();

  final focusNode = FocusNode();

  final RefreshController _refreshController = RefreshController(initialRefresh: false);

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

    // 第一次进入页面时初始化数据
    if (!_viewModel.initialized) {
      _viewModel.init();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 页面回到前台时执行的操作
      _viewModel.checkModifiedAttachments(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      return libraryListPage();
    } else {
      return _emptyView();
    }
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
      child: InkWell(
        onTap: () {
          debugPrint("Moyear==== item click");

          if (entry.isCollection()) {
            _viewModel.handleCollectionTap(entry.collection!);
          } else if (entry.isItem()) {
            _showItemInfo(context, entry.item!);
          }

        },
        child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          child: entry.isItem() ? _widgetItemEntry(entry.item!) : _widgetCollectionEntry(entry.collection!)
        ),
      ),
    );
  }
  
  /// 条目的列表widget
  Widget _widgetItemEntry(Item item)  {
    return Row(
      children: [
        _entryIcon(ListEntry(item: item)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                child: Text(item.getTitle(), maxLines: 2, style: TextStyle(color: ResColor.textMain),),
              ),
              Container(
                width: double.infinity,
                child: Text(
                  item.getAuthor(),
                  maxLines: 1,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
              _itemImportantTags(item),
            ],
          ),
        ),
        if (_hasPdfAttachment(item)) _attachmentIndicator(item),
        IconButton(onPressed: () {
          _showItemEntryOperatePanel(context, item);
        }, icon: Icon(Icons.more_vert_sharp, color: Colors.grey.shade400, size: 20,)),
      ],
    );
  }

  /// 条目是否有pdf附件
  bool _hasPdfAttachment(Item item) {
    return _viewModel.itemHasPdfAttachment(item);
  }
  
  Widget _widgetCollectionEntry(Collection collection)  {
    int sizeSub = _viewModel.getNumInCollection(collection);

    return Row(
      children: [
        _entryIcon(ListEntry(collection: collection)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(collection.name, maxLines: 2, style: TextStyle(color: ResColor.textMain)),
              ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  "$sizeSub条子项",
                  maxLines: 1,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
        IconButton(onPressed: () {
          _showCollectionEntryOperatePanel(context, collection);
        }, icon: Icon(Icons.more_vert_sharp, color: Colors.grey.shade400, size: 20,)),
      ],
    );
  }

  /// Icon Widget
  Widget _iconItemWidget(ListEntry entry) {
    if (entry.isCollection()) {
      return SvgPicture.asset(
        'assets/items/opened_folder.svg',
        package: 'module_library',
        width: 16,
        height: 16,
        // color: Colors.blue, // 可选颜色
      );
    }

    return requireItemIcon(entry.item?.itemType ?? "");
  }

  /// Entry Icon Widget
  Widget _entryIcon(ListEntry entry) {
    return Container(
      height: 42,
      width: 42,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(26),
      ),
      child: _iconItemWidget(entry),
    );
  }

  Widget _attachmentIndicator(Item item) {
    return _AttachmentIndicatorWidget(
      item: item,
      viewModel: _viewModel,
      onTap: () {
        try {
          _viewModel.openOrDownloadedPdf(context, item);
        } catch (e) {
          debugPrint("pdf tap error: $e");
          BrnToast.show("$e", context);
        }
      },
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

  Widget requireItemIcon(String itemType) {
    String iconPath;
    // Assign SVG icon path based on itemType
    switch (itemType) {
      case "note":
        iconPath = 'assets/items/ic_item_note.svg';
        break;
      case "book":
        iconPath = 'assets/items/ic_book.svg';
        break;
      case "bookSection":
        iconPath = 'assets/items/ic_book_section.svg';
        break;
      case "journalArticle":
        iconPath = 'assets/items/journal_article.svg';
        break;
      case "magazineArticle":
        iconPath = 'assets/items/magazine_article_24dp.svg';
        break;
      case "newspaperArticle":
        iconPath = 'assets/items/newspaper_article_24dp.svg';
        break;
      case "thesis":
        iconPath = 'assets/items/ic_thesis.svg';
        break;
      case "letter":
        iconPath = 'assets/items/letter_24dp.svg';
        break;
      case "manuscript":
        iconPath = 'assets/items/manuscript_24dp.svg';
        break;
      case "interview":
        iconPath = 'assets/items/interview_24dp.svg';
        break;
      case "film":
        iconPath = 'assets/items/film_24dp.svg';
        break;
      case "artwork":
        iconPath = 'assets/items/artwork_24dp.svg';
        break;
      case "webpage":
        iconPath = 'assets/items/ic_web_page.svg';
        break;
      case "attachment":
        iconPath = 'assets/items/ic_treeitem_attachment.svg';
        break;
      case "report":
        iconPath = 'assets/items/report_24dp.svg';
        break;
      case "bill":
        iconPath = 'assets/items/bill_24dp.svg';
        break;
      case "case":
        iconPath = 'assets/items/case_24dp.svg';
        break;
      case "hearing":
        iconPath = 'assets/items/hearing_24dp.svg';
        break;
      case "patent":
        iconPath = 'assets/items/patent_24dp.svg';
        break;
      case "statute":
        iconPath = 'assets/items/statute_24dp.svg';
        break;
      case "email":
        iconPath = 'assets/items/email_24dp.svg';
        break;
      case "map":
        iconPath = 'assets/items/map_24dp.svg';
        break;
      case "blogPost":
        iconPath = 'assets/items/blog_post_24dp.svg';
        break;
      case "instantMessage":
        iconPath = 'assets/items/instant_message_24dp.svg';
        break;
      case "forumPost":
        iconPath = 'assets/items/forum_post_24dp.svg';
        break;
      case "audioRecording":
        iconPath = 'assets/items/audio_recording_24dp.svg';
        break;
      case "presentation":
        iconPath = 'assets/items/presentation_24dp.svg';
        break;
      case "videoRecording":
        iconPath = 'assets/items/video_recording_24dp.svg';
        break;
      case "tvBroadcast":
        iconPath = 'assets/items/tv_broadcast_24dp.svg';
        break;
      case "radioBroadcast":
        iconPath = 'assets/items/radio_broadcast_24dp.svg';
        break;
      case "podcast":
        iconPath = 'assets/items/podcast_24dp.svg';
        break;
      case "computerProgram":
        iconPath = 'assets/items/computer_program_24dp.svg';
        break;
      case "conferencePaper":
        iconPath = 'assets/items/ic_conference_paper.svg';
        break;
      case "document":
        iconPath = 'assets/items/ic_document.svg';
        break;
      case "encyclopediaArticle":
        iconPath = 'assets/items/encyclopedia_article_24dp.svg';
        break;
      case "dictionaryEntry":
        iconPath = 'assets/items/dictionary_entry_24dp.svg';
        break;
      default:
        iconPath = 'assets/items/ic_item_known.svg';
    }

    // Return the appropriate SVG image
    return SvgPicture.asset(
      iconPath,
      height: 14,
      width: 14,
      package: 'module_library',
      colorFilter: ColorFilter.mode(ResColor.textMain, BlendMode.srcIn),
    );
  }

  /// 显示条目操作面板
  void _showItemEntryOperatePanel(BuildContext ctx, Item item) {
    List<ItemClickProxy> itemClickProxies = [];
    itemClickProxies.add(ItemClickProxy(
      title: "在线查看",
      desc: "在线查看条目的最新信息",
      onClick: () {
        _viewModel.viewItemOnline(context, item);
      },
    ));

    bool isStared = _viewModel.isItemStarred(item);
    if (isStared) {
      itemClickProxies.add(ItemClickProxy(
        title: "从收藏夹中移除",
        desc: "从收藏夹中移除该条目",
        actionStyle: "alert",
        onClick: () {
          _viewModel.removeStar(item: item);
        },
      ));
    } else {
      itemClickProxies.add(ItemClickProxy(
        title: "添加到收藏",
        onClick: () {
          _viewModel.addToStaredItem(item);
        },
      ));
    }

    bool isItemDeleted = _viewModel.isItemDeleted(item);
    if (isItemDeleted) {
      itemClickProxies.add(ItemClickProxy(
        title: "还原到文献库中",
        onClick: () {
          _viewModel.restoreItem(ctx, item);
        },
      ));
    } else {
      itemClickProxies.add(ItemClickProxy(
        title: "移动到回收站",
        actionStyle: "alert",
        onClick: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            _viewModel.moveItemToTrash(ctx, item);
          });
        },
      ));
    }

    if (item.hasAttachments()) {
      itemClickProxies.add(ItemClickProxy(
        title: "删除已下载的附件",
        actionStyle: "alert",
        onClick: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            BrnDialogManager.showConfirmDialog(context,
                // showIcon: true,
                // iconWidget: Image.asset(
                //   "images/icon_warnning.png",
                //   package: "bruno",
                // ),
                title: "删除下载的附件",
                confirm: "确定",
                cancel: "取消",
                message: "是否删除《${item.getTitle()}》中已下载的附件",
                                 onConfirm: () async {
                   Navigator.of(ctx).pop();
                   await _viewModel.deleteAllDownloadedAttachmentsOfItems(
                       context,
                       item,
                       onCallback: () {
                         // 删除完成后的回调，可以在这里添加额外的逻辑
                         MyLogger.d('所有附件删除操作完成');
                       });
                 },
                onCancel: () {
                  Navigator.of(ctx).pop();
                });
          });
        },
      ));
    }

    if (!isItemDeleted) {
      itemClickProxies.add(ItemClickProxy(
        title: "更改所属集合",
        onClick: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            _viewModel.showChangeCollectionSelector(ctx, item: item);
          });
        },
      ));
    }

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



    // itemActions.add(BrnCommonActionSheetItem(
    //   '下载所有附件',
    //   desc: '下载条目下的所有附件到本地',
    //   actionStyle: BrnCommonActionSheetItemStyle.normal,
    // ));
    // itemActions.add(BrnCommonActionSheetItem(
    //   '删除下载的附件',
    //   desc: '该操作不可逆，请确保本地的附件修改同步至云端',
    //   actionStyle: BrnCommonActionSheetItemStyle.alert,
    // ));
    // itemActions.add(BrnCommonActionSheetItem(
    //   '分享条目',
    //   // desc: '分享条目信息给朋友',
    //   actionStyle: BrnCommonActionSheetItemStyle.normal,
    // ));

    var title = item.getTitle();

    // 展示actionSheet
    showModalBottomSheet(
        context: ctx,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (BuildContext bottomSheetContext) {
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

  Widget _itemImportantTags(Item item) {
    if (item.getTagList().isEmpty) {
      return Container();
    }

    // 获取item的标签
    final tags =  _viewModel.getImportTagOfItemSync(item);
    return Row(
        children: tags.map<Widget>((tag) {
      return Container(
        margin: const EdgeInsets.only(right: 2),
        child: BrnTagCustom(
          tagText: tag.name,

          textColor: ColorUtils.hexToColor(tag.color),
          backgroundColor: const Color(0xFFF1F2FA),
        ),
      );
    }).toList(),);
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

/// 自定义的附件指示器Widget，避免不必要的重建
class _AttachmentIndicatorWidget extends StatefulWidget {
  final Item item;
  final LibraryViewModel viewModel;
  final VoidCallback onTap;

  const _AttachmentIndicatorWidget({
    required this.item,
    required this.viewModel,
    required this.onTap,
  });

  @override
  State<_AttachmentIndicatorWidget> createState() => _AttachmentIndicatorWidgetState();
}

class _AttachmentIndicatorWidgetState extends State<_AttachmentIndicatorWidget> {
  Item? targetPdfAttachmentItem;
  String? targetItemKey;
  AttachmentDownloadInfo? lastDownloadInfo;
  bool? lastFileExists;

  @override
  void initState() {
    super.initState();
    _findTargetPdfAttachment();
  }

  void _findTargetPdfAttachment() {
    if (widget.viewModel.isPdfAttachmentItem(widget.item)) {
      targetPdfAttachmentItem = widget.item;
    } else if (widget.viewModel.itemHasPdfAttachment(widget.item)) {
      targetPdfAttachmentItem = widget.item.attachments.firstWhere(
        (element) => widget.viewModel.isPdfAttachmentItem(element),
      );
    }
    targetItemKey = targetPdfAttachmentItem?.itemKey;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        // 只有当这个特定项目的状态改变时才重建
        final currentDownloadInfo = targetItemKey != null 
            ? widget.viewModel.getDownloadStatus(targetItemKey!)
            : null;
        final currentFileExists = targetItemKey != null
            ? widget.viewModel.getCachedFileExists(targetItemKey!)
            : null;

        // 检查是否需要重建
        final needsRebuild = currentDownloadInfo != lastDownloadInfo || 
                           currentFileExists != lastFileExists;

        if (needsRebuild) {
          lastDownloadInfo = currentDownloadInfo;
          lastFileExists = currentFileExists;
        }

        return InkWell(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: _buildAttachmentIcon(currentDownloadInfo, targetPdfAttachmentItem),
          ),
        );
      },
    );
  }

  /// 根据下载状态构建附件图标
  Widget _buildAttachmentIcon(AttachmentDownloadInfo? downloadInfo, Item? targetPdfAttachmentItem) {
    // if (kDebugMode) {
    //   print('构建附件图标: ${downloadInfo?.itemKey} - ${downloadInfo?.status} - ${downloadInfo?.progressPercent}%');
    // }

    if (downloadInfo == null) {
      // 没有下载状态时，检查缓存的文件存在状态
      if (targetPdfAttachmentItem != null) {
        final itemKey = targetPdfAttachmentItem.itemKey;
        final cachedExists = widget.viewModel.getCachedFileExists(itemKey);
        
        if (cachedExists != null) {
          // 有缓存值，直接使用
          return cachedExists ? _buildDownloadedIndicator() : _buildNotDownloadedIndicator();
        } else {
          // 没有缓存值，使用FutureBuilder检查一次并缓存
          return FutureBuilder<bool>(
            future: widget.viewModel.checkAndCacheFileExists(targetPdfAttachmentItem),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // 正在检查文件状态，显示默认图标
                return _buildDefaultIndicator();
              }
              
              final isDownloaded = snapshot.data ?? false;
              return isDownloaded ? _buildDownloadedIndicator() : _buildNotDownloadedIndicator();
            },
          );
        }
      } else {
        // 没有PDF附件，显示未下载图标
        return _buildNotDownloadedIndicator();
      }
    }

    switch (downloadInfo.status) {
      case DownloadStatus.downloading:
        return _buildDownloadingIndicator(downloadInfo);
      case DownloadStatus.extracting:
        return _buildExtractingIndicator();
      case DownloadStatus.completed:
        return _buildCompletedIndicator();
      case DownloadStatus.failed:
        return _buildFailedIndicator();
      case DownloadStatus.cancelled:
        return _buildCancelledIndicator();
      default:
        return _buildDefaultIndicator();
    }
  }

  /// 下载中：圆形进度环
  Widget _buildDownloadingIndicator(AttachmentDownloadInfo downloadInfo) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: downloadInfo.progressPercent / 100,
              strokeWidth: 2.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          // 中心的取消图标
          const Icon(
            Icons.close,
            size: 10,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  /// 解压中：旋转的进度环
  Widget _buildExtractingIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      ),
    );
  }

  /// 下载完成：PDF图标（绿色）
  Widget _buildCompletedIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
        colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
      ),
    );
  }

  /// 下载失败：PDF图标（红色）
  Widget _buildFailedIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
        colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
      ),
    );
  }

  /// 下载取消：PDF图标（灰色）
  Widget _buildCancelledIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
      ),
    );
  }

  /// 默认状态：PDF图标
  Widget _buildDefaultIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
      ),
    );
  }

  /// 文件已下载：显示已下载图标
  Widget _buildDownloadedIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf.svg",
        height: 20,
        width: 20,
        package: 'module_library',
      ),
    );
  }

  /// 文件未下载：显示未下载图标
  Widget _buildNotDownloadedIndicator() {
    return ClipRRect(
      child: SvgPicture.asset(
        "assets/attachment_indicator_pdf_not_download.svg",
        height: 20,
        width: 20,
        package: 'module_library',
      ),
    );
  }
}
