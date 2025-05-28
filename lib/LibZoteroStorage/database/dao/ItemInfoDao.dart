import 'package:sqflite/sqflite.dart';

import '../../entity/ItemInfo.dart';
import '../ZoteroDatabase.dart';

class ItemInfoDao {
  final ZoteroDatabase dbHelper;

  ItemInfoDao(this.dbHelper);

  Future<int> insertItem(ItemInfo item) async {
    final db = await dbHelper.database;
    final map =  item.toJson();
    map.remove('id');
    map['deleted']= item.deleted  ? 1 : 0;
    return await db.insert('ItemInfo',  map, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<List<ItemInfo>> getItemInfos() async{
    final db = await dbHelper.database;
    final result = await db.query('ItemInfo', where: 'deleted = ?', whereArgs: [0]);
    return result.map((json)  => ItemInfo.fromJson(json)).toList();
  }
  Future<ItemInfo?> getItemInfoByKey(String itemKey) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ItemInfo',
      where: 'itemKey = ? AND deleted = ?',
      whereArgs: [itemKey, 0],
    );
    if (maps.isNotEmpty)  {
      return ItemInfo.fromJson(maps.first);
    }
    return null;
  }

  Future<List<ItemInfo>> getItemInfosByGroup(int groupId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ItemInfo',
      where: 'groupId = ?',
      whereArgs: [groupId],
    );
    return maps.map((map)  => ItemInfo.fromJson(map)).toList();
  }

  Future<int> updateItemInfo(ItemInfo item) async {
    final db = await dbHelper.database;
    return await db.update(
      'ItemInfo',
      item.toJson(),
      where: 'itemKey = ? AND groupId = ?',
      whereArgs: [item.itemKey, item.groupId],
    );
  }

  Future<int> deleteItemInfo(String itemKey, {int groupId = -1}) async {
    final db = await dbHelper.database;
    return await db.delete(
      'ItemInfo',
      where: 'itemKey = ? AND groupId = ?',
      whereArgs: [itemKey, groupId],
    );
  }

  /// 获取所有已删除的item
  Future<List<ItemInfo>> getDeletedItemInfos() async{
    final db = await dbHelper.database;
    final result = await db.query('ItemInfo', where: 'deleted = ?', whereArgs: [1]);
    return result.map((json)  => ItemInfo.fromJson(json)).toList();
  }
}
