import 'dart:convert';
import 'dart:io';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:path_provider/path_provider.dart';
import '../LibZoteroApi/Model/ZoteroSettingsResponse.dart';

typedef OnSettingChangedListener = void Function(int newVersion);

class ZoteroSettingManager {
  static const _settingsFileName = "zoterosetting.json";
  static final List<OnSettingChangedListener> _listeners = [];

  static File? _settingsFile;
  static final _lock = Object();

  static Future<void> _initSettingsFile() async {
    if (_settingsFile != null) return;

    final dir = await getAppStorageDir();


    final configDir = Directory('${dir?.path}/zotero/config');
    if (!await configDir.exists()) await configDir.create(recursive: true);

    _settingsFile = File('${configDir.path}/$_settingsFileName');
  }

  static Future<Directory?> getAppStorageDir() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }
  }


  static Future<bool> saveSettingsSync(ZoteroSettingsResponse settings) async {
    try {
      await _initSettingsFile();
      final jsonStr = jsonEncode(settings.toJson());
      await _settingsFile!.writeAsString(jsonStr);

      for (var listener in _listeners) {
        listener(settings.lastModifiedVersion);
      }

      return true;
    } catch (e) {
      MyLogger.e("Save failed: $e");
      return false;
    }
  }

  static Future<void> saveSettings(ZoteroSettingsResponse settings) async {
    await saveSettingsSync(settings);
  }

  static Future<ZoteroSettingsResponse?> loadSettingsSync() async {
    try {
      await _initSettingsFile();
      if (!await _settingsFile!.exists()) return null;

      final jsonStr = await _settingsFile!.readAsString();
      return ZoteroSettingsResponse.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      MyLogger.e("Load failed: $e");
      return null;
    }
  }

  static Future<ZoteroSettingsResponse> loadSettings() async {
    final settings = await loadSettingsSync();
    if (settings == null) {
      return  ZoteroSettingsResponse();
      // throw FileSystemException("Settings file not found");
    }
    return settings;
  }

  static Future<void> appendSettings(ZoteroSettingsResponse newSettings) async {
    final oldSettings = await loadSettingsSync();
    if (oldSettings == null) {
      return saveSettings(newSettings);
    }

    final newLastPage = {...?oldSettings.lastPageIndices};
    newSettings.lastPageIndices?.forEach((key, value) {
      newLastPage[key] = value;
    });

    final tagColors = newSettings.tagColors ?? oldSettings.tagColors;

    final merged = oldSettings.copyWith(
      lastPageIndices: newLastPage,
      tagColors: tagColors,
      lastModifiedVersion: newSettings.lastModifiedVersion > oldSettings.lastModifiedVersion
          ? newSettings.lastModifiedVersion
          : oldSettings.lastModifiedVersion,
    );

    return saveSettings(merged);
  }

  static Future<void> clearSettings() async {
    await _initSettingsFile();
    await _settingsFile?.delete();
  }

  static void addSettingChangedListener(OnSettingChangedListener listener) {
    _listeners.add(listener);
  }

  static void removeSettingChangedListener(OnSettingChangedListener listener) {
    _listeners.remove(listener);
  }

  static void removeAllSettingChangedListeners() {
    _listeners.clear();
  }
}
