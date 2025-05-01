// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DeletedEntriesPojo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedEntriesPojo _$DeletedEntriesPojoFromJson(Map<String, dynamic> json) =>
    DeletedEntriesPojo(
      collections: (json['collections'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
      searches:
          (json['searches'] as List<dynamic>).map((e) => e as String).toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      settings:
          (json['settings'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$DeletedEntriesPojoToJson(DeletedEntriesPojo instance) =>
    <String, dynamic>{
      'collections': instance.collections,
      'items': instance.items,
      'searches': instance.searches,
      'tags': instance.tags,
      'settings': instance.settings,
    };
