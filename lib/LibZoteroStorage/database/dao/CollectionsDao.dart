import 'package:module/LibZoteroStorage/database/ZoteroDatabase.dart';

import '../../entity/Collection.dart';

class CollectionsDao {
  final ZoteroDatabase dbHelper;

  CollectionsDao(this.dbHelper);

  Future<int> insertCollection(Collection collection) async {
    final db = await dbHelper.database;
    final map = collection.toJson();
    map.remove('id');
    return await db.insert('Collections',  map);
  }

  Future<Collection?> getCollection(String key) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Collections',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty)  {
      return Collection.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Collection>> getAllCollections() async {
    final db = await dbHelper.database;
    final maps = await db.query('Collections');
    return maps.map((map)  => Collection.fromJson(map)).toList();
  }

  Future<int> updateCollection(Collection collection) async {
    final db = await dbHelper.database;
    return await db.update(
      'Collections',
      collection.toJson(),
      where: 'key = ?',
      whereArgs: [collection.key],
    );
  }

  Future<int> deleteCollection(String key) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Collections',
      where: 'key = ?',
      whereArgs: [key],
    );
  }
}

