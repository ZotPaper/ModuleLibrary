import 'dart:async';
import 'dart:collection';
import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/ModuleLibrary/model/list_entry.dart';
import 'package:module_library/ModuleLibrary/model/page_type.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';
import 'package:module_library/ModuleTagManager/item_tagmanager.dart';
import '../../LibZoteroStorage/entity/Collection.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../ModuleSync/zotero_sync_manager.dart';
import '../api/ZoteroDataHttp.dart';
import '../api/ZoteroDataSql.dart';
import '../share_pref.dart';
import '../page/LibraryUI/drawer.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class LibraryViewModel with ChangeNotifier {

  bool _initialized = false;
  bool get initialized => _initialized;

  final ZoteroDataSql zoteroDataSql = ZoteroDataSql();

  final String _userId = "16074844";
  final String _apiKey = "znrrHVJZMhSd8I9TWUxZjAFC";

  PageType curPage = PageType.library;

  String title = '';

  List<Item> _items = [];
  final List<Collection> _displayedCollections = [];

  List<Collection> get displayedCollections => _displayedCollections;

  final List<ListEntry> _listEntries = [];
  List<ListEntry> get listEntries => _listEntries;

  /// 用于过滤的关键字
  String filterText = "";

  // 当前位置的key
  String currentLocationKey = "";

  final ZoteroDB zoteroDB = ZoteroDB();

  TagManager tagManager = TagManager();

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
    setLoading(true);
    await SharedPref.init();
    bool isFirstStart = SharedPref.getBool(PrefString.isFirst, true);

    if (isFirstStart) {
      debugPrint("=============isFirstStart");
      // 切换到同步页面
      navigateToPage(PageType.sync);
    } else {
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
    }

    setLoading(false);
    _initialized = true;
  }


  void navigateToPage(PageType page) {
    curPage = page;
    notifyListeners();
  }

  /// 处理抽屉按钮点击事件
  void handleDrawerItemTap(DrawerBtn drawerBtn, {String? collectionKey}) {
    switch (drawerBtn) {
      case DrawerBtn.home:
        // showListEntriesIn("home");
        break;
      case DrawerBtn.favourites:
        // showListEntriesIn("favourites");
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
    var collections = await zoteroDataSql.getCollections();
    // 把collections保存到内存中
    zoteroDB.setCollections(collections);

    _items = await zoteroDataSql.getItems();
    // 把items保存到内存中
    zoteroDB.setItems(_items);

    // 加载回收站数据
    var deletedItems = await zoteroDataSql.getDeletedTrashes();
    zoteroDB.setTrashedItems(deletedItems);

    // 加载所有的标签数据
    var allTags = await zoteroDataSql.getAllTags();
    zoteroDB.setItemTags(allTags);

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
      default:
        // list = await _getEntriesInCollection(locationKey);
    }

    _listEntries.clear();
    _listEntries.addAll(list);

    _notifyShowItems();
    notifyListeners();

    // 记录当前位置的key
    currentLocationKey = locationKey;

    if (addToViewStack) {
      // 添加到浏览历史栈中
      _viewStack.addLast(locationKey);
    }
  }

  /// 获取我的文库页面的条目数据
  Future<List<ListEntry>> _getMyLibraryEntries() async {
    var res = zoteroDB.getDisplayableItems();
    // 对数据进行排序
    sortItems(res);

    return res.map((ele) {
      return ListEntry(item: ele);
    }).toList();

  }

  /// 获取未分类的条目
  Future<List<ListEntry>> _getUnfiledEntries() async {
    var res = zoteroDB.getUnfiledItems();
    // 对数据进行排序
    sortItems(res);

    return res.map((ele) {
      return ListEntry(item: ele);
    }).toList();
  }

  /// 处理侧边栏合集的点击事件
  Future<void> handleCollectionTap(Collection collection, {bool addToViewStack = true}) async {
    // var itemKey = collection.key;
    // var entries = await _getEntriesInCollection(itemKey);
    title = collection.name;

    var res = await zoteroDataSql.getItemsInCollection(collection.key);
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
    _listEntries.addAll(entriesCollections);
    _listEntries.addAll(entriesItems);

    _notifyShowItems();
    notifyListeners();

    // 记录当前位置的key
    currentLocationKey = collection.key;

    if (addToViewStack) {
      // 添加到浏览历史栈中
      _viewStack.addLast(collection.key);
    }
  }

  /// 获取我的出版物
  Future<List<ListEntry>>_getPublicationsEntries() async {
    var res = zoteroDB.getMyPublicationItems();
    // 对数据进行排序
    sortItems(res);

    return res.map((ele) {
      return ListEntry(item: ele);
    }).toList();
  }

  Future<List<ListEntry>> _getTrashEntries() async {
    var res = zoteroDB.getTrashedItems();
    sortItems(res);
    return res.map((ele) {
      return ListEntry(item: ele);
    }).toList();
  }

  /// 返回上一个浏览记录
  void backToPreviousPos() async {
    var locationKey = _viewStack.removeLast();
    if (locationKey.isEmpty) return;

    debugPrint('Moyear=== backToPreviousPage: $locationKey');

    switch (locationKey) {
      case 'library':
      case 'publications':
      case 'unfiled':
      case "trashes":
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
    // 根据item进行排序
    items.sort((a, b) {
      return _compereItem(a, b);
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

  /// 比较两个item
  int _compereItem(Item item1, Item item2) {
    return item1.getTitle().toLowerCase().compareTo(item2.getTitle().toLowerCase());
  }

  int _compereCollection(Collection collection1, Collection collection2) {
    return collection1.name.compareTo(collection2.name);
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
      onProgressCallback: (progress, total) {
        debugPrint("Moyear=== LibraryPage同步Item进度：$progress/$total");

        // 通知下载进度
        syncProgress = SyncProgress(progress, total);
        notifyListeners();
        // _onProgressCallback?.call(progress, total);
      },
      onFinishCallback: (items) async {
        debugPrint("Moyear=== LibraryPage同步加载Item完成，条目数量：${items.length}");

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
      case 'library':
      case 'publications':
      case 'unfiled':
      case "trashes":
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


}