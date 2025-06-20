import 'package:json_annotation/json_annotation.dart';

part 'ZoteroSettingsResponse.g.dart';

@JsonSerializable()
class ZoteroSettingsResponse {
  @JsonKey(name: 'lastPageIndices')
  final Map<String, LastPageEntry>? lastPageIndices;

  @JsonKey(name: 'tagColors')
  final TagColors? tagColors;

  int lastModifiedVersion;

  ZoteroSettingsResponse({
    this.lastPageIndices,
    this.tagColors,
    this.lastModifiedVersion = -1,
  });

  /// 从 本地JSON的配置文件中 解析出 ZoteroSettingsResponse
  factory ZoteroSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$ZoteroSettingsResponseFromJson(json);

  /// 从 HTTP 响应体中解析出 ZoteroSettingsResponse
  factory ZoteroSettingsResponse.fromHttpJson(Map<String, dynamic> json) {
    final pageEntries = parseLastPageIndices(json);

    return ZoteroSettingsResponse(
      lastPageIndices: pageEntries,
      tagColors: json['tagColors'] == null
          ? null
          : TagColors.fromJson(json['tagColors'] as Map<String, dynamic>),
      lastModifiedVersion: (json['lastModifiedVersion'] as num?)?.toInt() ?? -1,
    );
  }

  static Map<String, LastPageEntry> parseLastPageIndices(Map<String, dynamic>? json) {
    final result = <String, LastPageEntry>{};
    if (json == null) {
      return result;
    }

    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key.startsWith('lastPageIndex_u_') && value is Map<String, dynamic>) {
        final itemKey = key.replaceFirst('lastPageIndex_u_', '');
        result[itemKey] = LastPageEntry.fromJson(value);
      }
    }

    return result;
  }

  Map<String, dynamic> toJson() => _$ZoteroSettingsResponseToJson(this);

  int? getLastPageIndex(String key) {
    return lastPageIndices?[key]?.value;
  }

  String? getTagColor(String name) {
    final tagColor = tagColors?.values.firstWhere(
          (element) => element.name == name,
      orElse: () => null as TagColor,
    );
    return tagColor?.color;
  }

  // ✅ 添加 copyWith 方法
  ZoteroSettingsResponse copyWith({
    Map<String, LastPageEntry>? lastPageIndices,
    TagColors? tagColors,
    int? lastModifiedVersion,
  }) {
    return ZoteroSettingsResponse(
      lastPageIndices: lastPageIndices ?? this.lastPageIndices,
      tagColors: tagColors ?? this.tagColors,
      lastModifiedVersion: lastModifiedVersion ?? this.lastModifiedVersion,
    );
  }

}

@JsonSerializable()
class LastPageEntry {
  @JsonKey(name: 'value')
  final int value;

  @JsonKey(name: 'version')
  final int version;

  LastPageEntry({
    required this.value,
    required this.version,
  });

  factory LastPageEntry.fromJson(Map<String, dynamic> json) =>
      _$LastPageEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LastPageEntryToJson(this);
}

@JsonSerializable()
class TagColors {
  @JsonKey(name: 'value')
  final List<TagColor> values;

  @JsonKey(name: 'version')
  final int version;

  TagColors({
    required this.values,
    required this.version,
  });

  factory TagColors.fromJson(Map<String, dynamic> json) =>
      _$TagColorsFromJson(json);

  Map<String, dynamic> toJson() => _$TagColorsToJson(this);
}

@JsonSerializable()
class TagColor {
  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'color')
  final String color;

  TagColor({
    required this.name,
    required this.color,
  });

  factory TagColor.fromJson(Map<String, dynamic> json) =>
      _$TagColorFromJson(json);

  Map<String, dynamic> toJson() => _$TagColorToJson(this);

  @override
  int get hashCode => Object.hash(name, color);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TagColor &&
        other.name == name &&
        other.color == color;
  }
}