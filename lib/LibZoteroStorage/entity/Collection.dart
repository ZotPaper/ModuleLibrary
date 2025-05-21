import 'package:json_annotation/json_annotation.dart';

import '../../LibZoteroApi/Model/CollectionPojo.dart';

part 'Collection.g.dart';

const int NO_GROUP_ID = -1;
@JsonSerializable()
class Collection {
  final String key;
  final int version;
  final String name;
  final String parentCollection;
  final int groupId;



  Collection({
    required this.key,
    required this.version,
    required this.name,
    required this.parentCollection,
    this.groupId = NO_GROUP_ID,
  });

  // 类似于 Kotlin 中的二级构造函数
  factory Collection.fromCollectionPOJO(CollectionPOJO collectionPOJO, int groupID) {
    return Collection(
      key: collectionPOJO.key,
      version: collectionPOJO.version,
      name: collectionPOJO.getName(),
      parentCollection: collectionPOJO.getParent(),
      groupId: groupID,
    );
  }

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionToJson(this);

  bool hasParent() {
    return parentCollection != "false";
  }

  List<Collection>? subCollections = [];

  /// 添加子合集
  void addSubCollection(Collection collection) {
    if (subCollections != null && subCollections?.where((it) => it.key == collection.key).isEmpty == true) {
      subCollections?.add(collection);
    }
  }
}