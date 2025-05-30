import '../../LibZoteroStorage/entity/Collection.dart';
import '../../LibZoteroStorage/entity/Item.dart';

class FilterInfo {
  final String itemKey;
  final String name;
  final bool isCollection;

  FilterInfo({
    required this.itemKey,
    required this.name,
    required this.isCollection,
  });

  factory FilterInfo.fromJson(Map<String, dynamic> json) {
    return FilterInfo(
      itemKey: json['itemKey'],
      name: json['name'],
      isCollection: json['isCollection'],
    );
  }

  Map<String, dynamic> toJson() => {
    'itemKey': itemKey,
    'name': name,
    'isCollection': isCollection,
  };

  static FilterInfo fromItem(Item item) {
    return FilterInfo(itemKey: item.itemKey, name: item.getTitle(), isCollection: false);
  }

  static FilterInfo fromCollection(Collection collection) {
    return FilterInfo(itemKey: collection.key, name: collection.name, isCollection: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FilterInfo &&
              runtimeType == other.runtimeType &&
              itemKey == other.itemKey &&
              isCollection == other.isCollection;

  @override
  int get hashCode => itemKey.hashCode ^ isCollection.hashCode;

  @override
  String toString() {
    return "FilterInfo{itemKey: $itemKey, name: $name, isCollection: $isCollection}";
  }
}
