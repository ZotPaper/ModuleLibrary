import 'package:json_annotation/json_annotation.dart';
part 'ItemTag.g.dart';
@JsonSerializable()
class ItemTag{
  final int id;
  final String parent;
  final String tag;
  ItemTag({
    required this.id,
    required this.parent,
    required this.tag
  });
  factory ItemTag.fromJson(Map<String, dynamic> json) =>
      _$ItemTagFromJson(json);

  Map<String, dynamic> toJson() => _$ItemTagToJson(this);
}