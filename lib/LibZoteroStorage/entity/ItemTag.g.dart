// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ItemTag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemTag _$ItemTagFromJson(Map<String, dynamic> json) => ItemTag(
      id: (json['id'] as num).toInt(),
      parent: json['parent'] as String,
      tag: json['tag'] as String,
    );

Map<String, dynamic> _$ItemTagToJson(ItemTag instance) => <String, dynamic>{
      'id': instance.id,
      'parent': instance.parent,
      'tag': instance.tag,
    };
