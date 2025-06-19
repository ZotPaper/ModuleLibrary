import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:sqflite/sqflite.dart';

import '../../entity/ItemCollection.dart';
import '../ZoteroDatabase.dart';

class ItemCollectionDao {
  final ZoteroDatabase dbHelper;

  ItemCollectionDao(this.dbHelper);

  Future<int> insertItemCollection(ItemCollection itemCollection) async {
    final db = await dbHelper.database;
    final map = itemCollection.toJson();
    map.remove('id');
    return await db.insert('ItemCollection',  map, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<List<ItemCollection>> getItemCollection(String itemKey) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ItemCollection',
      where: 'itemKey = ?',
      whereArgs: [itemKey],
    );
    return maps.map((map)  => ItemCollection.fromJson(map)).toList();
  }
  Future<List<ItemCollection>> getItemsInCollection(String collectionKey) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ItemCollection',
      where: 'collectionKey = ?',
      whereArgs: [collectionKey],
    );
    return maps.map((map)  => ItemCollection.fromJson(map)).toList();
  }

  Future<int> deleteItemFromCollection(String collectionKey, String itemKey) async {
    final db = await dbHelper.database;
    return await db.delete(
      'ItemCollection',
      where: 'collectionKey = ? AND itemKey = ?',
      whereArgs: [collectionKey, itemKey],
    );
  }

  // 更新所属于的集合
  Future<int> updateParentCollections(String itemKey, Set<String> collectionKeys) async {
    var originalItemCollections = await getItemCollection(itemKey);

    // List<ItemCollection> deletedItemCollections = [];
    // List<ItemCollection> addedItemCollections = [];

    // 找出删除的
    for (var itemCollection in originalItemCollections) {
      if (!collectionKeys.contains(itemCollection.collectionKey)) {
        // deletedItemCollections.add(itemCollection);

        await deleteItemFromCollection(itemCollection.collectionKey, itemKey);
        MyLogger.d("从ItemCollectionDao中删除了ItemCollection[itemKey:$itemKey, collectionKey:${itemCollection.collectionKey}] ");
      }
    }

    // 找到新加的
    for (var collectionKey in collectionKeys) {
      if (!originalItemCollections.contains(collectionKey)) {
        await insertItemCollection(ItemCollection(collectionKey: collectionKey, itemKey: itemKey));
        MyLogger.d("从ItemCollectionDao中增加或更新了ItemCollection[itemKey:$itemKey, collectionKey:$collectionKey] ");
      }
    }

    return 1;
  }
}

