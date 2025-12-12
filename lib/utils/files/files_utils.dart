import 'dart:io';
import 'package:module_library/ModuleLibrary/zotero_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../LibZoteroStorage/database/ZoteroDatabase.dart';
import '../../LibZoteroStorage/storage_provider.dart';
import '../../ModuleLibrary/utils/my_logger.dart';

class FilesUtils {

  /// 删除zotero相关的文件，目录：内部储存/zotero
  static Future deleteZoteroFiles() async {
    final appDir = await StorageProvider.getAppStorageDir();
    var zoteroDir = Directory(join(appDir?.path ?? "", "zotero"));

    if (zoteroDir.existsSync()) {
      zoteroDir.deleteSync(recursive: true);
    }
  }

  /// 删除zotero数据库
  static Future deleteZoteroDatabase() async {
    // try {
    //   // 先关闭数据库, 不然重新写入数据会有问题
    //   ZoteroProvider.getZoteroDataSql().closeDatabase();
    // } catch (e) {
    //   MyLogger.e("关闭数据库错误：$e");
    // }

    String path = join(await getDatabasesPath(), ZoteroDatabase.databaseName);
    await databaseFactory.deleteDatabase(path); // 使用工厂方法删除数据库文件
  }

}
