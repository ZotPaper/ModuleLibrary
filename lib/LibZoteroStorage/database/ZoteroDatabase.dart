import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../entity/Collection.dart';
import '../entity/GroupInfo.dart';
class ZoteroDatabase {
  static final ZoteroDatabase _instance = ZoteroDatabase._internal();
  factory ZoteroDatabase() => _instance;
  ZoteroDatabase._internal();
  static const String _databaseName = 'zotero.db';
  static const int _databaseVersion = 1;
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) {
        return Future.wait([
          // 创建 GroupInfo 表
        db.execute(''' 
    CREATE TABLE GroupInfo (
      id INTEGER PRIMARY KEY,
      version INTEGER,
      name TEXT,
      description TEXT,
      type TEXT,
      url TEXT,
      libraryEditing TEXT,
      libraryReading TEXT,
      fileEditing TEXT,
      owner INTEGER 
    )
  '''),
          // 创建 Collections 表
          db.execute(''' 
    CREATE TABLE Collections (
      id INTEGER PRIMARY KEY,
      key TEXT UNIQUE,
      version INTEGER,
      name TEXT,
      parentCollection TEXT,
      groupId INTEGER 
    )
  '''),
          // 创建 RecentlyOpenedAttachment 表
          db.execute(''' 
    CREATE TABLE RecentlyOpenedAttachment (
      id INTEGER PRIMARY KEY,
      itemKey TEXT UNIQUE,
      version INTEGER NOT NULL DEFAULT 0 
    )
  '''),
          // 创建 ItemInfo 表
          db.execute(''' 
    CREATE TABLE ItemInfo (
      id INTEGER PRIMARY KEY, 
      itemKey TEXT NOT NULL,
      groupId INTEGER NOT NULL,
      version INTEGER NOT NULL,
      deleted INTEGER,
      UNIQUE (itemKey, groupId)
    )
  '''),
          db.execute('CREATE  UNIQUE INDEX IF NOT EXISTS index_ItemInfo_itemKey ON ItemInfo (itemKey)'),
          // 创建 ItemData 表
          db.execute(''' 
    CREATE TABLE ItemData (
      id INTEGER PRIMARY KEY,
      parent TEXT NOT NULL,
      name TEXT NOT NULL,
      value TEXT NOT NULL,
      valueType TEXT NOT NULL,
      UNIQUE (parent, name),
      FOREIGN KEY (parent) REFERENCES ItemInfo(itemKey) ON UPDATE NO ACTION ON DELETE CASCADE 
    )
  '''),
          // 创建 ItemCreator 表
          db.execute(''' 
    CREATE TABLE ItemCreator (
      id INTEGER PRIMARY KEY,
      parent TEXT NOT NULL,
      firstName TEXT NOT NULL,
      lastName TEXT NOT NULL,
      creatorType TEXT NOT NULL,
      `order` INTEGER,
      UNIQUE (parent, firstName, lastName),
      FOREIGN KEY (parent) REFERENCES ItemInfo(itemKey) ON UPDATE NO ACTION ON DELETE CASCADE 
    )
  '''),
          // 创建 ItemTags 表
          db.execute(''' 
    CREATE TABLE ItemTags (
      id INTEGER PRIMARY KEY,
      parent TEXT NOT NULL,
      tag TEXT NOT NULL,
      UNIQUE (parent, tag),
      FOREIGN KEY (parent) REFERENCES ItemInfo(itemKey) ON UPDATE NO ACTION ON DELETE CASCADE 
    )
  '''),
          // 创建 ItemCollection 表
          db.execute(''' 
    CREATE TABLE ItemCollection (
      id INTEGER PRIMARY KEY,
      collectionKey TEXT NOT NULL,
      itemKey TEXT NOT NULL,
      UNIQUE (collectionKey, itemKey),
      FOREIGN KEY (itemKey) REFERENCES ItemInfo(itemKey) ON UPDATE NO ACTION ON DELETE CASCADE 
    )
  '''),
          // 创建 AttachmentInfo 表
          db.execute(''' 
    CREATE TABLE AttachmentInfo (
      id INTEGER PRIMARY KEY,
      itemKey TEXT NOT NULL,
      groupId INTEGER NOT NULL,
      md5Key TEXT NOT NULL,
      mtime INTEGER NOT NULL,
      downloadedFrom TEXT NOT NULL,
      UNIQUE (itemKey, groupId),
      FOREIGN KEY (itemKey) REFERENCES ItemInfo(itemKey) ON UPDATE NO ACTION ON DELETE CASCADE 
    )
  ''')
        ]);
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // 处理数据库版本升级逻辑
        if (oldVersion < 2) {
          // 执行从版本 1 到 2 的迁移操作
        }
        if (oldVersion < 3) {
          // 执行从版本 2 到 3 的迁移操作
        }
        // 以此类推处理其他版本升级
      },
    );
  }


}