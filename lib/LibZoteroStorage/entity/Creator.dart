import 'package:json_annotation/json_annotation.dart';

part 'Creator.g.dart';

@JsonSerializable()
class Creator {
  final int id;
  final String parent; // itemKey of parent
  final String firstName;
  final String lastName;
  final String creatorType;
  final int order;

  Creator({
    required this.id,
    required this.parent,
    required this.firstName,
    required this.lastName,
    required this.creatorType,
    required this.order,
  });

  factory Creator.fromJson(Map<String, dynamic> json) =>
      _$CreatorFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorToJson(this);

  String makeString() {
    return '$firstName $lastName';
  }
}