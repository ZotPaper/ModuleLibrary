import '../ZoteroDatabase.dart';

class RecentlyOpenedAttachmentDao {
  final ZoteroDatabase dbHelper;

  RecentlyOpenedAttachmentDao(this.dbHelper);

  Future<int> insertRecentAttachment(RecentlyOpenedAttachment attachment) async {
    final db = await dbHelper.database;
    final map =  attachment.toMap();
    map.remove('id');
    return await db.insert('RecentlyOpenedAttachment',  map);
  }

  Future<RecentlyOpenedAttachment?> getRecentAttachment(String itemKey) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'RecentlyOpenedAttachment',
      where: 'itemKey = ?',
      whereArgs: [itemKey],
    );
    if (maps.isNotEmpty)  {
      return RecentlyOpenedAttachment.fromMap(maps.first);
    }
    return null;
  }

  Future<List<RecentlyOpenedAttachment>> getAllRecentAttachments() async {
    final db = await dbHelper.database;
    final maps = await db.query('RecentlyOpenedAttachment');
    return maps.map((map)  => RecentlyOpenedAttachment.fromMap(map)).toList();
  }

  Future<int> updateRecentAttachment(RecentlyOpenedAttachment attachment) async {
    final db = await dbHelper.database;
    return await db.update(
      'RecentlyOpenedAttachment',
      attachment.toMap(),
      where: 'itemKey = ?',
      whereArgs: [attachment.itemKey],
    );
  }

  Future<int> deleteRecentAttachment(String itemKey) async {
    final db = await dbHelper.database;
    return await db.delete(
      'RecentlyOpenedAttachment',
      where: 'itemKey = ?',
      whereArgs: [itemKey],
    );
  }
}

class RecentlyOpenedAttachment {
  final int id;
  final String itemKey;
  final int version;

  RecentlyOpenedAttachment({
    required this.id,
    required this.itemKey,
    required this.version,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemKey': itemKey,
      'version': version,
    };
  }

  factory RecentlyOpenedAttachment.fromMap(Map<String,  dynamic> map) {
    return RecentlyOpenedAttachment(
      id: map['id'],
      itemKey: map['itemKey'],
      version: map['version'],
    );
  }
}