import 'package:module_library/ModuleLibrary/api/ZoteroDataSql.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';
import '../LibZoteroStorage/database/ZoteroDatabase.dart';
import 'api/ZoteroDataHttp.dart';

class ZoteroProvider {
  static ZoteroDB? _zoteroDB;
  static ZoteroDataSql? _zoteroDataSql;

  static ZoteroDataHttp? _zoteroHttp;

  static ZoteroDB getZoteroDB()  {
    _zoteroDB ??= ZoteroDB();
    return _zoteroDB!;
  }

  static ZoteroDataSql getZoteroDataSql()  {
    _zoteroDataSql ??= ZoteroDataSql();
    return _zoteroDataSql!;
  }

  static void initZoteroProvider(String userId, String apiKey) {
    _zoteroHttp = ZoteroDataHttp(userId: userId, apiKey: apiKey);
  }

  static ZoteroDataHttp getZoteroHttp()  {
    return _zoteroHttp!;
  }

  static void clearZoteroProvider() {
    // 释放数据库
    ZoteroDatabase.dispose();

    _zoteroDB = null;
    _zoteroDataSql = null;
    _zoteroHttp = null;
  }
}