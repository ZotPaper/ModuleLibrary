import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageProvider {

  /// 获取应用存储目录，根据不同的平台获取不同的目录
  static Future<Directory?> getAppStorageDir() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    } else {
      return null;
    }
  }


}