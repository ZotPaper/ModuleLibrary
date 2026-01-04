
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:module_library/LibZoteroAttachDownloader/default_attachment_storage.dart';
import 'package:module_library/LibZoteroAttachment/model/pdf_annotation.dart';
import 'package:module_library/LibZoteroStorage/database/dao/RecentlyOpenedAttachmentDao.dart';
import 'package:module_library/LibZoteroStorage/entity/AttachmentInfo.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemData.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemTag.dart';
import 'package:module_library/ModuleLibrary/api/ZoteroDataSql.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/zotero_provider.dart';
import 'package:module_library/utils/zotero_sync_progress_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../LibZoteroStorage/entity/AttachmentInfo.dart';
import '../../LibZoteroStorage/entity/Collection.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../LibZoteroStorage/entity/Note.dart';
import '../model/zotero_item_downloaded.dart';

/// 这是存放从本地数据库加载到内存的数据存放类（全局单例类）
///
class ZoteroDB {
  // 单例模式
  static ZoteroDB _instance = ZoteroDB._internal();
  factory ZoteroDB() => _instance;
  ZoteroDB._internal() {
    MyLogger.d("Moyear=== ZoteroDB创建对象");
    /// 加载上次保存的下载进度，避免重复加载
    _loadSavedDownloadProgress();
  }

  final ZoteroDataSql _zoteroDataSql = ZoteroProvider.getZoteroDataSql();

  // 所有的条目数据
  final List<Item> _items = [];
  // 所有的条目数据
  List<Item> get items => _items;

  // 所有的合集数据
  final List<Collection> _collections = [];
  // 所有的合集数据
  List<Collection> get collections => _collections;

  Map<String, List<Item>>? itemsFromCollections;

  // 我的出版物
  final List<Item> myPublications  = [];

  // 附件数据
  final Map<String, List<Item>> _attcahmentItems = {};

  // 笔记数据
  final Map<String, List<Item>> notes = {};

  /// 回收站中的数据
  final List<Item> trashItems  = [];

  final List<ItemTag> _itemTags = [];
  List<ItemTag> get itemTags => _itemTags;

  // map that stores attachmentInfo classes by ItemKey.
  // This is used to store metadata related to items that don't go in the item database class
  // such a design was picked to seperate the data that is from the zotero api official server and
  // the metadata i store customly.
  Map<String, AttachmentInfo>? attachmentInfo;

  final attachmentStorageManager = DefaultAttachmentStorage.instance;

  // 判断是否已经加载了数据
  bool isPopulated() {
    return true;
    // return !(_collections == null || _items == null);
  }

  // 设置条目数据
  void setItems(List<Item> items) {
    _items.clear();
    _items.addAll(items);
    // Associate items with attachments and notes
    _associateItemsWithAttachments();
    // 创建集合项映射
    _createCollectionItemMap();
    // 处理条目数据
    _processItems();

    // 获取附件信息
    _zoteroDataSql.attachmentInfoDao.getAllAttachmentInfos().then((attachments) {
      attachmentInfo = HashMap<String, AttachmentInfo>();
      for (var attachment in (attachments ?? [])) {
        attachmentInfo![attachment.itemKey] = attachment;
      }
    });
  }

  void setCollections(List<Collection> collections) {
    _collections.clear();
    _collections.addAll(collections);

    /// 建立集合之间的父子关系
    _populateCollectionChildren();
    /// 建立集合项映射
    _createCollectionItemMap();

  }

  void setItemTags(List<ItemTag> itemTags) {
    _itemTags.clear();
    _itemTags.addAll(itemTags);
  }

  /// 将条目数据与附件和笔记关联起来
  void _associateItemsWithAttachments() {
    Map<String, Item> itemsByKey = {};

    // Initialize items and clear attachments/notes
    for (var item in items) {
      itemsByKey[item.itemKey] = item;

      // To avoid repeatedly adding notes and attachments during updates, nullify them
      item.attachments = [];
      item.notes = [];
    }

    for (var item in items) {
      if (item.isDownloadable()) {
        var parentKey = item.data['parentItem'];
        if (parentKey != null) {
          itemsByKey[parentKey]?.attachments?.add(item);
        }
      }

      if (item.itemType == 'note') {
        try {
          var note = Note(
            parent: item.data['parentItem'] ?? '',
            key: item.data['key'] ?? '',
            note: item.data['note'] ?? '',
            version: item.getVersion(),
          );

          // Ensure that the parent exists in the map and add the note
          if (itemsByKey.containsKey(note.parent)) {
            itemsByKey[note.parent]?.notes?.add(note);
          }
        } catch (e) {
          debugPrint('Error loading note ${item.itemKey} error: ${e.toString()}');
        }
      }
    }
  }

  void _populateCollectionChildren() {
    // Check if collections is null
    if (collections == null) {
      throw Exception("called populate collections with no collections!");
    }

    // Iterate through each collection in the list
    for (var collection in collections) {
      if (collection.hasParent()) {
        // Find the parent collection and add the sub-collection
        try {
          Collection? parentCollection = collections.firstWhere(
                (col) => col.key == collection.parentCollection
          );

          parentCollection.addSubCollection(collection);
        } catch (e) {
          MyLogger.d("Error in _populateCollectionChildren: $e");
        }
      }
    }
  }

  /// Create a map of collections and their sub-collections
  void _createCollectionItemMap() {
    // Check if items are populated
    if (!isPopulated()) {
      return;
    }

    // Initialize the map to store collections
    itemsFromCollections = {};  // Using Map<String, List<Item>> for storing collections

    for (var item in items) {
      for (var collection in item.collections) {
        // If the collection doesn't already exist in the map, create a new list
        if (!itemsFromCollections!.containsKey(collection)) {
          itemsFromCollections![collection] = [];
        }
        // Add the item to the corresponding collection
        itemsFromCollections![collection]?.add(item);
      }
    }
  }

  /// Processes the items and creates a map of collections and their items
  void _processItems() {
    // Check if items are populated
    if (!isPopulated()) {
      return;
    }

    /// 处理我的出版物
    for (var item in items) {
      if (item.data.containsKey("inPublications") && item.data["inPublications"] == "true" && !item.hasParent()) {
        myPublications.add(item);
      }
    }
  }



  /// 添加条目数据
  void addItem(Item item) {
    _items.add(item);
  }

  /// 添加合集数据
 void addCollection(Collection collection) {}
  // todo 条目以及item变化的事件监听

  List<Item> getDisplayableItems() {
    if (items != null) {
      var filtered = items.where((it) { return !it.hasParent();});
      return filtered.toList();
    } else {
      // Log.e("zotero", "error. got request for getDisplayableItems() before items has loaded.")
      return [];
    }
  }

  /// Gets all sub collections in a specific collection
  Future<List<Collection>> getSubCollectionsOf(String collectionKey) async {
    List<Collection> subCollections = [];

    for (var collection in collections) {
      if (collection.parentCollection == collectionKey) {
        subCollections.add(collection);
      }
    }

    return subCollections;
  }

  /// 获取合集下的条目
  List<Item> getItemsFromCollection(String collection) {
    // If itemsFromCollections is null, create the collection-item map
    if (itemsFromCollections == null) {
      _createCollectionItemMap();
    }

    // Return the list of items from the collection, or an empty list if not found
    return itemsFromCollections?[collection] ?? [];
  }


  /// 获取未分类条目
  List<Item> getUnfiledItems() {
    if (items != null) {
      // var filtered = items.where((it) { return !it.hasParent();});
      var filtered = getDisplayableItems().where((it) { return it.collections.isEmpty;});
      return filtered.toList();
    } else {
      // Log.e("zotero", "error. got request for getDisplayableItems() before items has loaded.")
      return [];
    }
  }

  /// 获取我的出版物
  List<Item> getMyPublicationItems() {
   return myPublications;
  }

  List<Item> getTrashedItems() {
    return trashItems;
  }

  void setTrashedItems(List<Item> items) {
    trashItems.clear();
    trashItems.addAll(items);
  }

  /// 根据key获取合集
  Collection? getCollectionByKey(String key) {
    for (var collection in collections) {
      if (collection.key == key) {
        return collection;
      }
    }
    return null;
  }

  /// 根据key获取条目item
  Item? getItemByKey(String key) {
    for (var item in items) {
      if (item.itemKey == key) {
        return item;
      }
    }
    return null;
  }

  /// 本地持久化保存，当前本次数据的版本号
  /// todo 考虑要不要集成到database里面
  Future<void> setItemsVersion(int libraryVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ItemsLibraryVersion', libraryVersion);
    MyLogger.d('setting library version $libraryVersion');
  }

  /// 设置本地持久化保存的当前的zotero设置版本号
  /// todo 考虑要不要集成到database里面
  Future<void> setZoteroSettingVersion(int settingVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ZoteroSettingVersion', settingVersion);
    debugPrint('setting zotero setting version $settingVersion');
  }

  /// 获取本地持久化保存的当前的zotero设置版本号
  Future<int> getZoteroSettingVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ZoteroSettingVersion') ?? -1;
  }


  Future<void> setLastDeletedItemsCheckVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('LastDeletedItemsCheckVersion', version);
  }

  Future<int> getLastDeletedItemsCheckVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('LastDeletedItemsCheckVersion') ?? 0;
  }

  Future<int> getLibraryVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ItemsLibraryVersion') ?? -1;
  }

  Future<int> getTrashVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('TrashLibraryVersion') ?? -1;
  }

  Future<void> setTrashVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('TrashLibraryVersion', version);
  }

  Future<void> setDownloadProgress(ItemsDownloadProgress progress) async {
    await ZoteroSyncProgressHelper.setItemsDownloadProgress(progress);
  }

  void destroyDownloadProgress() {
    ZoteroSyncProgressHelper.destroyDownloadProgress();
  }

  ItemsDownloadProgress? getDownloadProgress() {
    return ZoteroSyncProgressHelper.getItemsDownloadProgress();
  }

  /// 移动条目到回收站
  void moveItemToTrash(Item item) {
    if (!_items.contains(item)) {
      MyLogger.w("error. got request to move item to trash that is not in items list.");
      return;
    }
    _items.remove(item);
    // 更新item的itemInfo为已删除
    item.itemInfo = item.itemInfo.copyWith(deleted: true);
    trashItems.add(item);
  }

  /// 从回收站中恢复条目
  void restoreItemFromTrash(Item item) {
    if (!trashItems.contains(item)) {
      MyLogger.w("error. got request to restore item from trash that is not in trash list.");
      return;
    }
    trashItems.remove(item);
    // 更新item的itemInfo为未删除
    item.itemInfo = item.itemInfo.copyWith(deleted: false);
    _items.add(item);
  }

  /// 更新条目所属于的Collection合集
  void updateParentCollections(Item item, Set<String> parentCollections) {
    // 更新item的parentCollections
    item.collections = parentCollections.toList();
    List<String> deleted = [];

    // 找出删除的
    itemsFromCollections?.forEach((collectionKey, value) {
      var itemKeys = value.map((ele) {
        return ele.itemKey;
      });

      // 找出删除的
      if (itemKeys.contains(item.itemKey) && !parentCollections.contains(collectionKey)) {
        deleted.add(collectionKey);

        value.remove(item);
        MyLogger.d("从ZoteroDB中删除了ItemCollection[itemKey:${item.itemKey}, collectionKey:$collectionKey] ");

      }
    });

    // 找到新加的
    for (var collectionKey in parentCollections) {
      var items = itemsFromCollections?[collectionKey];
      if (items == null) {
        items = [];
        items.add(item);
        itemsFromCollections?[collectionKey] = items;
        MyLogger.d("从ZoteroDB中新增了ItemCollection[itemKey:${item.itemKey}, collectionKey:$collectionKey] ");
      } else {
        // item不存在的时候添加
        var itemKeys = items.map((ele) {
          return ele.itemKey;
        });
        if (!itemKeys.contains(item.itemKey)) {
          items.add(item);
          MyLogger.d("从ZoteroDB中新增了ItemCollection[itemKey:${item.itemKey}, collectionKey:$collectionKey] ");
        }
      }
    }
  }

  void updateParentCollection(Collection collection, String parentCollectionKey) {
    collection.parentCollection = parentCollectionKey;
  }

  /// 加载上次保存的下载进度，避免重复加载
  Future<void> _loadSavedDownloadProgress() async {
    var lastSavedDownloadProgress = await ZoteroSyncProgressHelper.getLastSavedDownloadProgress();
    MyLogger.d("_loadSavedDownloadProgress itemToDownload: ${lastSavedDownloadProgress.total}, itemDownloaded: ${lastSavedDownloadProgress.nDownloaded}, libraryVersion: ${lastSavedDownloadProgress.libraryVersion}");

    // 确保下数据正确，避免-1和0的差异导致异常
    int lastDownload = 0;
    int lastTotal = 0;
    if (lastSavedDownloadProgress.total > 0) {
      lastTotal = lastSavedDownloadProgress.total;
    }
    if (lastSavedDownloadProgress.nDownloaded > 0) {
      lastDownload = lastSavedDownloadProgress.nDownloaded;
    }

    setDownloadProgress(ItemsDownloadProgress(lastSavedDownloadProgress.libraryVersion, lastDownload, lastTotal));
  }

  Future setCollectionsVersion(int newCollectionsVersion) async {

  }

  CollectionsDownloadProgress? getCollectionsDownloadProgress() {
    return ZoteroSyncProgressHelper.getCollectionsDownloadProgress();
  }

  void setCollectionsDownloadProgress(CollectionsDownloadProgress collectionsDownloadProgress) {
    ZoteroSyncProgressHelper.setCollectionsDownloadProgress(collectionsDownloadProgress);
  }


  Future<List<PdfAnnotation>> getPdfAnnotations(String itemKey) async {
    final zoteroDataSql = ZoteroDataSql();
    final res = await zoteroDataSql.itemDataDao.getItemDataWithAttachmentKey(itemKey);

    MyLogger.d('annotations[${itemKey}] value: $res');

    final List<PdfAnnotation> annotations = [];

    for (var itemData in res) {
      if (itemData.name == "parentItem") {
        final data = await zoteroDataSql.itemDataDao.getDataForAnnotationKey(itemData.parent);
        final annotation = parsePdfAnnotation(data);
        annotations.add(annotation);
      }
    }
    return annotations;
  }

  PdfAnnotation parsePdfAnnotation(List<ItemData> data) {
    final Map<String, String> map = {};

    for (var item in data) {
      map[item.name] = item.value;
    }

    final String key = map['key'] ?? '';
    final String parentItem = map['parentItem'] ?? '';
    final int annotationPageLabel = int.tryParse(map['annotationPageLabel'] ?? '') ?? -1;
    final String annotationColor = map['annotationColor'] ?? '';
    final String annotationPosition = map['annotationPosition'] ?? '';
    final String annotationType = map['annotationType'] ?? '';
    final String annotationText = map['annotationText'] ?? '';
    final String dateAdded = map['dateAdded'] ?? '';
    final String dateModified = map['dateModified'] ?? '';
    final String annotationSortIndex = map['annotationSortIndex'] ?? '';
    final String annotationComment = map['annotationComment'] ?? '';

    final PdfAnnotation annotation = PdfAnnotation(
      key: key,
      parentItemKey: parentItem,
      pageLabel: annotationPageLabel,
      color: annotationColor,
      position: annotationPosition,
      type: annotationType,
    );

    annotation.text = annotationText;
    annotation.comment = annotationComment;
    annotation.dateAdded = dateAdded;
    annotation.dateModified = dateModified;
    annotation.sortIndex = annotationSortIndex;

    return annotation;
  }

  /// 添加到最近打开的附件
  void addRecentlyOpenedAttachments(Item attachment) {
    ZoteroDataSql zoteroDataSql = ZoteroProvider.getZoteroDataSql();
    final RecentlyOpenedAttachment recentlyOpenedAttachment = RecentlyOpenedAttachment(id: -1, itemKey: attachment.itemKey, version: attachment.getVersion());
    zoteroDataSql.recentlyOpenedAttachmentDao.insertRecentAttachment(recentlyOpenedAttachment);
  }

  /// 获取最近打开的附件
  Future<List<RecentlyOpenedAttachment>> getRecentlyOpenedAttachments() async {
    return _zoteroDataSql.recentlyOpenedAttachmentDao.getAllRecentAttachments();
  }

  /// 移除最近打开的附件
  Future<void> removeRecentlyOpenedAttachment(String itemKey) async {
    await _zoteroDataSql.recentlyOpenedAttachmentDao.deleteRecentAttachment(itemKey);
  }

  /// 更新附件上传后的状态
  Future<void> updateAttachmentAfterUpload(Item item) async {
    // 更新附件的版本信息或修改时间标记
    // 这里可以根据需要更新相关字段
    await removeRecentlyOpenedAttachment(item.itemKey);
  }

  Future<bool> isAttachmentModified(RecentlyOpenedAttachment attachment) async {
    final attachmentItem = getItemByKey(attachment.itemKey);
    if (attachmentItem == null) {
      return false;
    }

    var isExist = await attachmentStorageManager.attachmentExists(attachmentItem);
    if (!isExist) {
      return false;
    }

    /// 本地附件是否发生改变的检查逻辑
    /// 1. 获取数据库里面记录的附件md5值
    /// 2. 计算本地的当前附件的md5值
    /// 3. 如果两个值都为有效md5,且不相等，则认为附件被修改
    /// 4. todo 确定一下：如果数据库里面没有记录的md5值，但是本地附件md5有效，该如何处理
    var isModified = false;

    final md5KeyInDB = getMd5KeyInDB(attachmentItem) ?? "";
    String? calculatedMd5;
    try {
      calculatedMd5 = await attachmentStorageManager.calculateAttachItemMD5(attachmentItem);
    } catch (e) {
      MyLogger.e("zotero: validateMd5 got error $e");
    }

    MyLogger.d("Moyear=== MD5InDB: ${md5KeyInDB} calculatedMD5: $calculatedMd5");

    if (md5KeyInDB.isNotEmpty && calculatedMd5?.isNotEmpty == true && md5KeyInDB != calculatedMd5) {
      isModified = true;
    }
    return isModified;
  }

  /// 获取数据库里面记录的附件md5值
  String? getMd5KeyInDB(Item item, {bool onlyWebdav = false}) {
    if (attachmentInfo == null) {
      MyLogger.d('error attachment metadata isn\'t loaded');
      return null;
    }

    /// 获取附件条目md5的逻辑：
    /// 1. 从内存中的attachmentInfo中获取附件条目的md5值（AttachmentInfo表默认没有值，附件上传后会将其信息写入）,如果不为空直接返回;
    /// 2. 如果前一步为空，则从item.data中获取md5值；
    /// 3. 如果都为为空，则返回null
    final attachmentInfoEntry = attachmentInfo![item.itemKey];
    if (attachmentInfoEntry != null) {
      return attachmentInfoEntry.md5Key;
    }

    final md5Key = item.data['md5'];
    if (md5Key != null) {
      return md5Key;
    }
    MyLogger.d('No metadata available for ${item.itemKey}');
    return null;
  }

  /// 更新附件元数据
  /// 注意：上传附件成功后，必须要更新本地附件的元数据，否则可能造成zotero附件数据错乱
  Future<void> updateAttachmentMetadata({
    required String itemKey,
    required String md5Key,
    required int mtime,
    String downloadedFrom = AttachmentInfo.UNSET,
    int groupID = -1,
  }) async {
    // 日志输出
    MyLogger.d('zotero: adding metadata for $itemKey, $md5Key - $downloadedFrom');

    // todo 更新ttachmentInfo这个表的数据
    final attachmentInfoObj = AttachmentInfo(
      itemKey: itemKey,
      md5Key: md5Key,
      mtime: mtime,
      downloadedFrom: downloadedFrom,
    );
    attachmentInfo?[itemKey] = attachmentInfoObj;

    // 写入数据库
    await _zoteroDataSql.attachmentInfoDao.updateAttachment(attachmentInfoObj);

    // 更新附件信息
    // todo 这里不仅仅更新attachmentInfo，而是要更新内存中保存的附件md5值以及数据库中的MD5值

    final attachmentItem = getItemByKey(itemKey);
    if (attachmentItem == null) {
      MyLogger.d("updateAttachmentMetadata失败：找不到attachmentItem[itemKey: $itemKey]");
      return;
    }

    MyLogger.d("updateAttachmentMetadata before[itemKey: $itemKey， md5: ${attachmentItem.data['md5']}，version: ${attachmentItem.data['version']}  mtime: ${attachmentItem.data['mtime']}]");

    /// 更新附件的条目数据信息
    /// 比如：附件的md5、mtime、version
    /// 注意：这里面每次调用都会先查询之前的版本version，然后自动+1

    /// todo 更新内存里面的md5值,mtime,version
    attachmentItem.data['md5'] = md5Key;
    attachmentItem.data['mtime'] = mtime.toString();
    attachmentItem.data['version'] = mtime.toString();

    // todo 更新本地数据库ItemData的附件信息(md5、mtime、version)
    var data = await _zoteroDataSql.itemDataDao.getItemDataForParent(itemKey);
    for (var itemData in data) {
      var needUpdate = false;
      var newValue = "";

      if (itemData.name == 'md5') {
        needUpdate = true;
        newValue = md5Key;
      } else if (itemData.name == 'mtime') {
        needUpdate = true;
        newValue = mtime.toString();
      } else if (itemData.name == 'version') {
        needUpdate = true;
        newValue = (int.parse(itemData.value) + 1).toString();
      }

      if (needUpdate) {
        final newItemData = ItemData(
          id: itemData.id,
          parent: itemKey,
          name: itemData.name,
          value: newValue,
          valueType: itemData.valueType,
        );
        await _zoteroDataSql.itemDataDao.updateItemData(newItemData);
        MyLogger.d("updateItemData [itemKey: $itemKey, name: ${itemData.name}, value: $newValue]");
      }
    }
    MyLogger.d("updateAttachmentMetadata after[itemKey: $itemKey， md5: ${attachmentItem.data['md5']}，version: ${attachmentItem.data['version']}  mtime: ${attachmentItem.data['mtime']}]");

  }

  void dispose() {
  }

}