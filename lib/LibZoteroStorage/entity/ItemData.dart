import 'package:json_annotation/json_annotation.dart';

part 'ItemData.g.dart';

@JsonSerializable()
class ItemData {
  final int id;
  final String parent; // itemKey of parent
  final String name;
  final String value;
  final String valueType;

  ItemData({
    required this.id,
    required this.parent,
    required this.name,
    required this.value,
    required this.valueType,
  });

  factory ItemData.fromJson(Map<String, dynamic> json) =>
      _$ItemDataFromJson(json);

  Map<String, dynamic> toJson() => _$ItemDataToJson(this);
}