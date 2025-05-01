// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ItemInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemInfo _$ItemInfoFromJson(Map<String, dynamic> json) => ItemInfo(
      id: (json['id'] as num).toInt(),
      itemKey: json['itemKey'] as String,
      groupId: (json['groupId'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      deleted: (json['deleted'] == 1),
    );

Map<String, dynamic> _$ItemInfoToJson(ItemInfo instance) => <String, dynamic>{
      'id': instance.id,
      'itemKey': instance.itemKey,
      'groupId': instance.groupId,
      'version': instance.version,
      'deleted': instance.deleted,
    };
