import 'dart:convert';
import 'dart:io';
import 'package:module_library/LibZoteroStorage/storage_provider.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'model/my_item_entity.dart';

class MyItemFilter {
  // 单例模式
  MyItemFilter._internal();
  factory MyItemFilter() => instance;
  static final MyItemFilter instance = MyItemFilter._internal();

  // static MyItemFilter? _instance;
  final List<FilterInfo> _starredItems = [];
  final List<FilterInfo> _shieldedItems = [];

  Directory _workspace = Directory('');

  bool _isInit = false;
  bool isInit() => _isInit;

  Future<void> init() async {
    final dir = await StorageProvider.getAppStorageDir();
    _workspace = Directory('${dir!.path}/zotero');
    if (!(await _workspace.exists())) {
      await _workspace.create(recursive: true);
    }
    await _loadStarredItems();
    _isInit = true;
  }


  Future<void> ensureInit() async {
    if (_isInit) {
      return;
    }
    await init();
    _isInit = true;
  }

  Future<void> _loadStarredItems() async {
    final file = await _getStarConfigFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final list = json.decode(content) as List;
        _starredItems.addAll(list.map((e) => FilterInfo.fromJson(e)));
      }
    }
  }

  Future<File> _getStarConfigFile() async {
    final configDir = Directory('${_workspace.path}/config');
    final file = File('${configDir.path}/myStars.json');
    if (!(await configDir.exists())) await configDir.create(recursive: true);
    if (!(await file.exists())) await file.create();
    return file;
  }

  Future<File> getIgnoreConfigFile() async {
    final configDir = Directory('${_workspace.path}/config');
    final file = File('${configDir.path}/ignore.json');
    if (!(await configDir.exists())) await configDir.create(recursive: true);
    if (!(await file.exists())) await file.create();
    return file;
  }

  List<FilterInfo> getMyStars() {
    // MyLogger.d("收藏的列表数量：${_starredItems.length} 列表：$_starredItems");
    return List.unmodifiable(_starredItems);
  }

  Future<void> addToStar(FilterInfo entity) async {
    await ensureInit();
    if (_starredItems.contains(entity)) {
      MyLogger.d('The item: ${entity.itemKey} has been added to stars，no need to add again');
      return;
    }
    _starredItems.add(entity);
    MyLogger.d('Add item: ${entity.itemKey} to stars');
    await _writeStarConfig();
  }

  Future<void> removeStar(FilterInfo entity) async {
    await ensureInit();
    if (!_starredItems.contains(entity)) {
      MyLogger.d('The item: ${entity.itemKey} has not been added to stars, unable to remove it.');
      return;
    }
    // MyLogger.d("删除前收藏的列表数量：${_starredItems.length} 列表：$_starredItems");
    _starredItems.remove(entity);
    // MyLogger.d("删除后收藏的列表数量：${_starredItems.length} 列表：$_starredItems");
    MyLogger.d('Remove  $entity from stars');
    await _writeStarConfig();
  }

  bool isStarred(FilterInfo entity) {
    return _starredItems.contains(entity);
  }

  Future<void> _writeStarConfig() async {
    await ensureInit();
    final file = await _getStarConfigFile();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(_starredItems.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonStr);
    MyLogger.d('Wrote star config: $jsonStr to file: ${file.path}');
  }

// TODO: Add shield-related logic if needed



}
