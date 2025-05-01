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

  factory ZoteroSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$ZoteroSettingsResponseFromJson(json);

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
}