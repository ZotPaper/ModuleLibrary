// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ZoteroSettingsResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZoteroSettingsResponse _$ZoteroSettingsResponseFromJson(
        Map<String, dynamic> json) =>
    ZoteroSettingsResponse(
      lastPageIndices: (json['lastPageIndices'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, LastPageEntry.fromJson(e as Map<String, dynamic>)),
      ),
      tagColors: json['tagColors'] == null
          ? null
          : TagColors.fromJson(json['tagColors'] as Map<String, dynamic>),
      lastModifiedVersion: (json['lastModifiedVersion'] as num?)?.toInt() ?? -1,
    );

Map<String, dynamic> _$ZoteroSettingsResponseToJson(
        ZoteroSettingsResponse instance) =>
    <String, dynamic>{
      'lastPageIndices': instance.lastPageIndices,
      'tagColors': instance.tagColors,
      'lastModifiedVersion': instance.lastModifiedVersion,
    };

LastPageEntry _$LastPageEntryFromJson(Map<String, dynamic> json) =>
    LastPageEntry(
      value: (json['value'] as num).toInt(),
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$LastPageEntryToJson(LastPageEntry instance) =>
    <String, dynamic>{
      'value': instance.value,
      'version': instance.version,
    };

TagColors _$TagColorsFromJson(Map<String, dynamic> json) => TagColors(
      values: (json['value'] as List<dynamic>)
          .map((e) => TagColor.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$TagColorsToJson(TagColors instance) => <String, dynamic>{
      'value': instance.values,
      'version': instance.version,
    };

TagColor _$TagColorFromJson(Map<String, dynamic> json) => TagColor(
      name: json['name'] as String,
      color: json['color'] as String,
    );

Map<String, dynamic> _$TagColorToJson(TagColor instance) => <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
    };
