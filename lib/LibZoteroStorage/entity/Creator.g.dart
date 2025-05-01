// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Creator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Creator _$CreatorFromJson(Map<String, dynamic> json) => Creator(
      id: (json['id'] as num).toInt(),
      parent: json['parent'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      creatorType: json['creatorType'] as String,
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$CreatorToJson(Creator instance) => <String, dynamic>{
      'id': instance.id,
      'parent': instance.parent,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'creatorType': instance.creatorType,
      'order': instance.order,
    };
