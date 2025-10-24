import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleTagManager/zotero_setting_manager.dart';

import '../LibZoteroApi/Model/ZoteroSettingsResponse.dart';

class TagManager {

  // 单例模式
  static final TagManager _instance = TagManager._internal();

  TagManager._internal();
  factory TagManager() => _instance;

  List<TagColor> _styledTags = [];
  List<TagColor> get styledTags => _styledTags;

  ZoteroSettingManager _settingManager = ZoteroSettingManager.instance;

  bool _isInit = false;
  OnSettingChangedListener? _currentListener; // 保存当前监听器引用

  Future<void> init() async {
    if (_isInit) return;
    final settings = await _settingManager.loadSettings();

    // 使用 Set 去重，防止数据源本身包含重复标签
    final uniqueTags = <String, TagColor>{};
    for (var element in settings.tagColors?.values ?? []) {
      uniqueTags[element.name] = element; // Map 会自动去重
    }
    
    _styledTags.clear();
    _styledTags.addAll(uniqueTags.values);

    // 移除旧的监听器（如果存在）
    if (_currentListener != null) {
      _settingManager.removeSettingChangedListener(_currentListener!);
    }

    // 创建并保存新的监听器
    _currentListener = (newVersion, newSettings) {
      MyLogger.d("收到 设置变化 new $newVersion");
      
      // 使用 Set 去重
      final uniqueTags = <String, TagColor>{};
      for (var element in newSettings.tagColors?.values ?? []) {
        uniqueTags[element.name] = element;
      }
      
      _styledTags.clear();
      _styledTags.addAll(uniqueTags.values);
      
      MyLogger.d("更新后的精选标签数量: ${_styledTags.length}");
    };
    
    _settingManager.addSettingChangedListener(_currentListener!);

    _isInit = true;
    MyLogger.d("TagManager 初始化完成，精选标签数量: ${_styledTags.length}");
  }

  Future<List<TagColor>> getStyledTags() async {
    if (!_isInit) {
      await init();
    }
    // 返回副本，避免外部修改影响内部数据
    return List<TagColor>.from(_styledTags);
  }

  Future<TagColor?> foundInImportantTag(String tag) async {
    List<TagColor> styledTags = await getStyledTags();

    for (var styledTag in styledTags) {
      if (styledTag.name == tag) {
        return Future.value(styledTag);
      }
    }
    return Future.value(null);
  }



}