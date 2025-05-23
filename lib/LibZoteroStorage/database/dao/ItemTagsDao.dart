import '../../entity/ItemTag.dart';
import '../ZoteroDatabase.dart';

class ItemTagsDao {
  final ZoteroDatabase dbHelper;

  ItemTagsDao(this.dbHelper);

  Future<List<ItemTag>> getAllTags() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ItemTags',
      // where: 'parent = ?',
      // whereArgs: [parent],
    );
    return maps.map((map)  => ItemTag.fromJson(map)).toList();
  }

  Future<int> insertItemTag(ItemTag tag) async {
    final db = await dbHelper.database;
    final map =  tag.toJson();
    map.remove('id');
    // return await db.insert('ItemTags',  map);
    return await db.rawInsert(''' 
    INSERT OR REPLACE INTO ItemTags (
      parent, tag
    ) VALUES (?, ?)
  ''', [
      tag.parent,
      tag.tag
    ]);
  }

  Future<List<ItemTag>> getTagsForParent(String parent) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ItemTags',
      where: 'parent = ?',
      whereArgs: [parent],
    );
    return maps.map((map)  => ItemTag.fromJson(map)).toList();
  }

  Future<int> deleteItemTag(String parent, String tag) async {
    final db = await dbHelper.database;
    return await db.delete(
      'ItemTags',
      where: 'parent = ? AND tag = ?',
      whereArgs: [parent, tag],
    );
  }
}

