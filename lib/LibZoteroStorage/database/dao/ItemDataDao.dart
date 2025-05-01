import '../../entity/ItemData.dart';
import '../ZoteroDatabase.dart';

class ItemDataDao {
  final ZoteroDatabase dbHelper;

  ItemDataDao(this.dbHelper);

  Future<int> insertItemData(ItemData itemData) async {
    final db = await dbHelper.database;
    final map =  itemData.toJson();
    map.remove('id');
    return await db.insert('ItemData',  map);
  }

  Future<List<ItemData>> getItemDataForParent(String parent) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ItemData',
      where: 'parent = ?',
      whereArgs: [parent],
    );
    return maps.map((map)  => ItemData.fromJson(map)).toList();
  }

  Future<int> updateItemData(ItemData itemData) async {
    final db = await dbHelper.database;
    return await db.update(
      'ItemData',
      itemData.toJson(),
      where: 'parent = ? AND name = ?',
      whereArgs: [itemData.parent, itemData.name],
    );
  }

  Future<int> deleteItemData(String parent, String name) async {
    final db = await dbHelper.database;
    return await db.delete(
      'ItemData',
      where: 'parent = ? AND name = ?',
      whereArgs: [parent, name],
    );
  }
}
