import '../../entity/GroupInfo.dart';
import '../ZoteroDatabase.dart';

class GroupInfoDao {
  final ZoteroDatabase dbHelper;

  GroupInfoDao(this.dbHelper);

  Future<int> insertGroup(GroupInfo group) async {
    final db = await dbHelper.database;
    final map = group.toJson();
    map.remove('id');
    return await db.insert('GroupInfo',  map);
  }

  Future<GroupInfo?> getGroup(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'GroupInfo',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty)  {
      return GroupInfo.fromJson(maps.first);
    }
    return null;
  }

  Future<List<GroupInfo>> getAllGroups() async {
    final db = await dbHelper.database;
    final maps = await db.query('GroupInfo');
    return maps.map((map)  => GroupInfo.fromJson(map)).toList();
  }

  Future<int> updateGroup(GroupInfo group) async {
    final db = await dbHelper.database;
    return await db.update(
      'GroupInfo',
      group.toJson(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'GroupInfo',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

