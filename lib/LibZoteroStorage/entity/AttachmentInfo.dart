import 'package:json_annotation/json_annotation.dart';
import 'Collection.dart';
import 'ItemInfo.dart';

part 'AttachmentInfo.g.dart';
const String UNSET = "UNSET";
@JsonSerializable()
class AttachmentInfo {
  final String itemKey;
  final int groupId;
  final String md5Key;
  final int mtime;
  final String downloadedFrom;
  static const String WEBDAV = "WEBDAV";
  static const String ZOTEROAPI = "ZOTERO_API";
  static const String LOCALSYNC = "LOCAL_SYNC";

  AttachmentInfo({
    required this.itemKey,
    this.groupId = NO_GROUP_ID,
    this.md5Key = "",
    required this.mtime,
    this.downloadedFrom = UNSET,
  });

  factory AttachmentInfo.fromJson(Map<String, dynamic> json) =>
      _$AttachmentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentInfoToJson(this);
}

