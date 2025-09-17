import 'package:module_base/stores/hive_stores.dart';
import 'package:module_library/LibZoteroStorage/stores/attachments_settings.dart';

class WebdavConfiguration {

  static AttachmentStore _setStore = Stores.get(Stores.KEY_ATTACHMENT) as AttachmentStore;

  static String _webdavUrl = "";
  static String get webdavUrl => _webdavUrl;

  static String _userName = "";
  static String get userName => _userName;

  static String _password = "";
  static String get password => _password;

  static bool _useWebdav = false;
  static bool get useWebdav => _useWebdav;

  static Function(bool enableWebdav)? _onChangeCallback;

  static void setOnChangeCallback(Function(bool enableWebdav)? onChangeCallback) {
    _onChangeCallback = onChangeCallback;
  }

  static void setUseWebdav(bool use) {
    _useWebdav = use;
    // 本地持久化变量
    _setStore.useWebDAV.set(use);
    _onChangeCallback?.call(use);
  }

  static void setWebdavConfiguration(String url, String user, String password) {
    _webdavUrl = url;
    _userName = user;
    _password = password;

    // 本地持久化变量
    _setStore.webdavAddress.set(_webdavUrl);
    _setStore.webdavUsername.set(_userName);
    _setStore.webdavPassword.set(_password);

    _onChangeCallback?.call(useWebdav);
  }

  /// 加载本地配置
  static Future<void> loadConfiguration() async {
    _webdavUrl = _setStore.webdavAddress.get();
    _userName = _setStore.webdavUsername.get();
    _password = _setStore.webdavPassword.get();
    _useWebdav = _setStore.useWebDAV.get();
  }

}