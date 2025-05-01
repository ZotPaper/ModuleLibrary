import 'package:json_annotation/json_annotation.dart';

part 'ItemCollection.g.dart';

@JsonSerializable()
class ItemCollection {
  final String collectionKey;
  final String itemKey;

  ItemCollection({
    required this.collectionKey,
    required this.itemKey,
  });

  factory ItemCollection.fromJson(Map<String, dynamic> json) =>
      _$ItemCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$ItemCollectionToJson(this);
}