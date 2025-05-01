import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';


part 'CollectionPojo.g.dart';

@JsonSerializable()
class CollectionPOJO {
  final String key;
  final int version;
  final CollectionData collectionData;

  CollectionPOJO({
    required this.key,
    required this.version,
    required this.collectionData,
  });

  String getName() {
    return collectionData.name;
  }

  bool hasParent() {
    return collectionData.parentCollection != 'false';
  }

  String getParent() {
    return collectionData.parentCollection;
  }

  factory CollectionPOJO.fromJson(Map<String, dynamic> json) =>
      _$CollectionPOJOFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionPOJOToJson(this);
}

class CollectionData {
  final String name;
  final String parentCollection;

  CollectionData({
    required this.name,
    required this.parentCollection,
  });
  factory CollectionData.fromJson(Map<String, dynamic> json) {
    return CollectionData(
      name: json['name'] as String,
      parentCollection: json['parentCollection'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parentCollection': parentCollection,
    };
  }

}

