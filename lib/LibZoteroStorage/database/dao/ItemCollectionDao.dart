import '../../entity/ItemCollection.dart';
import '../ZoteroDatabase.dart';

class ItemCollectionDao {
  final ZoteroDatabase dbHelper;

  ItemCollectionDao(this.dbHelper);

  Future<int> insertItemCollection(ItemCollection itemCollection) async {
    final db = await dbHelper.database;
    final map = itemCollection.toJson();
    map.remove('id');
    return await db.insert('ItemCollection',  map);
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
}

