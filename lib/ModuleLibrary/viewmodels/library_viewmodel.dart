import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:bruno/bruno.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/LibZoteroAttachDownloader/model/upload_attachment.dart';
import 'package:module_library/LibZoteroAttachDownloader/native/attachment_native_channel.dart';
import 'package:module_library/LibZoteroAttachDownloader/webdav_attachment_transfer.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attachment_transfer.dart';
import 'package:module_library/LibZoteroAttachment/attachment_strategy_manager.dart';
import 'package:module_library/LibZoteroStorage/database/dao/RecentlyOpenedAttachmentDao.dart';
import 'package:module_library/ModuleLibrary/model/list_entry.dart';
import 'package:module_library/ModuleLibrary/model/page_type.dart';
import 'package:module_library/ModuleLibrary/my_library_filter.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';
import 'package:module_library/ModuleLibrary/zotero_provider.dart';
import 'package:module_library/ModuleNoteEdit/note_edit_manager.dart';
import 'package:module_library/ModuleTagManager/item_tagmanager.dart';
import 'package:module_library/utils/local_zotero_credential.dart';
import 'package:module_library/utils/webdav_configuration.dart';
import 'package:open_filex/open_filex.dart';
import '../../LibZoteroAttachDownloader/bean/exception/zotero_download_exception.dart';
import '../../LibZoteroAttachDownloader/default_attachment_storage.dart';
import '../../LibZoteroAttachDownloader/model/status.dart';
import '../../LibZoteroAttachDownloader/model/transfer_info.dart';
import '../../LibZoteroStorage/entity/Collection.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../LibZoteroStorage/entity/ItemCollection.dart';
import '../../LibZoteroStorage/entity/Note.dart';
import '../../ModuleSync/zotero_sync_manager.dart';
import '../../routers.dart';
import '../api/ZoteroDataHttp.dart';
import '../api/ZoteroDataSql.dart';
import '../model/my_item_entity.dart';
import '../share_pref.dart';
import '../page/LibraryUI/drawer.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../store/library_settings.dart';
import 'package:module_base/stores/hive_stores.dart';

import '../widget/bottomsheet/item_operation_panel.dart';

class LibraryViewModel with ChangeNotifier {

  bool _initialized = false;
  bool get initialized => _initialized;

  final ZoteroDataSql zoteroDataSql = ZoteroProvider.getZoteroDataSql();

  String _userId = "";
  String _apiKey = "";

  PageType curPage = PageType.library;

  String title = '';

  List<Item> _items = [];
  final List<Collection> _displayedCollections = [];

  List<Collection> get displayedCollections => _displayedCollections;

  // 当前位置的所有列表entries
  final List<ListEntry> _listEntries = [];
  // List<ListEntry> get listEntries => _listEntries;

  // 用于显示的列表entries，用于过滤
  final List<ListEntry> _displayListEntries = [];
  List<ListEntry> get displayEntries => _displayListEntries;

  /// 用于过滤的关键字
  String filterText = "";

  // 当前位置的key
  String currentLocationKey = "";

  final ZoteroDB zoteroDB = ZoteroProvider.getZoteroDB();

  TagManager tagManager = TagManager();

  // 添加LibraryStore实例
  final LibraryStore _libraryStore = Stores.get(Stores.KEY_LIBRARY) as LibraryStore;

  // 下载状态跟踪
  final Map<String, AttachmentDownloadInfo> _downloadStates = {};
  
  // 上传状态跟踪
  final Map<String, AttachmentUploadInfo> _uploadStates = {};
  
  // 文件存在状态缓存
  final Map<String, bool> _fileExistsCache = {};
  
  /// 获取附件下载状态
  AttachmentDownloadInfo? getDownloadStatus(String itemKey) {
    return _downloadStates[itemKey];
  }

  /// 获取所有正在进行的下载任务
  List<AttachmentDownloadInfo> getActiveDownloads() {
    return _downloadStates.values
        .where((info) => 
            info.status == DownloadStatus.downloading || 
            info.status == DownloadStatus.extracting)
        .toList();
  }

  /// 检查是否有正在进行的下载
  bool hasActiveDownloads() {
    return getActiveDownloads().isNotEmpty;
  }

  /// 获取所有正在进行的上传任务（包含失败状态，以便用户看到错误）
  List<AttachmentUploadInfo> getActiveUploads() {
    return _uploadStates.values
        .where((info) => 
            info.status == UploadStatus.uploading ||
            info.status == UploadStatus.failed)
        .toList();
  }

  /// 检查是否有正在进行的上传
  bool hasActiveUploads() {
    return getActiveUploads().isNotEmpty;
  }

  /// 更新上传状态
  void _updateUploadState(AttachmentUploadInfo uploadInfo) {
    _uploadStates[uploadInfo.itemKey] = uploadInfo;
    MyLogger.d('更新上传状态: ${uploadInfo.itemKey} - ${uploadInfo.status}');
    notifyListeners(); // 通知UI更新
  }

  /// 移除上传状态
  void _removeUploadState(String itemKey) {
    _uploadStates.remove(itemKey);
    MyLogger.d('移除上传状态: $itemKey');
    notifyListeners();
  }

  /// 更新上传进度（公开方法，供UI层调用）
  void updateUploadProgress({
    required Item item,
    required int currentIndex,
    required int totalCount,
    UploadStatus status = UploadStatus.uploading,
    String? errorMessage,
  }) {
    final uploadInfo = AttachmentUploadInfo(
      itemKey: item.itemKey,
      filename: item.getTitle(),
      currentIndex: currentIndex,
      totalCount: totalCount,
      status: status,
      errorMessage: errorMessage,
    );
    _updateUploadState(uploadInfo);
  }

  /// 移除上传进度（公开方法，供UI层调用）
  void removeUploadProgress(String itemKey) {
    _removeUploadState(itemKey);
  }
  
  /// 获取缓存的文件存在状态
  bool? getCachedFileExists(String itemKey) {
    return _fileExistsCache[itemKey];
  }
  
  // 用于防止同一个文件被重复检查
  final Map<String, Future<bool>> _fileCheckingFutures = {};
  
  /// 异步检查并缓存文件存在状态
  Future<bool> checkAndCacheFileExists(Item pdfAttachment) async {
    final itemKey = pdfAttachment.itemKey;
    
    // 如果已经缓存且不在下载中，直接返回缓存值
    if (_fileExistsCache.containsKey(itemKey) && !isAttachmentDownloading(itemKey)) {
      return _fileExistsCache[itemKey]!;
    }
    
    // 如果正在检查中，返回同一个Future
    if (_fileCheckingFutures.containsKey(itemKey)) {
      return _fileCheckingFutures[itemKey]!;
    }
    
    // 创建新的检查Future
    final checkFuture = _checkFileExists(pdfAttachment);
    _fileCheckingFutures[itemKey] = checkFuture;
    
    try {
      final exists = await checkFuture;
      _fileExistsCache[itemKey] = exists;
      MyLogger.d('文件存在检查完成: $itemKey = $exists');
      return exists;
    } finally {
      // 检查完成后移除Future缓存
      _fileCheckingFutures.remove(itemKey);
    }
  }
  
  /// 实际执行文件检查的方法
  Future<bool> _checkFileExists(Item pdfAttachment) async {
    try {
      return await DefaultAttachmentStorage.instance.attachmentExists(pdfAttachment);
    } catch (e) {
      MyLogger.e('检查文件存在时出错: ${pdfAttachment.itemKey}, 错误: $e');
      return false;
    }
  }
  
  /// 检查附件是否正在下载
  bool isAttachmentDownloading(String itemKey) {
    final state = _downloadStates[itemKey];
    return state?.status == DownloadStatus.downloading || 
           state?.status == DownloadStatus.extracting;
  }
  
  /// 更新下载状态
  void _updateDownloadState(AttachmentDownloadInfo downloadInfo) {
    _downloadStates[downloadInfo.itemKey] = downloadInfo;
    MyLogger.d('更新下载状态: ${downloadInfo.itemKey} - ${downloadInfo.status} - ${downloadInfo.progressPercent}%');
    notifyListeners(); // 通知UI更新
  }
  
  /// 移除下载状态
  void _removeDownloadState(String itemKey) {
    _downloadStates.remove(itemKey);
    MyLogger.d('移除下载状态: $itemKey');
    notifyListeners();
  }

  LibraryViewModel() : super() {}

  final BehaviorSubject<PageType> _curPageController = BehaviorSubject<PageType>.seeded(PageType.blank);
  Stream<PageType> get curPageStream => _curPageController.stream;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

 SyncProgress? syncProgress = null;

  /// 栈结构，用于记录浏览历史
  final DoubleLinkedQueue<String> _viewStack = DoubleLinkedQueue<String>();
  DoubleLinkedQueue<String> get viewStack => _viewStack;

  ZoteroSyncManager zoteroSyncManager = ZoteroSyncManager.instance;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void init() async {
    bool isLoggedIn = await LocalZoteroCredential.isLoggedIn();
    debugPrint("=============isLoggedIn: $isLoggedIn");

    setLoading(true);
    if (!isLoggedIn) {
      // 切换到同步页面
      navigateToPage(PageType.sync);
    } else {
      // 获取本地保存的apikey和userId
      await fetchZoteroUserCredential();

      MyLogger.d("fetch saved loginInfo locally: [userId: $_userId, apiKey: $_apiKey]");

      ZoteroProvider.initZoteroProvider(_userId, _apiKey);
      // 初始化同步管理器
      if (!zoteroSyncManager.isConfigured()) {
        zoteroSyncManager.init(_userId, _apiKey);
      }

      // 初始化标签管理器
      await tagManager.init();

      // 从数据库加载数据
      await _loadDataFromLocalDatabase();
      // 切换到列表页面
      navigateToPage(PageType.library);

      // 显示所有条目
      showListEntriesIn("library");

      // 初始化下载助手
      await ensureDownloadHelperInitialized();

      // 初始化PDF查看器
      await PdfViewerNativeChannel.init();
      
      // 设置附件管理器的状态更新回调
      AttachmentStrategyManager.instance.setDownloadStateUpdateCallback((downloadInfo) {
        _updateDownloadState(downloadInfo);
      });
      AttachmentStrategyManager.instance.setDownloadStateRemoveCallback((itemKey) {
        _removeDownloadState(itemKey);
      });
      AttachmentStrategyManager.instance.setFileExistsCacheUpdateCallback((itemKey, exists) {
        if (exists) {
          _fileExistsCache[itemKey] = true;
        } else {
          _fileExistsCache.remove(itemKey);
        }
      });
    }

    setLoading(false);
    _initialized = true;
  }

  Future<void> fetchZoteroUserCredential() async {
    _userId = await LocalZoteroCredential.getUserId();
    _apiKey = await LocalZoteroCredential.getApiKey();
  }

  void navigateToPage(PageType page) {
    curPage = page;
    notifyListeners();
  }

  /// 处理抽屉按钮点击事件
  void handleDrawerItemTap(DrawerBtn drawerBtn, {String? collectionKey}) {
    switch (drawerBtn) {
      case DrawerBtn.home:
        showListEntriesIn("home");
        break;
      case DrawerBtn.favourites:
        showListEntriesIn("favourites");
      case DrawerBtn.library:
        showListEntriesIn("library");
        break;
      case DrawerBtn.unfiled:
        showListEntriesIn("unfiled");
        break;
      case DrawerBtn.publications:
        showListEntriesIn("publications");
        break;
      case DrawerBtn.trash:
        showListEntriesIn("trashes");
      default:
    }
    _notifyShowItems();
  }

  void _resetShowItems() {
    // _showItems.clear();
  }

  void _notifyShowItems() {
    // _showItemsController.add(_showItems);
    notifyListeners();
  }

  void dispose() {
    // _showItemsController.close();
    _curPageController.close();
  }

  /// 从本地数据库中获取数据
  Future<void> _loadDataFromLocalDatabase() async {
    MyLogger.d("_loadDataFromLocalDatabase 从本地数据库中获取数据}");

    var collections = await zoteroDataSql.getCollections();
    // 把collections保存到内存中
    zoteroDB.setCollections(collections);

    MyLogger.d("_loadDataFromLocalDatabase getCollections 获取所有的集合数据完成✅");

    _items = await zoteroDataSql.getItems();
    // 把items保存到内存中
    zoteroDB.setItems(_items);

    MyLogger.d("_loadDataFromLocalDatabase getItems 获取所有的条目数据完成✅");

    // 加载回收站数据
    var deletedItems = await zoteroDataSql.getDeletedTrashes();
    zoteroDB.setTrashedItems(deletedItems);

    MyLogger.d("_loadDataFromLocalDatabase getDeletedTrashes 获取所有的集合数据完成✅");

    // 加载所有的标签数据
    var allTags = await zoteroDataSql.getAllTags();
    zoteroDB.setItemTags(allTags);

    MyLogger.d("_loadDataFromLocalDatabase getAllTags 获取所有的集合数据完成✅");

    // 初始化过滤器
    MyItemFilter.instance.init();

    // 只显示顶级的集合
    _displayedCollections.clear();
    _displayedCollections.addAll(collections.where((it) {
      return !it.hasParent();
    }));
  }

  /// 显示指定位置的列表entries
  Future<void> showListEntriesIn(String locationKey, {bool addToViewStack = true}) async {
    List<ListEntry> list = [];
    switch (locationKey) {
      case 'home':
        list = await _getHomeListEntries();
        title = "主页";
        break;
      case 'library':
        list = await _getMyLibraryEntries();
        title = "我的文库";
        break;
      case 'publications':
        list = await _getPublicationsEntries();
        title = "我的出版物";
        break;
      case 'unfiled':
        list = await _getUnfiledEntries();
        // debugPrint('Moyear=== unfiled res:${list.length}');
        title = "未分类条目";
        break;
      case "trashes":
        list = await _getTrashEntries();
        title = "回收站";
        break;
      case "favourites":
        list = await _getMyStarredEntries();
        title = "收藏";
        break;
      default:
        // list = await _getEntriesInCollection(locationKey);
    }

    _listEntries.clear();
    _listEntries.addAll(list);

    _displayListEntries.clear();
    if (filterText.isEmpty) {
      _displayListEntries.addAll(_listEntries);
    } else {
      _displayListEntries.addAll(_filterListEntries(_listEntries, filterText));
    }

    _notifyShowItems();
    notifyListeners();

    // 记录当前位置的key
    currentLocationKey = locationKey;

    if (addToViewStack) {
      // 添加到浏览历史栈中
      _viewStack.addLast(locationKey);
    }
  }

  /// 获取我的文库页面的条目数据 - 修改以支持筛选
  Future<List<ListEntry>> _getMyLibraryEntries() async {
    var res = zoteroDB.getDisplayableItems();
    
    // 应用筛选
    res = _applyItemFilters(res);
    
    // 对数据进行排序
    sortItems(res);

    return res.map((ele) {
      return ListEntry(item: ele);
    }).toList();
  }

  Future<List<ListEntry>> _getHomeListEntries() async {
    List<ListEntry> res = [];
    zoteroDB.collections.forEach((element) {
      res.add(ListEntry(collection: element));
    });
    var allItems = zoteroDB.getDisplayableItems();
    
    // 应用筛选
    allItems = _applyItemFilters(allItems);
    
    sortItems(allItems);

    res.addAll(allItems.map((ele) {
      return ListEntry(item: ele);
    }).toList());
    return res;
  }

  /// 获取未分类的条目 - 修改以支持筛选
  Future<List<ListEntry>> _getUnfiledEntries() async {
    var res = zoteroDB.getUnfiledItems();
    
    // 应用筛选
    res = _applyItemFilters(res);
    
    // 对数据进行排序
    sortItems(res);

    return res.map((ele) {
      return ListEntry(item: ele);
    }).toList();
  }

  /// 处理侧边栏合集的点击事件 - 修改以支持筛选
  Future<void> handleCollectionTap(Collection collection, {bool addToViewStack = true}) async {
    // var itemKey = collection.key;
    // var entries = await _getEntriesInCollection(itemKey);
    title = collection.name;

    var res = zoteroDB.getItemsFromCollection(collection.key);
    
    // 应用筛选
    res = _applyItemFilters(res);
    
    // 对数据进行排序
    sortItems(res);
    var entriesItems = res.map((ele) {
      return ListEntry(item: ele);
    });
    // debugPrint('Moyear== handleCollectionTap: $itemKey size: ${entries.length}');

    var subCollections = await zoteroDB.getSubCollectionsOf(collection.key);
    // 对数据进行排序
    sortCollections(subCollections);
    var entriesCollections = subCollections.map((ele) {
      return ListEntry(collection: ele);
    });

    _listEntries.clear();
    // 过滤数据并添加
    _listEntries.addAll(entriesCollections);
    _listEntries.addAll(entriesItems);

    _displayListEntries.clear();
    // 过滤数据并添加, 如果没有过滤条件，则添加全部数据
    if (filterText.trim().isEmpty) {
      _displayListEntries.addAll(_listEntries);
    } else {
      _displayListEntries.addAll(_filterListEntries(_listEntries, filterText));
    }

    _notifyShowItems();
    notifyListeners();

    // 记录当前位置的key
    currentLocationKey = collection.key;

    if (addToViewStack) {
      // 添加到浏览历史栈中
      _viewStack.addLast(collection.key);
    }
  }

  /// 获取我的出版物 - 修改以支持筛选
  Future<List<ListEntry>>_getPublicationsEntries() async {
    var res = zoteroDB.getMyPublicationItems();
    
    // 应用筛选
    res = _applyItemFilters(res);
    
    // 对数据进行排序
    sortItems(res);

    return res.map((ele) {
      return ListEntry(item: ele);
    }).toList();
  }

  Future<List<ListEntry>> _getTrashEntries() async {
    var res = zoteroDB.getTrashedItems();
    
    // 应用筛选
    res = _applyItemFilters(res);
    
    sortItems(res);
    return res.map((ele) {
      return ListEntry(item: ele);
    }).toList();
  }

  /// 应用所有筛选条件
  List<Item> _applyItemFilters(List<Item> items) {
    List<Item> filteredItems = List.from(items);
    
    // 筛选只含PDF附件的条目
    if (_libraryStore.showOnlyWithPdfs.get()) {
      filteredItems = filteredItems.where((item) => _itemHasPdfAttachment(item)).toList();
    }
    
    // 筛选只含笔记的条目
    if (_libraryStore.showOnlyWithNotes.get()) {
      filteredItems = filteredItems.where((item) => item.isNoteItem() || _itemHasNotes(item)).toList();
    }
    
    return filteredItems;
  }

  /// 检查条目是否有PDF附件
  bool _itemHasPdfAttachment(Item item) {
    if (isPdfAttachmentItem(item)) return true;
    return item.attachments.any((attachment) => 
      isPdfAttachmentItem(attachment)
    );
  }

  /// 检查条目是否为pdf附件条目
  bool isPdfAttachmentItem(Item item) {
    return item.getFileExtension().toLowerCase() == "pdf";
  }

  /// 检查条目是否有PDF附件
  bool itemHasPdfAttachment(Item item) {
    return _itemHasPdfAttachment(item);
  }

  /// 检查条目是否有笔记
  bool _itemHasNotes(Item item) {
    return item.notes.isNotEmpty;
  }
  /// 返回上一个浏览记录
  void backToPreviousPos() async {
    var locationKey = _viewStack.removeLast();
    if (locationKey.isEmpty) return;

    debugPrint('Moyear=== backToPreviousPage: $locationKey');

    switch (locationKey) {
      case 'home':
      case 'library':
      case 'publications':
      case 'unfiled':
      case "trashes":
      case "favourites":
        showListEntriesIn(locationKey, addToViewStack: false);
        break;
      default:
    }

    var collection = zoteroDB.getCollectionByKey(locationKey);
    if (collection != null) {
      handleCollectionTap(collection, addToViewStack: false);
    }
  }

  /// 对items进行排序
  List<Item> sortItems(List<Item> items) {
    // 根据设置进行排序
    items.sort((a, b) {
      return _compareItem(a, b);
    });
    return items;
  }

  /// 比较两个合集
  List<Collection> sortCollections(List<Collection> collections) {
    // 根据item进行排序
    collections.sort((a, b) {
      return _compereCollection(a, b);
    });
    return collections;
  }

  /// 比较两个item - 重新实现以支持多种排序方式
  int _compareItem(Item item1, Item item2) {
    String sortMethod = _libraryStore.sortMethod.get();
    bool isDescending = _libraryStore.sortDirection.get() == "DESCENDING";
    
    int result = 0;
    
    switch (sortMethod) {
      case "TITLE":
        result = item1.getTitle().toLowerCase().compareTo(item2.getTitle().toLowerCase());
        break;
      case "AUTHOR":
        result = item1.getAuthor().toLowerCase().compareTo(item2.getAuthor().toLowerCase());
        break;
      case "DATE":
        result = item1.getSortableDateString().compareTo(item2.getSortableDateString());
        break;
      case "DATE_ADDED":
        result = item1.getSortableDateAddedString().compareTo(item2.getSortableDateAddedString());
        break;
      default:
        result = item1.getTitle().toLowerCase().compareTo(item2.getTitle().toLowerCase());
    }
    
    return isDescending ? -result : result;
  }

  /// 比较两个item (保持原有的简单比较作为备用)
  int _compereItem(Item item1, Item item2) {
    return _compareItem(item1, item2);
  }

  int _compereCollection(Collection collection1, Collection collection2) {
    bool isDescending = _libraryStore.sortDirection.get() == "DESCENDING";
    int result = collection1.name.compareTo(collection2.name);
    return isDescending ? -result : result;
  }

  /// 在浏览器中查看条目
  Future<void> viewItemOnline(BuildContext context, Item item) async {
    var url = item.getItemData('url') ?? "";
    if (url.isEmpty) {
      BrnToast.show(
        "找不到该条目的在线链接",
        context,
        duration: BrnDuration.short,
      );
      return;
    };

    debugPrint('Moyear=== viewItemOnline: $url');

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  // 开始与服务器同步
  void startSync({Function? onSyncCompleteCallback}) {
    zoteroSyncManager.startCompleteSync(
      onProgressCallback: (progress, total, items) {
        MyLogger.d("Moyear=== LibraryPage同步Item进度：$progress/$total");
        MyLogger.d("Moyear=== 获取Item数量：${items?.length}");

        // 通知下载进度
        syncProgress = SyncProgress(progress, total);
        notifyListeners();
        // _onProgressCallback?.call(progress, total);
      },
      onFinishCallback: (total) async {
        debugPrint("Moyear=== LibraryPage同步加载Item完成，条目数量：${total}");

        await _loadDataFromLocalDatabase();

        // 通知刷新当前页面
        refreshInCurrent();
        // 更新本地的文库版本

        onSyncCompleteCallback?.call();

        syncProgress = null;
      },
    );
  }

  /// 刷新当前页面
  void refreshInCurrent() {
    if (currentLocationKey.isEmpty) return;

    switch (currentLocationKey) {
      case 'home':
      case 'library':
      case 'publications':
      case 'unfiled':
      case "trashes":
      case "favourites":
        showListEntriesIn(currentLocationKey, addToViewStack: false);
        break;
      default:
    }

    var collection = zoteroDB.getCollectionByKey(currentLocationKey);
    if (collection != null) {
      handleCollectionTap(collection, addToViewStack: false);
    }
  }

  Future<TagColor?> filterInImportTag(String tag) async {
    return await tagManager.foundInImportantTag(tag);
  }

  Future<List<TagColor>> getImportTagOfItem(Item item) async {
    List<TagColor> res = [];
    var itemTags = item.getTagList();

    List<TagColor> importantTags = await tagManager.getStyledTags();

    importantTags.forEach((ele) {
      if (itemTags.contains(ele.name)) {
        res.add(ele);
      }
    });
    return res;
  }

  List<TagColor> getImportTagOfItemSync(Item item) {
    List<TagColor> res = [];
    var itemTags = item.getTagList();

    List<TagColor> importantTags = tagManager.styledTags;

    importantTags.forEach((ele) {
      if (itemTags.contains(ele.name)) {
        res.add(ele);
      }
    });
    return res;
  }

  int getNumInCollection(Collection collection) {
    int size = collection.subCollections?.length ?? 0;
    size += zoteroDB.getItemsFromCollection(collection.key).length;

    return size;

  }

  void addToStar(Collection collection) {
    var collectionInfo = FilterInfo.fromCollection(collection);
    // 添加到收藏夹
    MyItemFilter.instance.addToStar(collectionInfo);
  }

  void addToStaredItem(Item item) {
    var itemInfo = FilterInfo.fromItem(item);
    // 添加到收藏夹
    MyItemFilter.instance.addToStar(itemInfo);
  }

  Future<List<ListEntry>> _getMyStarredEntries() async {
    // 每次都创建新的列表，避免重复数据
    List<ListEntry> res = [];
    List<Item> starredItems = [];
    List<Collection> starredCollections = [];
    
    // 获取收藏的items和collections
    final myStars = MyItemFilter.instance.getMyStars();
    
    for (var ele in myStars) {
      if (ele.isCollection) {
        var collection = zoteroDB.getCollectionByKey(ele.itemKey);
        if (collection != null) {
          starredCollections.add(collection);
        }
      } else {
        var item = zoteroDB.getItemByKey(ele.itemKey);
        if (item != null) {
          starredItems.add(item);
        }
      }
    }

    // 对收藏的集合进行排序
    sortCollections(starredCollections);
    res.addAll(starredCollections.map((collection) => ListEntry(collection: collection)));
    
    // 对收藏的条目应用筛选和排序
    starredItems = _applyItemFilters(starredItems);
    sortItems(starredItems);
    res.addAll(starredItems.map((item) => ListEntry(item: item)));

    MyLogger.d('_getMyStarredEntries: 收藏集合=${starredCollections.length}, 收藏条目=${starredItems.length}, 总计=${res.length}');
    
    return res;
  }

  /// 获取收藏夹是否被收藏
  bool isCollectionStarred(Collection collection) {
    return MyItemFilter.instance.isStarred(FilterInfo.fromCollection(collection));

  }

  bool isItemStarred(Item item) {
    return MyItemFilter.instance.isStarred(FilterInfo.fromItem(item));
  }

  /// 从收藏夹移除
  Future<void> removeStar({Collection? collection, Item? item}) async {
    bool delete = false;
    if (collection != null) {
      await MyItemFilter.instance.removeStar(FilterInfo.fromCollection(collection));
      delete = true;
    }
    if (item != null) {
      await MyItemFilter.instance.removeStar(FilterInfo.fromItem(item));
      delete = true;
    }

    // 如果有元素删除则刷新数据
    if (delete) {
      refreshInCurrent();
    }
  }

  /// 设置过滤条件
  void setFilterText(String text) {
    filterText = text;
    refreshInCurrent();
  }

  /// 对条目进行过滤
  List<ListEntry> _filterListEntries(List<ListEntry> entries, String filter, {bool ignoreCase = true}) {
    if (filter.trim().isEmpty) {
      return entries;
    }
    return entries.where((entry) {
      if (entry.isCollection()) {
        return entry.collection!.name.contains(filter);
      } else if (entry.isItem()) {
        if (entry.item!.getTitle().contains(filter) == true || entry.item!.getAuthor().contains(filter)) {
          return true;
        }

        // 遍历作者
        for (var creator in entry.item!.creators) {
          if (ignoreCase) {
            if (creator.firstName.toLowerCase().contains(filter.toLowerCase())
                || creator.lastName.toLowerCase().contains(filter.toLowerCase())) {
              return true;
            }
          } else {
            if (creator.firstName.contains(filter) || creator.lastName.contains(filter)) {
              return true;
            }
          }
        }

        // 遍历条目数据中的 摘要, 笔记, 批注, 出版社
        if (_itemDataContains(entry.item!, "abstractNote", filter) ||
            _itemDataContains(entry.item!, "note", filter) ||
            _itemDataContains(entry.item!, "annotationText", filter) ||
            _itemDataContains(entry.item!, "publicationTitle", filter)
        ) {
          return true;
        }
        else {
          return false;
        }
      } else {
        return false;
      }
    }).toList();
  }

  /// 条目数据是否包含过滤条件
  bool _itemDataContains(Item item, String itemAttr, String filter, {bool ignoreCase = true}) {
    if (itemAttr.isEmpty) return false;
    var value = item.getItemData(itemAttr) ?? "";
    if (ignoreCase) {
      filter = filter.toLowerCase();
      value = value.toLowerCase();
    }
    return value.contains(filter) == true;
  }

  void moveItemToTrash(BuildContext context, Item item) {
    zoteroDataSql.itemInfoDao.markItemDeleted(item.itemKey, true);
    zoteroDB.moveItemToTrash(item);

    BrnToast.show("将条目${item.itemKey}移动到回收站成功", context);
    refreshInCurrent();
  }

  bool isItemDeleted(Item item) {
    return item.itemInfo.deleted;
  }

  void restoreItem(BuildContext context, Item item) {
    zoteroDataSql.itemInfoDao.markItemDeleted(item.itemKey, false);
    zoteroDB.restoreItemFromTrash(item);

    BrnToast.show("恢复条目${item.itemKey}成功", context);
    refreshInCurrent();
  }

  void showChangeCollectionSelector(BuildContext ctx, {Item? item, Collection? collection}) {
    // debugPrint("====默认选中的：${item.collections}");
    List<String> collectionKeys = [];

    var multiSelect = true;
    if (item != null) {
      collectionKeys = item.collections;
    } else if (collection != null) {
      collectionKeys = [collection.parentCollection];
      multiSelect = false;
    }

    Future res = Navigator.of(ctx).pushNamed("collectionSelector", arguments: <String, dynamic> {
      "initialSelected": collectionKeys,
      "isMultiSelect": multiSelect,
    });
    res.then((value) {
      if (value is List<String>) {
        if (item != null) {
          _changeParentCollections(ctx, item, value);
        } else if (collection != null) {

          var parentCollectionKey = "";
          if (value.isNotEmpty) {
            parentCollectionKey = value[0];
          }
          _changeParentCollectionsOfCollection(ctx, collection, parentCollectionKey);
        }
      }
    });
  }

  void _changeParentCollections(BuildContext ctx, Item item, List<String> value) {
    MyLogger.d("选中了${value.length}个集合");

    Set<String> collectionKeys = value.toSet();

    // 更新内存中的数据
    zoteroDB.updateParentCollections(item, value.toSet());
    // 更新数据库
    zoteroDataSql.itemCollectionDao.updateParentCollections(item.itemKey, collectionKeys);

    // 刷新当前页面
    refreshInCurrent();
  }

  void _changeParentCollectionsOfCollection(BuildContext ctx, Collection collection, String parentCollectionKey) {
    MyLogger.d("改变Collection[${collection.name}]的父集合为$parentCollectionKey");

    // 更新内存中的数据
    zoteroDB.updateParentCollection(collection, parentCollectionKey);
    // 更新数据库
    zoteroDataSql.collectionsDao.updateParentCollection(collection, parentCollectionKey);

    // 刷新当前页面
    refreshInCurrent();
  }

  /// 创建副本
  // void duplicateItem(BuildContext ctx, Item item) {
  //   Item duplicatedItem = item;
  //   duplicatedItem.getTitle()
  //
  //   zoteroDB.addItem(duplicatedItem);
  //
  //
  //   refreshInCurrent();
  // }


  /// 过滤条目，只显示pdf文件
  void filterItemsOnlyWithPdfs(bool enableFilter) {
    // 保存设置到store
    _libraryStore.showOnlyWithPdfs.set(enableFilter);
    
    // 刷新当前页面以应用筛选
    refreshInCurrent();
  }

  /// 筛选条目，只显示带笔记的条目
  void filterItemsOnlyWithNotes(bool enableFilter) {
    // 保存设置到store
    _libraryStore.showOnlyWithNotes.set(enableFilter);
    
    // 刷新当前页面以应用筛选
    refreshInCurrent();
  }

  /// 下载pdf或取消下载
  /// 现在委托给 AttachmentStrategyManager 处理
  Future<void> openOrDownloadedPdf(BuildContext context, Item item) async {
    await AttachmentStrategyManager.instance.openOrDownloadPdf(context, item);
  }

  /// 删除item下所有已下载的附件
  Future<void> deleteAllDownloadedAttachmentsOfItems(
      BuildContext context,
      Item item,
      {required VoidCallback onCallback}) async {

    if (!item.hasAttachments() && !item.isDownloadable()) {
      MyLogger.d('条目没有附件，跳过删除操作');
      onCallback();
      return;
    }

    List<Item> attachments = [];
    if (item.isDownloadable()) {
      // item为附件类型
      attachments.add(item);
    } else {
      // item为条目类型
      attachments = item.attachments;
    }

    // 过滤出已下载的附件
    List<Item> downloadedAttachments = [];
    for (var attachment in attachments) {
      bool exists = await DefaultAttachmentStorage.instance.attachmentExists(attachment);
      if (exists) {
        downloadedAttachments.add(attachment);
      }
    }

    if (downloadedAttachments.isEmpty) {
      MyLogger.d('没有已下载的附件需要删除');
      BrnToast.show('没有已下载的附件需要删除', context);
      onCallback();
      return;
    }

    MyLogger.d('开始删除${downloadedAttachments.length}个已下载的附件');

    // 使用计数器跟踪删除进度
    int completedCount = 0;
    int totalCount = downloadedAttachments.length;
    int successCount = 0;
    int failedCount = 0;

    final storage = DefaultAttachmentStorage.instance;

    for (var attachment in downloadedAttachments) {
      try {
        await storage.deleteAttachment(attachment);
        // 【客户端】pdf文件删除下载本地文件后从最近修改的文档中移除
        zoteroDB.removeRecentlyOpenedAttachment(attachment.itemKey);
        MyLogger.d('删除附件成功: ${attachment.getTitle()}');
        
        // 更新文件存在状态缓存为false
        _fileExistsCache[attachment.itemKey] = false;
        // 清除可能存在的检查Future
        _fileCheckingFutures.remove(attachment.itemKey);
        
        successCount++;
      } catch (e) {
        MyLogger.e('删除附件失败: ${attachment.getTitle()}, 错误: $e');
        failedCount++;
      }
      
      completedCount++;
      
      // 检查是否所有附件都处理完成
      if (completedCount == totalCount) {
        MyLogger.d('附件删除完成，成功: $successCount, 失败: $failedCount');
        
        // 通知UI更新以反映文件状态变化
        notifyListeners();
        
        // 显示删除结果
        if (failedCount == 0) {
          BrnToast.show('成功删除${successCount}个附件', context);
        } else {
          BrnToast.show('删除完成：成功${successCount}个，失败${failedCount}个', context);
        }
        
        // 执行回调
        onCallback();
      }
    }
  }

  /// 确保下载类已初始化
  Future<void> ensureDownloadHelperInitialized() async {
    final downloadHelper = ZoteroAttachDownloaderHelper.instance;

    // todo 读取本地持久化的webdav信息
    await WebdavConfiguration.loadConfiguration();

    if (!downloadHelper.isInitialized) {
      downloadHelper.initialize(_userId, _apiKey);

      // 监听WebDAV配置变化
      WebdavConfiguration.setOnChangeCallback((bool useWebdav) {
        IAttachmentTransfer transfer = ZoteroAttachmentTransfer(
            userID: _userId,
            API_KEY: _apiKey,
            attachmentStorageManager: DefaultAttachmentStorage.instance
        );
        if (useWebdav) {
          transfer = WebDAVAttachmentTransfer(
              webdavAddress: WebdavConfiguration.webdavUrl,
              username: WebdavConfiguration.userName,
              password: WebdavConfiguration.password,
              attachmentStorageManager: DefaultAttachmentStorage.instance
          );
        }
        downloadHelper.setTransfer(transfer);
        MyLogger.d('WebDAV配置已更改，使用WebDAV: $useWebdav username: ${WebdavConfiguration.userName} password: ${WebdavConfiguration.password}');
      });

      // 调用自身，确保初次使用可以通知webdav的配置变化回调
      WebdavConfiguration.setUseWebdav(WebdavConfiguration.useWebdav);
    }
  }

  // 检查已下载的附件是否被修改
  Future<void> checkModifiedAttachments() async {
    MyLogger.d('Moyear=== 检查打开过的附件是否被修改');

    final recentlyOpenedAttachments = await zoteroDB.getRecentlyOpenedAttachments();
    MyLogger.d('Moyear=== 开过的附件数量：${recentlyOpenedAttachments.length}');

    List<RecentlyOpenedAttachment> modifiedAttachments = [];
    for (var attachment in recentlyOpenedAttachments) {
      final isModified = await zoteroDB.isAttachmentModified(attachment);
      if (isModified) {
        modifiedAttachments.add(attachment);
      }
    }

    // modifiedAttachments.add(RecentlyOpenedAttachment(id: -1, itemKey: "QLTM3JVE", version: 570));

    MyLogger.d('Moyear=== 修改的附件数量：${modifiedAttachments.length}');

    if (modifiedAttachments.isNotEmpty) {
      // 获取修改的附件详细信息
      List<Item> modifiedItems = [];
      for (var attachment in modifiedAttachments) {
        final item = zoteroDB.getItemByKey(attachment.itemKey);
        if (item != null) {
          modifiedItems.add(item);
        }
      }

      if (modifiedItems.isNotEmpty && onModifiedAttachmentsFound != null) {
        // 通过回调通知UI层显示对话框
        onModifiedAttachmentsFound!(modifiedItems, modifiedAttachments);
      }
    }
  }

  // 添加回调函数类型定义
  Function(List<Item> modifiedItems, List<RecentlyOpenedAttachment> attachments)? onModifiedAttachmentsFound;

  /// 设置修改附件发现回调
  void setOnModifiedAttachmentsFoundCallback(Function(List<Item>, List<RecentlyOpenedAttachment>)? callback) {
    onModifiedAttachmentsFound = callback;
  }

  /// 开始上传修改的附件（纯数据处理，不涉及UI）
  Future<UploadResult> uploadModifiedAttachments(List<Item> modifiedItems, List<RecentlyOpenedAttachment> attachments) async {
    try {
      int successCount = 0;
      int totalCount = modifiedItems.length;
      List<String> failedItems = [];
      
      for (int i = 0; i < modifiedItems.length; i++) {
        final item = modifiedItems[i];
        try {
          await _uploadAttachment(item);
          successCount++;
          MyLogger.d('附件上传成功: ${item.getTitle()}');

          // 从最近打开的附件列表中移除，这样下次就不会再检测到修改
          await zoteroDB.removeRecentlyOpenedAttachment(item.itemKey);
        } catch (e) {
          MyLogger.e('附件上传失败: ${item.getTitle()}, 错误: $e');
          failedItems.add(item.getTitle());
        }
      }

      // // 清除修改标记
      // await _clearModifiedAttachmentsMarks(attachments);

      return UploadResult(
        successCount: successCount,
        totalCount: totalCount,
        failedItems: failedItems,
      );

    } catch (e) {
      MyLogger.e('上传附件时发生错误: $e');
      return UploadResult(
        successCount: 0,
        totalCount: modifiedItems.length,
        failedItems: modifiedItems.map((item) => item.getTitle()).toList(),
        error: e.toString(),
      );
    }
  }

  /// 上传单个附件（公开方法，供UI层调用）
  Future<void> uploadSingleAttachment(Item item) async {
    await _uploadAttachment(item);
  }

  /// 上传单个附件（内部实现）
  Future<void> _uploadAttachment(Item item) async {
    try {
      // 确保下载助手已初始化
      await ensureDownloadHelperInitialized();
      
      final downloadHelper = ZoteroAttachDownloaderHelper.instance;

      // 使用下载助手的上传功能
      await downloadHelper.uploadAttachment(item);
      
      // 更新附件的修改时间标记
      await zoteroDB.updateAttachmentAfterUpload(item);
      
    } catch (e) {
      rethrow;
    }
  }

  /// 清除修改的附件标记
  Future<void> _clearModifiedAttachmentsMarks(List<RecentlyOpenedAttachment> attachments) async {
    for (var attachment in attachments) {
      try {
        // 从最近打开的附件列表中移除，这样下次就不会再检测到修改
        await zoteroDB.removeRecentlyOpenedAttachment(attachment.itemKey);
      } catch (e) {
        MyLogger.e('清除附件修改标记失败: ${attachment.itemKey}, 错误: $e');
      }
    }
  }

  /// 仅清除修改标记，不上传
  Future<void> clearModifiedAttachmentsMarks(List<RecentlyOpenedAttachment> attachments) async {
    // await _clearModifiedAttachmentsMarks(attachments);
  }

  void onItemTap(BuildContext context, Item item) {
    if (item.isNoteItem()) {
      NoteEditManager.instance.editNoteItem(context, item);
      return;
    }

    if (_itemHasPdfAttachment(item)) {
      AttachmentStrategyManager.instance.openOrDownloadPdf(context, item);
      return;
    }

    showItemInfoDetail(context, item);
  }

  void showItemInfoDetail(BuildContext context, Item item) {
    // BrnToast.show("item: ${item.getTitle()}", context);
    // 跳转到详情页
    try {
      MyRouter.instance.pushNamed(context, "itemDetailPage", arguments: { "item": item });
    } catch (e) {
      debugPrint(e.toString());
      BrnToast.show("跳转详情页失败", context);
    }
  }

}