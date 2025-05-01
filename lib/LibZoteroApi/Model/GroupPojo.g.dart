// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GroupPojo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupPojo _$GroupPojoFromJson(Map<String, dynamic> json) => GroupPojo(
      id: (json['id'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      groupData: GroupData.fromJson(json['groupData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupPojoToJson(GroupPojo instance) => <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'groupData': instance.groupData,
    };
