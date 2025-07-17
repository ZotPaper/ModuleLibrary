import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/ModuleItemDetail/page/item_details_page.dart';
import 'package:module_library/ModuleLibrary/model/list_entry.dart';
import 'package:module_library/ModuleLibrary/model/page_type.dart';
import 'package:module_library/ModuleLibrary/page/blank_page.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_page.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';
import 'package:module_library/ModuleLibrary/utils/sheet_item_helper.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/ModuleTagManager/item_tagmanager.dart';
import 'package:module_library/routers.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../utils/color_utils.dart';
import 'LibraryUI/appBar.dart';
import 'LibraryUI/drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bruno/bruno.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late LibraryViewModel _viewModel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  BrnSearchTextController searchController = BrnSearchTextController();
  TextEditingController textController = TextEditingController();

  final focusNode = FocusNode();

  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
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
          return Scaffold(
            backgroundColor: ResColor.bgColor,
            key: _scaffoldKey,
            drawerEnableOpenDragGesture: false,
            drawer: CustomDrawer(
              collections: _viewModel.displayedCollections,
              onItemTap: _viewModel.handleDrawerItemTap,
              onCollectionTap: (collection) {
                _viewModel.handleCollectionTap(collection);
              }, // 如果有需要再实现
            ),
            appBar: pageAppBar(
              title: _viewModel.title,
              leadingIconTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              filterMenuTap: () {},
              tagsTap: () {
                _navigationTagManager();
              },
            ),
            body: _viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPageContent(),
          );
        }
      ),
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
              _itemImportantTags(item),
            ],
          ),
        ),
        if (item.attachments.isNotEmpty) _attachmentIndicator(item),
        IconButton(onPressed: () {
          _showItemEntryOperatePanel(context, item);
        }, icon: const Icon(Icons.more_vert)),
      ],
    );
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
                child: Text(collection.name, maxLines: 2),
              ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  "$sizeSub条子项",
                  maxLines: 1,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        IconButton(onPressed: () {
          _showCollectionEntryOperatePanel(context, collection);
        }, icon: const Icon(Icons.more_vert)),
      ],
    );
  }

  /// Icon Widget
  Widget _iconItemWidget(ListEntry entry) {
    if (entry.isCollection()) {
      return SvgPicture.asset(
        'assets/items/opened_folder.svg',
        package: 'module_library',
        width: 18,
        height: 18,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(26),
      ),
      child: _iconItemWidget(entry),
    );
  }

  Widget _attachmentIndicator(Item item) {
    return  InkWell(
      onTap: () {
        // print("pdf tap");
        _showItemInfo(context, item);
      },
      child: Container(
        padding: EdgeInsets.all(4),
        child: ClipRRect(
          // borderRadius: BorderRadius.circular(20),
          child: SvgPicture.asset(
            "assets/attachment_indicator_pdf.svg",
            height: 20,
            width: 20,
            package: 'module_library',
          ),
        ),
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
    return SvgPicture.asset(iconPath, height: 14, width: 14, package: 'module_library',);
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


}
