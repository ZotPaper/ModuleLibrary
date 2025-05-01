// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ItemData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemData _$ItemDataFromJson(Map<String, dynamic> json) => ItemData(
      id: (json['id'] as num).toInt(),
      parent: json['parent'] as String,
      name: json['name'] as String,
      value: json['value'] as String,
      valueType: json['valueType'] as String,
    );

Map<String, dynamic> _$ItemDataToJson(ItemData instance) => <String, dynamic>{
      'id': instance.id,
      'parent': instance.parent,
      'name': instance.name,
      'value': instance.value,
      'valueType': instance.valueType,
    };
