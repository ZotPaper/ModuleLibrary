import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
part 'KeyInfo.g.dart';

@JsonSerializable()
class KeyInfo {
  // 假设 GroupPojo 有两个属性：id 和 name
  final String key;
  final int userId;
  final String username;

  KeyInfo({
    required this.key,
    required this.userId,
    required this.username,
  });

  // 生成的工厂构造函数，用于从 JSON 数据创建 GroupPojo 实例
  factory KeyInfo.fromJson(Map<String,  dynamic> json) => _$KeyInfoFromJson(json);

  // 生成的方法，用于将 GroupPojo 实例转换为 JSON 数据
  Map<String, dynamic> toJson() => _$KeyInfoToJson(this);
}