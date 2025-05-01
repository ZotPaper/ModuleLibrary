import 'package:json_annotation/json_annotation.dart';

part 'GroupInfo.g.dart';

@JsonSerializable()
class GroupInfo {
  final int id;
  final int version;
  final String name;
  final String description;
  final String type;
  final String url;
  final String libraryEditing;
  final String libraryReading;
  final String fileEditing;
  final int owner;

  static const int NO_GROUP_ID = -1;

  GroupInfo({
    required this.id,
    required this.version,
    required this.name,
    required this.description,
    required this.type,
    required this.url,
    required this.libraryEditing,
    required this.libraryReading,
    required this.fileEditing,
    required this.owner,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);

  Map<String, dynamic> toJson() => _$GroupInfoToJson(this);
}