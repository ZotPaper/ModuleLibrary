import 'package:module_library/ModuleLibrary/api/ZoteroDataSql.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';

class ZoteroProvider {
  static ZoteroDB? _zoteroDB;
  static ZoteroDataSql? _zoteroDataSql;


  static ZoteroDB getZoteroDB()  {
    _zoteroDB ??= ZoteroDB();
    return _zoteroDB!;
  }

  static ZoteroDataSql getZoteroDataSql()  {
    _zoteroDataSql ??= ZoteroDataSql();
    return _zoteroDataSql!;
  }


}