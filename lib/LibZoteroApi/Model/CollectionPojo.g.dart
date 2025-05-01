// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CollectionPojo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectionPOJO _$CollectionPOJOFromJson(Map<String, dynamic> json) =>
    CollectionPOJO(
      key: json['key'] as String,
      version: (json['version'] as num).toInt(),
      collectionData: CollectionData.fromJson(
          json['collectionData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CollectionPOJOToJson(CollectionPOJO instance) =>
    <String, dynamic>{
      'key': instance.key,
      'version': instance.version,
      'collectionData': instance.collectionData,
    };
