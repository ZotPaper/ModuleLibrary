import 'package:sqflite/sqflite.dart';

import '../../entity/AttachmentInfo.dart';
import '../ZoteroDatabase.dart';

class AttachmentInfoDao {
  final ZoteroDatabase dbHelper;

  AttachmentInfoDao(this.dbHelper);

  Future<List<AttachmentInfo>?> getAllAttachmentInfos({int? groupId = -1}) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'AttachmentInfo',
      where: 'groupId = ?',
      whereArgs: [groupId],
    );
    if (maps.isNotEmpty)  {
      return maps.map((map) => AttachmentInfo.fromJson(map)).toList();
    }
    return null;
  }

  Future<int> insertAttachment(AttachmentInfo attachment) async {
    final db = await dbHelper.database;
    final map = attachment.toJson();
    map.remove('id');
    return await db.insert('AttachmentInfo',  map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AttachmentInfo?> getAttachment(String itemKey, int groupId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'AttachmentInfo',
      where: 'itemKey = ? AND groupId = ?',
      whereArgs: [itemKey, groupId],
    );
    if (maps.isNotEmpty)  {
      return AttachmentInfo.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateAttachment(AttachmentInfo attachment) async {
    final db = await dbHelper.database;
    return await db.update(
      'AttachmentInfo',
      attachment.toJson(),
      where: 'itemKey = ? AND groupId = ?',
      whereArgs: [attachment.itemKey, attachment.groupId],
    );
  }

  Future<int> deleteAttachment(String itemKey, int groupId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'AttachmentInfo',
      where: 'itemKey = ? AND groupId = ?',
      whereArgs: [itemKey, groupId],
    );
  }
}

