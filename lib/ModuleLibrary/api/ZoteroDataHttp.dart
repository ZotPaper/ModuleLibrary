import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:module/LibZoteroStorage/entity/Collection.dart';
import 'package:module/LibZoteroStorage/entity/Creator.dart';
import 'package:module/LibZoteroStorage/entity/Item.dart';
import 'package:module/LibZoteroStorage/entity/ItemData.dart';
import 'package:module/LibZoteroStorage/entity/ItemInfo.dart';
import 'package:module/LibZoteroStorage/entity/ItemTag.dart';

import '../../LibZoteroApi/ZoteroAPI.dart';
import '../../LibZoteroApi/ZoteroAPIService.dart';

class ZoteroDataHttp{
  final String apiKey;

  late ZoteroAPI service;
  ZoteroDataHttp({required this.apiKey}){
    service = ZoteroAPI(apiKey:apiKey);
  }
  Future<List<Item>> getItems(String userId) async {
    final itemRes = await service.getItems(userId);
    List<Item> items = [];
      for (var itemJson in itemRes) {
        var itemKey = getJsonValue(itemJson, "key");
        var item = Item(
            itemInfo: ItemInfo(id: 0,
                itemKey: itemKey,
                groupId: -1,
                version: getJsonValue(itemJson, "version"), deleted: false),
            itemData: [
              // ItemData(id: 0, parent: , name: name, value: value, valueType: valueType)
            ],
            creators: [],
            tags: [],
            collections: []);
        var data = getJsonValue(itemJson, "data");
        debugPrint(data);
        List<Creator> creators  =[];
        List<ItemTag> itemTags = [];
        List<String> collections = [];
        List<ItemData> itemDatas = [];
        // Map<String, dynamic> jsonMap = json.decode(data);
        for(var key in data.keys){
          if(key == "creators"){
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
          }else if (key == "tags"){
            for(var tagJson in convertDynamicToList(getJsonValue(data, "tags"),defaultValue: [])){
              var tag = ItemTag(id: 0,
                  parent: itemKey,
                  tag: getJsonValue(tagJson,"tag"));
              itemTags.add(tag);
            }
          }else if(key == "collections"){
            for(var collectionJson in convertDynamicToList(getJsonValue(data, "collections"),defaultValue: [])){
              collections.add(collectionJson);
            }
          }else{
            debugPrint("$key  ${data[key]}");
            var itemData = ItemData(id: 0, parent: itemKey, name: key, value: data[key].toString(), valueType: data[key].runtimeType.toString());
            itemDatas.add(itemData);

          }
        }
        item.creators = creators;
        item.tags = itemTags;
        item.collections = collections;
        item.itemData = itemDatas;
        items.add(item);
      }
      for(var item in items){
        debugPrint(item.itemInfo.toString());
        debugPrint(item.creators.toString());
        debugPrint(item.tags.toString());
        debugPrint(item.collections.toString());
      }
    return items;
  }

  Future<List<Collection>> getCollections(int ifModifiedSinceVersion, String userId, int index) async {
    final itemRes = await service.getCollections(ifModifiedSinceVersion, userId, index);
    List<Collection> collections = [];
    for (var collectionPOJO in itemRes) {
      collections.add( Collection(key: collectionPOJO.key,version: collectionPOJO.version,parentCollection: collectionPOJO.collectionData.parentCollection,groupId: NO_GROUP_ID, name: collectionPOJO.collectionData.name)
          );
    }
    return collections;
  }

  List<Map<String, dynamic>> prepareData(Map<String, dynamic> jsonMap) {
    return jsonMap.entries.map((entry)  {
      return {
        'key': entry.key,
        'value': entry.value.toString(),  // 统一转为字符串存储
        'type': entry.value.runtimeType.toString(),  // 可选：记录原始类型
      };
    }).toList();
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