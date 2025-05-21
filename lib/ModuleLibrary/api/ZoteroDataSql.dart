import 'package:module/LibZoteroStorage/database/ZoteroDatabase.dart';
import 'package:module/LibZoteroStorage/database/dao/CollectionsDao.dart';
import 'package:module/LibZoteroStorage/database/dao/GroupInfoDao.dart';
import 'package:module/LibZoteroStorage/entity/Collection.dart';
import 'package:module/LibZoteroStorage/entity/ItemCollection.dart';
import 'package:sqflite/sqflite.dart';
import '../../LibZoteroStorage/database/dao/AttachmentInfoDao.dart';
import '../../LibZoteroStorage/database/dao/ItemCollectionDao.dart';
import '../../LibZoteroStorage/database/dao/ItemCreatorDao.dart';
import '../../LibZoteroStorage/database/dao/ItemDataDao.dart';
import '../../LibZoteroStorage/database/dao/ItemInfoDao.dart';
import '../../LibZoteroStorage/database/dao/ItemTagsDao.dart';
import '../../LibZoteroStorage/database/dao/RecentlyOpenedAttachmentDao.dart';
import '../../LibZoteroStorage/entity/Item.dart';

class ZoteroDataSql {
  // 单例实例
  static final ZoteroDataSql _instance = ZoteroDataSql._internal();
  
  // 工厂构造函数返回单例
  factory ZoteroDataSql() => _instance;
  
  // 私有构造函数
  ZoteroDataSql._internal() {
    // 初始化所有DAO
    groupInfoDao = GroupInfoDao(_database);
    collectionsDao = CollectionsDao(_database);
    itemInfoDao = ItemInfoDao(_database);
    itemDataDao = ItemDataDao(_database);
    itemCreatorDao = ItemCreatorDao(_database);
    itemTagsDao = ItemTagsDao(_database);
    itemCollectionDao = ItemCollectionDao(_database);
    attachmentInfoDao = AttachmentInfoDao(_database);
    recentlyOpenedAttachmentDao = RecentlyOpenedAttachmentDao(_database);
  }

  final ZoteroDatabase _database = ZoteroDatabase();
  late GroupInfoDao groupInfoDao;
  late CollectionsDao collectionsDao;
  late ItemInfoDao itemInfoDao;
  late ItemDataDao itemDataDao;
  late ItemCreatorDao itemCreatorDao;
  late ItemTagsDao itemTagsDao;
  late ItemCollectionDao itemCollectionDao;
  late AttachmentInfoDao attachmentInfoDao;
  late RecentlyOpenedAttachmentDao recentlyOpenedAttachmentDao;

  /// Saves a list of items with all their related data (creators, tags, etc.)
  Future<void> saveItems(List<Item> items) async {
    // This would be implemented as a transaction for data integrity
    for (var item in items) {
      itemInfoDao.insertItem(item.itemInfo);
      for(var itemData in item.itemData){
        itemDataDao.insertItemData(itemData);
      }
      for(var creator in item.creators){
        itemCreatorDao.insertItemCreator(creator);
      }
      for(var itemTag in item.tags){
        itemTagsDao.insertItemTag(itemTag);
      }
      for(var collection in item.collections){
        itemCollectionDao.insertItemCollection(ItemCollection(collectionKey: collection, itemKey: item.itemInfo.itemKey));
      }
      for(var attachment in item.attachments){
        // attachmentInfoDao.insertAttachment(attachment);
      }
      for(var note in item.notes){

      }
    }
  }
  Future<void> saveCollections(List<Collection> collections) async {
    // This would be implemented as a transaction for data integrity
    for (var collection in collections) {
      collectionsDao.insertCollection(collection);
    }
  }
  Future<List<Collection>> getCollections() async {
    var collections = await collectionsDao.getAllCollections();
    return collections;
  }

  /// 从数据库中获取所有的条目item
  /// ⚠️ 不包含笔记、附件等信息
  Future<List<Item>> getItems({
    Function(Item item)? onNext,
    Function(List<Item> items)? onComplete,
  }) async {
    List<Item> items = [];
    var itemInfos = await itemInfoDao.getItemInfos();

    for (var itemInfo in itemInfos) {
      var itemDatas = await itemDataDao.getItemDataForParent(itemInfo.itemKey);
      var creators = await itemCreatorDao.getCreatorsForParent(itemInfo.itemKey);
      var itemTags = await itemTagsDao.getTagsForParent(itemInfo.itemKey);
      var itemCollections = await itemCollectionDao.getItemsInCollection(itemInfo.itemKey);
      var collections = itemCollections.map((data){return data.collectionKey;}).toList();
      var attachmentInfos = await attachmentInfoDao.getAttachment(itemInfo.itemKey,-1);
      var item = Item(
          itemInfo: itemInfo,
          itemData: itemDatas,
          creators: creators,
          tags: itemTags,
          collections: collections);


      items.add(item);
      onNext?.call(item);
    }
    onComplete?.call(items);
    return items;
  }

  /// Saves a single item with all its related data
  Future<void> saveItem(Item item) async {
    // await _database.transaction((txn)  async {
    //   // 1. Save the base item info
    //   await itemInfoDao.insertItem(item.info);
    //
    //   // 2. Save item data (fields)
    //   for (final data in item.data)  {
    //     await itemDataDao.insertItemData(data);
    //   }
    //
    //   // 3. Save creators
    //   for (final creator in item.creators)  {
    //     await itemCreatorDao.insertItemCreator(creator);
    //   }
    //
    //   // 4. Save tags
    //   for (final tag in item.tags)  {
    //     await itemTagsDao.insertItemTag(tag);
    //   }
    //
    //   // 5. Save collection relationships if any
    //   for (final collectionKey in item.collectionKeys)  {
    //     await itemCollectionDao.insertItemCollection(
    //       ItemCollection(
    //         id: 0, // auto-incremented
    //         collectionKey: collectionKey,
    //         itemKey: item.info.itemKey,
    //       ),
    //     );
    //   }
    //
    //   // 6. Save attachment info if present
    //   if (item.attachmentInfo  != null) {
    //     await attachmentInfoDao.insertAttachment(item.attachmentInfo!);
    //   }
    // });
  }

  /// Gets a complete item with all its related data
  Future<Item?> getItem(String itemKey) async {

  }

  /// Gets all items in a specific collection
  Future<List<Item>> getItemsInCollection(String collectionKey) async {
    final items = <Item>[];
    final itemCollections = await itemCollectionDao.getItemsInCollection(collectionKey);

    for (final ic in itemCollections) {
      final itemInfo = await itemInfoDao.getItemInfoByKey(ic.itemKey);
      if(itemInfo!=null){
          var itemDatas = await itemDataDao.getItemDataForParent(itemInfo.itemKey);
          var creators = await itemCreatorDao.getCreatorsForParent(itemInfo.itemKey);
          var itemTags = await itemTagsDao.getTagsForParent(itemInfo.itemKey);
          var itemCollections = await itemCollectionDao.getItemsInCollection(itemInfo.itemKey);
          var collections = itemCollections.map((data){return data.collectionKey;}).toList();
          var attachmentInfos = await attachmentInfoDao.getAttachment(itemInfo.itemKey,-1);
          var item = Item(
              itemInfo: itemInfo,
              itemData: itemDatas,
              creators: creators,
              tags: itemTags,
              collections: collections);
          items.add(item);
      }
    }
    return items;
  }

  /// Gets all items in a specific group
  Future<List<Item>> getItemsInGroup(int groupId) async {
    final items = <Item>[];
    final itemInfos = await itemInfoDao.getItemInfosByGroup(groupId);

    for (final info in itemInfos) {
      final item = await getItem(info.itemKey);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  /// Deletes an item and all its related data
  Future<void> deleteItem(String itemKey) async {
    // Since we have ON DELETE CASCADE for most relations, we only need to delete the main item
    // The database will take care of the rest
    // final itemInfo = await itemInfoDao.getItemByKey(itemKey);
    // if (itemInfo != null) {
    //   await itemInfoDao.deleteItem(itemKey,  itemInfo.groupId);
    // }
  }
}