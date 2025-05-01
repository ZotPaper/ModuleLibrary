import 'package:json_annotation/json_annotation.dart';

part 'DeletedEntriesPojo.g.dart';

@JsonSerializable()
class DeletedEntriesPojo {
  final List<String> collections;
  final List<String> items;
  final List<String> searches;
  final List<String> tags;
  final List<String> settings;

  DeletedEntriesPojo({
    required this.collections,
    required this.items,
    required this.searches,
    required this.tags,
    required this.settings,
  });

  factory DeletedEntriesPojo.fromJson(Map<String, dynamic> json) =>
      _$DeletedEntriesPojoFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedEntriesPojoToJson(this);
}    