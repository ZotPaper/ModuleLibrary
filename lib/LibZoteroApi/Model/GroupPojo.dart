import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
part 'GroupPojo.g.dart';

@JsonSerializable()
class GroupPojo {
  // 假设 GroupPojo 有两个属性：id 和 name
  final int id;
  final int version;
  final GroupData groupData;

  GroupPojo({
    required this.id,
    required this.version,
    required this.groupData,
  });

  // 生成的工厂构造函数，用于从 JSON 数据创建 GroupPojo 实例
  factory GroupPojo.fromJson(Map<String,  dynamic> json) => _$GroupPojoFromJson(json);

  // 生成的方法，用于将 GroupPojo 实例转换为 JSON 数据
  Map<String, dynamic> toJson() => _$GroupPojoToJson(this);
}

class GroupData {
  final int id;
  final String name;
  final String type;
  final String description;
  final int owner;
  final String url;
  final String libraryEditing;
  final String libraryReading;
  final String fileEditing;

  GroupData({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.owner,
    required this.url,
    required this.libraryEditing,
    required this.libraryReading,
    required this.fileEditing,
  });

  factory GroupData.fromJson(Map<String, dynamic> json) {
    return GroupData(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      owner: json['owner'] as int,
      url: json['url'] as String,
      libraryEditing: json['libraryEditing'] as String,
      libraryReading: json['libraryReading'] as String,
      fileEditing: json['fileEditing'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'owner': owner,
      'url': url,
      'libraryEditing': libraryEditing,
      'libraryReading': libraryReading,
      'fileEditing': fileEditing,
    };
  }
}