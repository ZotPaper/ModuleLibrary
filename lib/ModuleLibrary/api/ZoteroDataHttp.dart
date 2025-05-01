import 'package:module/LibZoteroStorage/entity/Collection.dart';
import 'package:module/LibZoteroStorage/entity/Creator.dart';
import 'package:module/LibZoteroStorage/entity/Item.dart';
import 'package:module/LibZoteroStorage/entity/ItemData.dart';
import 'package:module/LibZoteroStorage/entity/ItemInfo.dart';
import 'package:module/LibZoteroStorage/entity/ItemTag.dart';

import '../../LibZoteroApi/ZoteroAPIService.dart';

class ZoteroDataHttp{
  final String apiKey;

  late ZoteroAPIService service;
  ZoteroDataHttp({required this.apiKey}){
    service = ZoteroAPIService(api:apiKey);
  }
  Future<List<Item>> getItems(String userId) async {
    final itemRes = await service.getItems(0, userId, 0);
    if(itemRes.statusCode!=200){
      return [];
    }
    List<Item> items = [];
      for (var itemJson in itemRes.data) {
        var itemKey = getJsonValue(itemJson, "key");
        var item = Item(
            itemInfo: ItemInfo(id: 0,
                itemKey: getJsonValue(itemJson, "key"),
                groupId: 0,
                version: getJsonValue(itemJson, "version"), deleted: false),
            itemData: [
              // ItemData(id: 0, parent: , name: name, value: value, valueType: valueType)
            ],
            creators: [],
            tags: [],
            collections: []);
        var data = getJsonValue(itemJson, "data");
        print(data);
        List<Creator> creators  =[];
        print(getJsonValue(data, "creators"));
        for(var creatorJson in convertDynamicToList(getJsonValue(data, "creators"),defaultValue: []) ){
          int order = 0;
          var creator = Creator(id: 0,
              parent:itemKey,
              firstName: getJsonValue(creatorJson,"firstName"),
              lastName: getJsonValue(creatorJson,"lastName"),
              creatorType: getJsonValue(creatorJson,"creatorType"),
              order: order++);
          creators.add(creator);
        }
        List<ItemTag> itemTags = [];
        for(var tagJson in convertDynamicToList(getJsonValue(data, "tags"),defaultValue: [])){
          var tag = ItemTag(id: 0,
              parent: itemKey,
              tag: getJsonValue(tagJson,"tag"));
          itemTags.add(tag);
        }
        List<String> collections = [];
        for(var collectionJson in convertDynamicToList(getJsonValue(data, "collections"),defaultValue: [])){
          int order = 0;
          collections.add(collectionJson);
        }
        item.creators = creators;
        item.tags = itemTags;
        item.collections = collections;
        items.add(item);
      }
      for(var item in items){
        print(item.itemInfo.toString());
        print(item.creators.toString());
        print(item.tags.toString());
        print(item.collections.toString());
      }
    return items;
  }
  /// 安全获取嵌套 JSON 值
  ///
  /// [json] - 要提取值的 JSON 对象
  /// [path] - 路径字符串，用点号分隔（如 'user.address.city' ）
  /// [defaultValue] - 当路径不存在时返回的默认值
  dynamic getJsonValue(dynamic json, String path, {dynamic defaultValue}) {
    if (json == null || path.isEmpty)  return defaultValue;

    try {
      var keys = path.split('.');
      dynamic current = json;

      for (var key in keys) {
        if (current is Map && current.containsKey(key))  {
          current = current[key];
        } else if (current is List && int.tryParse(key)  != null) {
          int index = int.parse(key);
          if (index >= 0 && index < current.length)  {
            current = current[index];
          } else {
            return defaultValue;
          }
        } else {
          return defaultValue;
        }
      }

      return current ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
  List<T> convertDynamicToList<T>(dynamic json, {List<T> defaultValue = const []}) {
    if (json is List) {
      try {
        return json.cast<T>();  // 强制转换为 List<T>
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

}