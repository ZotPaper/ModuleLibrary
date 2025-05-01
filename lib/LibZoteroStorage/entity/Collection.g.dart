// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Collection _$CollectionFromJson(Map<String, dynamic> json) => Collection(
      key: json['key'] as String,
      version: (json['version'] as num).toInt(),
      name: json['name'] as String,
      parentCollection: json['parentCollection'] as String,
      groupId: (json['groupId'] as num?)?.toInt() ?? NO_GROUP_ID,
    );

Map<String, dynamic> _$CollectionToJson(Collection instance) =>
    <String, dynamic>{
      'key': instance.key,
      'version': instance.version,
      'name': instance.name,
      'parentCollection': instance.parentCollection,
      'groupId': instance.groupId,
    };
