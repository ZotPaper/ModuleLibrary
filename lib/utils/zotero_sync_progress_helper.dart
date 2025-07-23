import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ModuleLibrary/model/zotero_item_downloaded.dart';
import '../ModuleLibrary/share_pref.dart';

class ZoteroSyncProgressHelper {

  /// 本地下载的条目信息，用于下载变化的部分
  static Map<String, int> downloadedItemsInfo = {};

  static const String KEY_COLLECTIONS_TOTAL = "collections_total";
  static const String KEY_COLLECTIONS_DOWNLOADED = "collections_amount_downloaded";
  static const String KEY_COLLECTIONS_LIBRARY_VERSION = "collections_library_version";

  static const String KEY_ITEMS_TOTAL = "items_to_download";
  static const String KEY_ITEMS_DOWNLOADED = "items_amount_downloaded";
  static const String KEY_ITEMS_LIBRARY_VERSION = "ItemsLibraryVersion";


   static CollectionsDownloadProgress? getCollectionsDownloadProgress() {
     final nDownload = downloadedItemsInfo[KEY_COLLECTIONS_DOWNLOADED] ?? 0;
     if (nDownload == 0) return null;

     final total = downloadedItemsInfo[KEY_COLLECTIONS_TOTAL] ?? 0;
     final downloadVersion = downloadedItemsInfo[KEY_COLLECTIONS_LIBRARY_VERSION] ?? 0;
     if (total == nDownload) return null;

     return CollectionsDownloadProgress(downloadVersion, nDownload, total);
  }

  static void setCollectionsDownloadProgress(CollectionsDownloadProgress collectionsDownloadProgress) {
    downloadedItemsInfo[KEY_COLLECTIONS_DOWNLOADED] = collectionsDownloadProgress.nDownloaded;
    downloadedItemsInfo[KEY_COLLECTIONS_TOTAL] = collectionsDownloadProgress.total;
    downloadedItemsInfo[KEY_COLLECTIONS_LIBRARY_VERSION] = collectionsDownloadProgress.libraryVersion;
  }

  static ItemsDownloadProgress? getItemsDownloadProgress() {
    final nDownload = downloadedItemsInfo[KEY_ITEMS_DOWNLOADED] ?? 0;
    if (nDownload == 0) return null;

    final total = downloadedItemsInfo[KEY_ITEMS_TOTAL] ?? 0;
    final downloadVersion = downloadedItemsInfo[KEY_ITEMS_LIBRARY_VERSION] ?? 0;
    if (total == nDownload) return null;

    return ItemsDownloadProgress(downloadVersion, nDownload, total);
  }

  static Future<void> setItemsDownloadProgress(ItemsDownloadProgress progress) async {
    var last = getItemsDownloadProgress();
    MyLogger.d("上次保存的进度[${last?.nDownloaded}, ${last?.total}， ${last?.libraryVersion}] 当前[${progress.nDownloaded}, ${progress.total}， ${progress.libraryVersion}]");

    // 保存到本地
    if (progress.nDownloaded > (last?.nDownloaded ?? -1)) {
      await _saveItemsDownloadProgressToLocal(progress.nDownloaded, progress.total);
      // MyLogger.d("进度缓存到本地：[${progress.nDownloaded}, ${progress.total}]");
    }

    downloadedItemsInfo[KEY_ITEMS_DOWNLOADED] = progress.nDownloaded;
    downloadedItemsInfo[KEY_ITEMS_TOTAL] = progress.total;
    downloadedItemsInfo[KEY_ITEMS_LIBRARY_VERSION] = progress.libraryVersion;
  }

  static void destroyDownloadProgress() {
    downloadedItemsInfo.clear();
    // todo: save to prefs
    _saveItemsDownloadProgressToLocal(0, 0);
  }

  static Future<ItemsDownloadProgress> getLastSavedDownloadProgress() async {
    var total = SharedPref.getInt(KEY_ITEMS_TOTAL, 0);
    var progress = SharedPref.getInt(KEY_ITEMS_DOWNLOADED, 0);
    var libraryVersion = await getLibraryVersion();

    return ItemsDownloadProgress(libraryVersion, progress, total);
  }

  static Future<int> getLibraryVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(KEY_ITEMS_LIBRARY_VERSION) ?? -1;
  }

  static _saveItemsDownloadProgressToLocal(int progress, int total) async {
    await SharedPref.setInt(KEY_ITEMS_TOTAL, total);
    await SharedPref.setInt(KEY_ITEMS_DOWNLOADED, progress);
  }


}