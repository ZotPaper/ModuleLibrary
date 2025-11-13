// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AttachmentInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentInfo _$AttachmentInfoFromJson(Map<String, dynamic> json) =>
    AttachmentInfo(
      itemKey: json['itemKey'] as String,
      groupId: (json['groupId'] as num?)?.toInt() ?? NO_GROUP_ID,
      md5Key: json['md5Key'] as String? ?? "",
      mtime: (json['mtime'] as num).toInt(),
      downloadedFrom: json['downloadedFrom'] as String? ?? AttachmentInfo.UNSET,
    );

Map<String, dynamic> _$AttachmentInfoToJson(AttachmentInfo instance) =>
    <String, dynamic>{
      'itemKey': instance.itemKey,
      'groupId': instance.groupId,
      'md5Key': instance.md5Key,
      'mtime': instance.mtime,
      'downloadedFrom': instance.downloadedFrom,
    };
