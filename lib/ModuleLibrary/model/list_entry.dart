import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';

class ListEntry {
  Collection? collection;
  Item? item;

  ListEntry({this.collection, this.item});

  bool isCollection() {
    return collection != null;
  }

  bool isItem() {
    return item != null;
  }


}