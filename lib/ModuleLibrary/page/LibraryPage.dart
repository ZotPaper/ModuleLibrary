import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:module_base/my_eventbus.dart';
import 'package:module_base/utils/logger.dart';
import 'package:module_base/utils/tracking/dot_tracker.dart';
import 'package:module_base/view/dialog/neat_dialog.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/LibZoteroAttachDownloader/dialog/attachment_transfer_dialog_manager.dart';
import 'package:module_library/LibZoteroAttachDownloader/event/event_check_attachment_modification.dart';
import 'package:module_library/LibZoteroAttachDownloader/model/status.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attachment_transfer.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import 'package:module_library/LibZoteroStorage/database/dao/RecentlyOpenedAttachmentDao.dart';

import 'package:module_library/ModuleItemDetail/page/item_details_page.dart';
import 'package:module_library/ModuleLibrary/model/list_entry.dart';
import 'package:module_library/ModuleLibrary/model/page_type.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_page.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';
import 'package:module_library/ModuleLibrary/utils/sheet_item_helper.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/ModuleTagManager/item_tagmanager.dart';
import 'package:module_library/routers.dart' show MyRouter, globalRouteObserver;
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../utils/log/module_library_log_helper.dart';
import '../dialog/library_layout_dialog.dart';
import '../utils/color_utils.dart';
import '../utils/device_utils.dart';
import '../widget/global_download_indicator.dart';
import '../widget/attachment_indicator.dart';
import '../widget/item_entry_widget.dart';
import '../widget/collection_entry_widget.dart';
import '../widget/item_type_icon.dart';
import '../widget/bottomsheet/item_operation_panel.dart';
import '../widget/modified_attachments_banner.dart';
import '../widget/upload_progress_dialog.dart';
import '../widget/global_upload_indicator.dart';
import 'LibraryUI/appBar.dart';
import 'LibraryUI/drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bruno/bruno.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

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
 
  late RefreshController _phoneRefreshController;
  late RefreshController _tabletRefreshController;
  
  /// 获取当前布局对应的RefreshController
  RefreshController get _currentRefreshController {
    final bool isTablet = DeviceUtils.shouldShowFixedDrawer(context);
    return isTablet ? _tabletRefreshController : _phoneRefreshController;
  }

  StreamSubscription? _subscription;

  // 修改的附件信息
  List<Item>? _modifiedItems;
  List<RecentlyOpenedAttachment>? _modifiedAttachments;
  bool _showModifiedBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _phoneRefreshController = RefreshController(initialRefresh: false);
    _tabletRefreshController = RefreshController(initialRefresh: false);

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

    // 监听检查附件变更事件
    _subscription = eventBus.on<EventCheckAttachmentModification>().listen((event) {
      MyLogger.d("Moyear=== eventbus checkModifiedAttachments()");

      // 延迟执行操作
      Future.delayed(const Duration(seconds: 1), () {
        // 检查附件变更
        _viewModel.checkModifiedAttachments();
      });
    });

    MyLogger.d("Moyear=== 进入LibraryPage");
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
      globalRouteObserver.subscribe(this, modalRoute);
    }
  }

  /// 当发现修改的附件时的回调处理
  void _onModifiedAttachmentsFound(List<Item> modifiedItems, List<RecentlyOpenedAttachment> attachments) {
    // 保存修改的附件信息并显示提示栏
    setState(() {
      _modifiedItems = modifiedItems;
      _modifiedAttachments = attachments;

      MyLogger.d("Moyear=== modifiedItems数量：${_modifiedItems?.length} RecentlyOpenedAttachment数量：${_modifiedAttachments?.length}");

      // 判断是否显示提示栏
      final shouldShow = _modifiedItems?.isNotEmpty == true && _modifiedItems?.isNotEmpty == true;
      _showModifiedBanner = shouldShow;
    });
  }

  /// 关闭修改附件提示栏
  void _dismissModifiedBanner() {
    setState(() {
      _showModifiedBanner = false;
    });
    // 清除修改标记
    if (_modifiedAttachments != null) {
      _viewModel.clearModifiedAttachmentsMarks(_modifiedAttachments!);
    }
  }

  /// 点击提示栏，显示对话框
  void _onModifiedBannerTap() {
    if (_modifiedItems != null && _modifiedAttachments != null) {
      _showModifiedAttachmentsDialog(_modifiedItems!, _modifiedAttachments!);
    }
  }

  /// 显示修改的附件对话框
  void _showModifiedAttachmentsDialog(List<Item> modifiedItems, List<RecentlyOpenedAttachment> attachments) {
    MyLogger.d("Moyear=== 显示修改的附件对话框");
    
    final strModified = modifiedItems.map((item) => "\<font color = '#8ac6d1'\>${ item.getTitle()}</font>" ).join(', ');

    NeatDialogManager.showConfirmDialog(context,
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
        onConfirm: (BuildContext dialogContext) {
          // 隐藏提示栏
          setState(() {
            _showModifiedBanner = false;
          });

          Navigator.of(dialogContext).pop();

          // 开始上传修改的附件（会显示进度对话框）
          _startUploadModifiedAttachments(modifiedItems, attachments);

          // 关闭附件改变提示栏
          _dismissModifiedBanner();
        },
        onCancel: (BuildContext dialogContext) {
          // 隐藏提示栏并清除修改标记
          setState(() {
            _showModifiedBanner = false;
          });

          Navigator.of(dialogContext).pop();
        },
    );
  }

  /// 开始上传修改的附件
  Future<void> _startUploadModifiedAttachments(List<Item> modifiedItems, List<RecentlyOpenedAttachment> attachments) async {
    final totalCount = modifiedItems.length;
    int successCount = 0;
    Map<String, String> failedItemsWithErrors = {}; // 保存失败的附件和错误信息

    try {
      // 逐个上传附件
      for (int i = 0; i < modifiedItems.length; i++) {
        final item = modifiedItems[i];
        
        try {
          MyLogger.d('开始上传附件 ${i + 1}/$totalCount: ${item.getTitle()}');
          
          // 更新上传状态到ViewModel（会自动通知全局指示器更新）
          _viewModel.updateUploadProgress(
            item: item,
            currentIndex: i + 1,
            totalCount: totalCount,
          );

          // 上传单个附件
          await _viewModel.uploadSingleAttachment(item);
          
          // 从最近打开的附件列表中移除
          await _viewModel.zoteroDB.removeRecentlyOpenedAttachment(item.itemKey);
          
          // 上传完成后移除该附件的上传状态
          _viewModel.removeUploadProgress(item.itemKey);
          
          successCount++;
          MyLogger.d('附件上传成功: ${item.getTitle()}');

          // todo 更新本地附件的md5码信息

          // 附件上传成功 日志与埋点上报
          ModuleLibraryLogHelper.attachmentTransfer.logUploadSuccess(item);
          
        } catch (e) {
          final errorMsg = _parseUploadError(e);
          MyLogger.e('附件上传失败: ${item.getTitle()}, 错误: $errorMsg');
          failedItemsWithErrors[item.getTitle()] = errorMsg;
          
          // 更新为失败状态，显示在全局指示器中
          _viewModel.updateUploadProgress(
            item: item,
            currentIndex: i + 1,
            totalCount: totalCount,
            status: UploadStatus.failed,
            errorMessage: errorMsg,
          );
          
          // 延迟移除失败状态，让用户有时间看到
          Future.delayed(const Duration(seconds: 3), () {
            _viewModel.removeUploadProgress(item.itemKey);
          });
        }
      }

      // 显示结果
      if (!mounted) return;

      var needRefresh = false;
      if (failedItemsWithErrors.isEmpty) {
        // 全部成功
        BrnToast.show('所有附件上传成功！', context);
        // 这里再次检查是为了让顶部的那个修改弹窗消失
        // _viewModel.checkModifiedAttachments();

        var isZotero = ZoteroAttachDownloaderHelper.instance.transfer is ZoteroAttachmentTransfer;

        // 埋点上报
        DotTracker
            .addBot("UPLOAD_ALL_MODIFIED_SUCCESS", description: "所有附件上传成功")
            .addParam("total", modifiedItems.length)
            .addParam("service", isZotero ? "Zotero" : "WEBDAV")
            .report();

        needRefresh = true;
      } else if (successCount > 0) {
        // 部分成功 - 显示详细错误信息
        AttachmentTransferDialogManager.showUploadErrorInfo(
          context:  context,
          successCount: successCount,
          totalCount: totalCount,
          failedItems: failedItemsWithErrors,
        );
        needRefresh = true;
      } else {
        // 全部失败 - 显示详细错误信息
        AttachmentTransferDialogManager.showUploadErrorInfo(
          context: context,
          successCount: 0,
          totalCount: totalCount,
          failedItems: failedItemsWithErrors,
        );
      }
      if (needRefresh) {
        // 有上传成功的附件，会自动执行与服务器同步操作
        _currentRefreshController.requestRefresh();
      }
    } catch (e) {
      MyLogger.e('上传附件时发生错误: $e');
      // 清除所有上传状态
      for (var item in modifiedItems) {
        _viewModel.removeUploadProgress(item.itemKey);
      }
      if (mounted) {
        final errorMsg = _parseUploadError(e);
        BrnToast.show('上传失败：$errorMsg', context);
      }
    }
  }

  /// 解析上传错误信息，返回用户友好的错误描述
  String _parseUploadError(dynamic error) {
    String errorStr = error.toString();
    if (error is DioException) {
      errorStr = "errorCode[${error.response?.statusCode}], message: ${error.message}";
    }

    if (errorStr.contains('NetworkException')) {
      return '网络连接失败: $errorStr';
    } else if (errorStr.contains('timeout') || errorStr.contains('TimeoutException')) {
      return '连接超时: $errorStr';
    } else if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return '认证失败，请重新登录: $errorStr';
    } else if (errorStr.contains('404') || errorStr.contains('not found') || errorStr.contains("PathNotFoundException")) {
      return '文件未找到: $errorStr';
    } else if (errorStr.contains('500') || errorStr.contains('server error')) {
      return '服务器错误: $errorStr';
    } else {
      // 返回简化的错误信息
      return errorStr;
      // return errorStr.length > 50 ? '${errorStr.substring(0, 50)}...' : errorStr;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MyLogger.d("Moyear=== didChangeAppLifecycleState resume checkModifiedAttachments()");
      // 应用从后台返回前台时检查修改的附件
      _viewModel.checkModifiedAttachments();
    }
  }

  @override
  void didPopNext() {
    // 每次从其他页面返回时检查修改的附件
    super.didPopNext();
    _viewModel.checkModifiedAttachments();
    MyLogger.d("Moyear=== didPopNext checkModifiedAttachments()");
  }

  @override
  void dispose() {
    // 记得取消订阅
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    globalRouteObserver.unsubscribe(this);
    textController.dispose();
    focusNode.dispose();
    _phoneRefreshController.dispose();
    _tabletRefreshController.dispose();
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
    final bool isTablet = DeviceUtils.shouldShowFixedDrawer(context);
    
    if (_viewModel.curPage == PageType.sync) {
      return const SyncPageFragment();
    } else if (_viewModel.curPage == PageType.library) {
      return Stack(
        children: [
          libraryListPage(isTablet: isTablet),
          // 全局下载进度指示器
          _buildGlobalDownloadIndicator(),
          // 全局上传进度指示器
          _buildGlobalUploadIndicator(),
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

  /// 构建全局上传进度指示器
  Widget _buildGlobalUploadIndicator() {
    return GlobalUploadIndicator(
      viewModel: _viewModel,
    );
  }

  /// 文库列表页面
  Widget libraryListPage({required bool isTablet}) {
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
          // 修改附件提示栏
          if (_showModifiedBanner)
            ModifiedAttachmentsBanner(
              modifiedCount: _modifiedItems?.length ?? 0,
              onTap: _onModifiedBannerTap,
              onDismiss: _dismissModifiedBanner,
            ),
          Expanded(
            child: Container(
              color: ResColor.bgColor,
              width: double.infinity,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  // 当列表开始滚动时，移除焦点
                  if (notification is ScrollStartNotification) {
                    if (focusNode.hasFocus) {
                      FocusScope.of(context).unfocus();
                      focusNode.unfocus();
                    }
                  }
                  return false;
                },
                child: SmartRefresher(
                  key: ValueKey('refresher_${isTablet ? "tablet" : "phone"}'),
                  enablePullDown: true,
                  controller: isTablet ? _tabletRefreshController : _phoneRefreshController,
                  header: _refreshHeader(),
                  onRefresh: _onRefresh,
                  child: _viewModel.displayEntries.isEmpty ? _emptyView() : ListView.builder(
                    itemCount: _viewModel.displayEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _viewModel.displayEntries[index];
                      return widgetListEntry(entry);
                    },
                  ),
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
              _viewModel.onItemTap(context, entry.item!);
            },
            onLongPress: () {
              _viewModel.showItemInfoDetail(context, entry.item!);
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



  void _navigationTagManager() {
    MyRouter.instance.pushNamed(context, "tagsManagerPage");
  }

  void _onRefresh() async{
    // 开始与服务器同步
    _viewModel.startSync(onSyncCompleteCallback: () {
      // 关闭刷新动画
      _currentRefreshController.refreshCompleted();
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
        const Text('Oops! 页面内容为空或发生了错误'),
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
