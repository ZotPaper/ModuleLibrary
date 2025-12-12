import 'package:flutter/cupertino.dart';
import 'package:module_library/LibZoteroStorage/database/ZoteroDatabase.dart';
import 'package:module_library/LibZoteroStorage/database/dao/CollectionsDao.dart';
import 'package:module_library/LibZoteroStorage/database/dao/GroupInfoDao.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemCollection.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemInfo.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemTag.dart';
import 'package:module_library/ModuleLibrary/utils/my_fun_tracer.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:sqflite/sqflite.dart';
import '../../LibZoteroStorage/database/dao/AttachmentInfoDao.dart';
import '../../LibZoteroStorage/database/dao/ItemCollectionDao.dart';
import '../../LibZoteroStorage/database/dao/ItemCreatorDao.dart';
import '../../LibZoteroStorage/database/dao/ItemDataDao.dart';
import '../../LibZoteroStorage/database/dao/ItemInfoDao.dart';
import '../../LibZoteroStorage/database/dao/ItemTagsDao.dart';
import '../../LibZoteroStorage/database/dao/RecentlyOpenedAttachmentDao.dart';
import '../../LibZoteroStorage/entity/AttachmentInfo.dart';
import '../../LibZoteroStorage/entity/Creator.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../LibZoteroStorage/entity/ItemData.dart';

class ZoteroDataSql {
  // 单例实例
  static final ZoteroDataSql _instance = ZoteroDataSql._internal();
  
  // 工厂构造函数返回单例
  factory ZoteroDataSql() => _instance;
  
  // 私有构造函数
  ZoteroDataSql._internal() {
    MyLogger.d("Moyear=== ZoteroDataSql创建对象");

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

  // 添加一个锁来防止并发保存操作
  static bool _isSaving = false;
  static final List<Item> _pendingItems = [];

  /// 保存Items列表 - 使用事务和批量操作优化
  Future<void> saveItems(List<Item> items) async {
    if (items.isEmpty) return;

    MyLogger.d("开始保存 ${items.length} 个items");
    MyFunTracer.beginTrace(customKey: "saveItems_${items.length}");

    try {
      // 使用锁防止并发保存
      if (_isSaving) {
        MyLogger.d("检测到并发保存，将items加入待处理队列");
        _pendingItems.addAll(items);
        return;
      }

      _isSaving = true;
      final allItemsToSave = List<Item>.from(items);
      
      // 处理待处理队列中的items
      if (_pendingItems.isNotEmpty) {
        allItemsToSave.addAll(_pendingItems);
        _pendingItems.clear();
        MyLogger.d("合并待处理队列，总共保存 ${allItemsToSave.length} 个items");
      }

      await _saveItemsWithTransaction(allItemsToSave);
      
    } finally {
      _isSaving = false;
      MyFunTracer.endTrace(customKey: "saveItems_${items.length}");
    }
  }

  /// 使用数据库事务批量保存Items
  Future<void> _saveItemsWithTransaction(List<Item> items) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      MyFunTracer.beginTrace(customKey: "transaction_save_${items.length}");
      
      try {
        // 批量保存ItemInfo
        for (final item in items) {
          final itemInfoMap = item.itemInfo.toJson();
          itemInfoMap.remove('id');
          itemInfoMap['deleted'] = item.itemInfo.deleted ? 1 : 0;
          
          await txn.insert(
            'ItemInfo', 
            itemInfoMap, 
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // 批量保存ItemData
        for (final item in items) {
          for (final itemData in item.itemData) {
            final dataMap = itemData.toJson();
            dataMap.remove('id');
            
            await txn.insert(
              'ItemData', 
              dataMap, 
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // 批量保存Creators
        for (final item in items) {
          for (final creator in item.creators) {
            await txn.rawInsert('''
              INSERT OR REPLACE INTO ItemCreator (
                parent, firstName, lastName, creatorType, "order"
              ) VALUES (?, ?, ?, ?, ?)
            ''', [
              creator.parent,
              creator.firstName,
              creator.lastName,
              creator.creatorType,
              creator.order
            ]);
          }
        }

        // 批量保存Tags
        for (final item in items) {
          for (final tag in item.tags) {
            await txn.rawInsert('''
              INSERT OR REPLACE INTO ItemTags (
                parent, tag
              ) VALUES (?, ?)
            ''', [
              tag.parent,
              tag.tag
            ]);
          }
        }

        // 批量保存Collections关系
        for (final item in items) {
          for (final collectionKey in item.collections) {
            final collectionMap = {
              'collectionKey': collectionKey,
              'itemKey': item.itemInfo.itemKey,
            };
            
            await txn.insert(
              'ItemCollection', 
              collectionMap, 
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        MyLogger.d("事务批量保存完成: ${items.length} 个items");
        
      } catch (e) {
        MyLogger.e("批量保存失败: $e");
        rethrow;
      } finally {
        MyFunTracer.endTrace(customKey: "transaction_save_${items.length}");
      }
    });
  }

  /// 单个Item保存方法 - 现在也使用事务
  Future<void> saveItem(Item item) async {
    await saveItems([item]);
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

  /// 从数据库中获取所有的条目item (优化版本)
  /// ⚠️ 不包含笔记、附件等信息
  Future<List<Item>> getItems({
    Function(Item item)? onNext,
    Function(List<Item> items)? onComplete,
  }) async {
    MyFunTracer.beginTrace(customKey: "getItems_optimized");

    try {
      // 使用优化的批量查询方法
      final items = await getItemsOptimized(onNext: onNext);
      onComplete?.call(items);
      return items;
    } finally {
      MyFunTracer.endTrace(customKey: "getItems_optimized");
    }
  }

  /// 优化的获取Items方法，使用批量查询替代N+1查询
  Future<List<Item>> getItemsOptimized({
    Function(Item item)? onNext,
  }) async {
    final db = await _database.database;
    
    MyFunTracer.beginTrace(customKey: "batch_queries");

    // 1. 获取所有ItemInfo
    final itemInfos = await itemInfoDao.getItemInfos();
    if (itemInfos.isEmpty) return [];

    // 提取所有itemKeys用于批量查询
    final itemKeys = itemInfos.map((info) => info.itemKey).toList();
    final itemKeysStr = itemKeys.map((key) => "'$key'").join(',');

    // 2. 批量获取所有ItemData
    final itemDataResults = await db.rawQuery('''
      SELECT * FROM ItemData 
      WHERE parent IN ($itemKeysStr)
      ORDER BY parent
    ''');

    // 3. 批量获取所有Creators
    final creatorResults = await db.rawQuery('''
      SELECT * FROM ItemCreator 
      WHERE parent IN ($itemKeysStr)
      ORDER BY parent, "order" ASC
    ''');

    // 4. 批量获取所有Tags
    final tagResults = await db.rawQuery('''
      SELECT * FROM ItemTags 
      WHERE parent IN ($itemKeysStr)
      ORDER BY parent
    ''');

    // 5. 批量获取所有Collections关系
    final collectionResults = await db.rawQuery('''
      SELECT * FROM ItemCollection 
      WHERE itemKey IN ($itemKeysStr)
      ORDER BY itemKey
    ''');

    // 6. 批量获取所有AttachmentInfo
    final attachmentResults = await db.rawQuery('''
      SELECT * FROM AttachmentInfo 
      WHERE itemKey IN ($itemKeysStr)
      ORDER BY itemKey
    ''');

    MyFunTracer.endTrace(customKey: "batch_queries");

    MyFunTracer.beginTrace(customKey: "organize_data");

    // 组织数据到Map中，按itemKey分组
    final itemDataMap = <String, List<ItemData>>{};
    final creatorsMap = <String, List<Creator>>{};
    final tagsMap = <String, List<ItemTag>>{};
    final collectionsMap = <String, List<String>>{};
    final attachmentsMap = <String, AttachmentInfo?>{};

    // 处理ItemData
    for (final row in itemDataResults) {
      final itemData = ItemData.fromJson(row);
      itemDataMap.putIfAbsent(itemData.parent, () => []).add(itemData);
    }

    // 处理Creators
    for (final row in creatorResults) {
      final creator = Creator.fromJson(row);
      creatorsMap.putIfAbsent(creator.parent, () => []).add(creator);
    }

    // 处理Tags
    for (final row in tagResults) {
      final tag = ItemTag.fromJson(row);
      tagsMap.putIfAbsent(tag.parent, () => []).add(tag);
    }

    // 处理Collections
    for (final row in collectionResults) {
      final itemCollection = ItemCollection.fromJson(row);
      collectionsMap.putIfAbsent(itemCollection.itemKey, () => [])
          .add(itemCollection.collectionKey);
    }

    // 处理Attachments
    for (final row in attachmentResults) {
      final attachment = AttachmentInfo.fromJson(row);
      attachmentsMap[attachment.itemKey] = attachment;
    }

    MyFunTracer.endTrace(customKey: "organize_data");

    MyFunTracer.beginTrace(customKey: "build_items");

    // 构建Item对象
    final items = <Item>[];
    for (final itemInfo in itemInfos) {
      final itemKey = itemInfo.itemKey;
      
      final item = Item(
        itemInfo: itemInfo,
        itemData: itemDataMap[itemKey] ?? [],
        creators: creatorsMap[itemKey] ?? [],
        tags: tagsMap[itemKey] ?? [],
        collections: collectionsMap[itemKey] ?? [],
      );

      items.add(item);
      onNext?.call(item);
    }

    MyFunTracer.endTrace(customKey: "build_items");

    return items;
  }

  /// 超级优化版本：使用单个JOIN查询获取最常用的数据
  /// 适用于只需要基本信息的场景（标题、作者、类型等）
  Future<List<Item>> getItemsUltraOptimized({
    Function(Item item)? onNext,
  }) async {
    final db = await _database.database;
    
    MyFunTracer.beginTrace(customKey: "ultra_optimized_query");

    // 使用LEFT JOIN一次性获取Item的基本信息和最重要的字段
    final results = await db.rawQuery('''
      SELECT 
        i.id as item_id,
        i.itemKey,
        i.groupId,
        i.version,
        i.deleted,
        d1.value as title,
        d2.value as itemType,
        d3.value as dateAdded,
        d4.value as dateModified
      FROM ItemInfo i
      LEFT JOIN ItemData d1 ON i.itemKey = d1.parent AND d1.name = 'title'
      LEFT JOIN ItemData d2 ON i.itemKey = d2.parent AND d2.name = 'itemType'
      LEFT JOIN ItemData d3 ON i.itemKey = d3.parent AND d3.name = 'dateAdded'
      LEFT JOIN ItemData d4 ON i.itemKey = d4.parent AND d4.name = 'dateModified'
      WHERE i.deleted = 0
      ORDER BY i.itemKey
    ''');

    MyFunTracer.endTrace(customKey: "ultra_optimized_query");

    MyFunTracer.beginTrace(customKey: "build_lightweight_items");

    final items = <Item>[];
    for (final row in results) {
      final itemInfo = ItemInfo(
        id: row['item_id'] as int,
        itemKey: row['itemKey'] as String,
        groupId: row['groupId'] as int,
        version: row['version'] as int,
        deleted: (row['deleted'] as int) == 1,
      );

      // 构建基本的ItemData
      final itemData = <ItemData>[];
      if (row['title'] != null) {
        itemData.add(ItemData(
          id: 0,
          parent: itemInfo.itemKey,
          name: 'title',
          value: row['title'] as String,
          valueType: 'String',
        ));
      }
      if (row['itemType'] != null) {
        itemData.add(ItemData(
          id: 0,
          parent: itemInfo.itemKey,
          name: 'itemType',
          value: row['itemType'] as String,
          valueType: 'String',
        ));
      }
      if (row['dateAdded'] != null) {
        itemData.add(ItemData(
          id: 0,
          parent: itemInfo.itemKey,
          name: 'dateAdded',
          value: row['dateAdded'] as String,
          valueType: 'String',
        ));
      }
      if (row['dateModified'] != null) {
        itemData.add(ItemData(
          id: 0,
          parent: itemInfo.itemKey,
          name: 'dateModified',
          value: row['dateModified'] as String,
          valueType: 'String',
        ));
      }

      final item = Item(
        itemInfo: itemInfo,
        itemData: itemData,
        creators: [], // 如果需要可以后续加载
        tags: [], // 如果需要可以后续加载
        collections: [], // 如果需要可以后续加载
      );

      items.add(item);
      onNext?.call(item);
    }

    MyFunTracer.endTrace(customKey: "build_lightweight_items");

    return items;
  }

  /// 分页获取Items，避免一次性加载太多数据
  Future<List<Item>> getItemsPaged({
    int offset = 0,
    int limit = 100,
    Function(Item item)? onNext,
  }) async {
    final db = await _database.database;

    // 分页获取ItemInfo
    final itemInfoResults = await db.rawQuery('''
      SELECT * FROM ItemInfo 
      WHERE deleted = 0
      ORDER BY itemKey
      LIMIT ? OFFSET ?
    ''', [limit, offset]);

    if (itemInfoResults.isEmpty) return [];

    final itemInfos = itemInfoResults.map((row) => ItemInfo.fromJson(row)).toList();
    final itemKeys = itemInfos.map((info) => info.itemKey).toList();
    final itemKeysStr = itemKeys.map((key) => "'$key'").join(',');

    // 批量获取相关数据（复用上面的逻辑）
    final itemDataResults = await db.rawQuery('''
      SELECT * FROM ItemData 
      WHERE parent IN ($itemKeysStr)
      ORDER BY parent
    ''');

    final creatorResults = await db.rawQuery('''
      SELECT * FROM ItemCreator 
      WHERE parent IN ($itemKeysStr)
      ORDER BY parent, "order" ASC
    ''');

    final tagResults = await db.rawQuery('''
      SELECT * FROM ItemTags 
      WHERE parent IN ($itemKeysStr)
      ORDER BY parent
    ''');

    final collectionResults = await db.rawQuery('''
      SELECT * FROM ItemCollection 
      WHERE itemKey IN ($itemKeysStr)
      ORDER BY itemKey
    ''');

    // 组织数据并构建Item对象（复用上面的逻辑）
    final itemDataMap = <String, List<ItemData>>{};
    final creatorsMap = <String, List<Creator>>{};
    final tagsMap = <String, List<ItemTag>>{};
    final collectionsMap = <String, List<String>>{};

    for (final row in itemDataResults) {
      final itemData = ItemData.fromJson(row);
      itemDataMap.putIfAbsent(itemData.parent, () => []).add(itemData);
    }

    for (final row in creatorResults) {
      final creator = Creator.fromJson(row);
      creatorsMap.putIfAbsent(creator.parent, () => []).add(creator);
    }

    for (final row in tagResults) {
      final tag = ItemTag.fromJson(row);
      tagsMap.putIfAbsent(tag.parent, () => []).add(tag);
    }

    for (final row in collectionResults) {
      final itemCollection = ItemCollection.fromJson(row);
      collectionsMap.putIfAbsent(itemCollection.itemKey, () => [])
          .add(itemCollection.collectionKey);
    }

    final items = <Item>[];
    for (final itemInfo in itemInfos) {
      final itemKey = itemInfo.itemKey;
      
      final item = Item(
        itemInfo: itemInfo,
        itemData: itemDataMap[itemKey] ?? [],
        creators: creatorsMap[itemKey] ?? [],
        tags: tagsMap[itemKey] ?? [],
        collections: collectionsMap[itemKey] ?? [],
      );

      items.add(item);
      onNext?.call(item);
    }

    return items;
  }

  /// Gets a complete item with all its related data
  Future<Item?> getItem(String itemKey) async {

  }

  Future<List<ItemTag>> getAllTags() async {
    final tags = await itemTagsDao.getAllTags();
    return tags;
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

  /// Moves an item to the trash
  Future<void> moveItemToTrash(Item item) async {
    // 首先在数据库中，确定是否存在该条目数据, 如果不存在，先把该条目写入数据库，再标记为删除
    var isExist = await itemInfoDao.getItemInfoByKey(item.itemKey) != null;

    if (!isExist) {
      debugPrint("Moyear=== moveItemToTrash: item [${item.itemKey}] not exist, save it first");
      await saveItems([item]);
    }

    final itemInfo = await itemInfoDao.getItemInfoByKey(item.itemKey);

    if (itemInfo != null) {
      final deletedItem = itemInfo.copyWith(deleted: true);
      // 数据库标记为删除
      var res = itemInfoDao.updateItemInfo(deletedItem);
    }

  }

  /// todo Deletes an item and all its related data
  Future<void> deleteItem(String itemKey) async {
    // todo 实现该方法
    // Since we have ON DELETE CASCADE for most relations, we only need to delete the main item
    // The database will take care of the rest
    final itemInfo = await itemInfoDao.getItemInfoByKey(itemKey);
    if (itemInfo != null) {
      await itemInfoDao.deleteItemInfo(itemKey, groupId: itemInfo.groupId);
    }

    // todo 是否要删除ItemData的方法
    itemDataDao.deleteItemDataOf(itemKey);
    
  }

  /// Deletes a collection
  Future<void> deleteCollection(String collectionKey) async {
    final collection = await collectionsDao.getCollection(collectionKey);
    if (collection != null) {
      await collectionsDao.deleteCollection(collectionKey);
    }
  }


  Future<List<Item>> getDeletedTrashes({
    Function(Item item)? onNext,
    Function(List<Item> items)? onComplete,
  }) async {

    List<Item> items = [];
    final itemInfos = await itemInfoDao.getDeletedItemInfos();

    for (var itemInfo in itemInfos) {
      var itemDatas = await itemDataDao.getItemDataForParent(itemInfo.itemKey);
      var creators = await itemCreatorDao.getCreatorsForParent(itemInfo.itemKey);
      var itemTags = await itemTagsDao.getTagsForParent(itemInfo.itemKey);
      //  找到这个item属于的collection集合
      var itemCollections = await itemCollectionDao.getItemCollection(itemInfo.itemKey);
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

  void dispose() {
    _database.close();
  }
}