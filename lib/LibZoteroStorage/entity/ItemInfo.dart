import 'package:json_annotation/json_annotation.dart';
part 'ItemInfo.g.dart';
@JsonSerializable()
class ItemInfo{
  final int id;
  final String itemKey;
  final int groupId;
  final int version;
  final bool deleted;
  ItemInfo({
    required this.id,
    required this.itemKey,
    required this.groupId,
    required this.version,
    required this.deleted
  });
  factory ItemInfo.fromJson(Map<String, dynamic> json) =>
      _$ItemInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ItemInfoToJson(this);

  // 添加 copyWith 方法
  ItemInfo copyWith({bool? deleted}) {
    return ItemInfo(
      id: id,
      itemKey: itemKey,
      groupId: groupId,
      version: version,
      deleted: deleted ?? this.deleted,
    );
  }
}