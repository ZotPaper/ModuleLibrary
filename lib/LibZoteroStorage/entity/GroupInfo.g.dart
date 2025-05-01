// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GroupInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupInfo _$GroupInfoFromJson(Map<String, dynamic> json) => GroupInfo(
      id: (json['id'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      libraryEditing: json['libraryEditing'] as String,
      libraryReading: json['libraryReading'] as String,
      fileEditing: json['fileEditing'] as String,
      owner: (json['owner'] as num).toInt(),
    );

Map<String, dynamic> _$GroupInfoToJson(GroupInfo instance) => <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'url': instance.url,
      'libraryEditing': instance.libraryEditing,
      'libraryReading': instance.libraryReading,
      'fileEditing': instance.fileEditing,
      'owner': instance.owner,
    };
