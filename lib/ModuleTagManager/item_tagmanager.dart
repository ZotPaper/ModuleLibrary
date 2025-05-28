import 'package:module_library/ModuleTagManager/zotero_setting_manager.dart';

import '../LibZoteroApi/Model/ZoteroSettingsResponse.dart';

class TagManager {

  // 单例模式
  static final TagManager _instance = TagManager._internal();

  TagManager._internal();
  factory TagManager() => _instance;

  List<TagColor> _styledTags = [];
  List<TagColor> get styledTags => _styledTags;

  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
    final settings = await ZoteroSettingManager.loadSettings();

    settings.tagColors?.values.forEach((element) {
      _styledTags.add(element);
    });
    _isInit = true;
  }

  Future<List<TagColor>> getStyledTags() async {
    if (!_isInit) {
      await init();
    }
    return _styledTags;
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