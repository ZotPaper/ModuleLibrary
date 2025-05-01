import '../../entity/Creator.dart';
import '../ZoteroDatabase.dart';

class ItemCreatorDao {
  final ZoteroDatabase dbHelper;

  ItemCreatorDao(this.dbHelper);

  Future<int> insertItemCreator(Creator creator) async {
    final db = await dbHelper.database;
    final map =  creator.toJson();
    map.remove('id');
    // return await db.insert('ItemCreator', map);
    return await db.rawInsert(''' 
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

  Future<List<Creator>> getCreatorsForParent(String parent) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ItemCreator',
      where: 'parent = ?',
      whereArgs: [parent],
      orderBy: '`order` ASC',
    );
    return maps.map((map)  => Creator.fromJson(map)).toList();
  }

  Future<int> updateItemCreator(Creator creator) async {
    final db = await dbHelper.database;
    return await db.update(
      'ItemCreator',
      creator.toJson(),
      where: 'parent = ? AND firstName = ? AND lastName = ?',
      whereArgs: [creator.parent, creator.firstName,  creator.lastName],
    );
  }

  Future<int> deleteItemCreator(String parent, String firstName, String lastName) async {
    final db = await dbHelper.database;
    return await db.delete(
      'ItemCreator',
      where: 'parent = ? AND firstName = ? AND lastName = ?',
      whereArgs: [parent, firstName, lastName],
    );
  }
}

