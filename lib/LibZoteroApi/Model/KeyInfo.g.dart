// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'KeyInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyInfo _$KeyInfoFromJson(Map<String, dynamic> json) => KeyInfo(
      key: json['key'] as String,
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String,
    );

Map<String, dynamic> _$KeyInfoToJson(KeyInfo instance) => <String, dynamic>{
      'key': instance.key,
      'userId': instance.userId,
      'username': instance.username,
    };
