import 'package:flutter/cupertino.dart';
import 'package:module/LibZoteroStorage/entity/Collection.dart';
import 'package:module/LibZoteroStorage/entity/Creator.dart';
import 'package:module/LibZoteroStorage/entity/Item.dart';
import 'package:module/LibZoteroStorage/entity/ItemData.dart';
import 'package:module/LibZoteroStorage/entity/ItemInfo.dart';
import 'package:module/LibZoteroStorage/entity/ItemTag.dart';

import '../../LibZoteroApi/ZoteroAPI.dart';

class ZoteroDataHttp {
  final String apiKey;

  late ZoteroAPI service;

  ZoteroDataHttp({required this.apiKey}) {
    service = ZoteroAPI(apiKey: apiKey);
  }

  /// 获取zotero所有的条目,
  /// 注意：是全量数据
  Future<List<Item>> getItems(String userId,
      {Function(int progress, int total)? onProgress,
      Function(List<Item>)? onFinish,
      Function(int errorCode, String msg)? onError}) async {
    // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
    final response = await service.getItems(userId);
    if (response == null) {
      return [];
    }

    final items = <Item>[];
    final total = response.totalResults;
    int downloadedCount = 0;

    // 处理第一页数据
    await _processPage(response.data, items, total, downloadedCount, onProgress, onFinish);

    // 继续下载剩余页面
    while (downloadedCount < total) {
      final pagedResponse = await service.getItems(userId, startIndex: downloadedCount);
      if (pagedResponse == null) {
        continue;
      }
      await _processPage(pagedResponse.data, items, total, downloadedCount, onProgress, onFinish);
    }

    return items;
  }

  Future<void> _processPage(List<dynamic> pageData, List<Item> items, int total, int downloadedCount,
      Function(int progress, int total)? onProgress, Function(List<Item>)? onFinish) async {
    for (int i = 0; i < pageData.length; i++) {
      var itemJson = pageData[i] ?? "";
      debugPrint("Moyear==== index $i itemJson: $itemJson");

      Item item = organizeItem(itemJson);
      items.add(item);
      downloadedCount++;

      if (i == total - 1) {
        onFinish?.call(items);
      } else {
        onProgress?.call(downloadedCount, total);
      }
    }
  }

  Future<List<Collection>> getCollections(
      int ifModifiedSinceVersion, String userId, int index) async {
    final itemRes =
        await service.getCollections(ifModifiedSinceVersion, userId, index);
    List<Collection> collections = [];

    for (var collectionPOJO in itemRes) {
      collections.add(Collection(
          key: collectionPOJO.key,
          version: collectionPOJO.version,
          parentCollection: collectionPOJO.collectionData.parentCollection,
          groupId: NO_GROUP_ID,
          name: collectionPOJO.collectionData.name));
    }
    return collections;
  }

  List<Map<String, dynamic>> prepareData(Map<String, dynamic> jsonMap) {
    return jsonMap.entries.map((entry) {
      return {
        'key': entry.key,
        'value': entry.value.toString(), // 统一转为字符串存储
        'type': entry.value.runtimeType.toString(), // 可选：记录原始类型
      };
    }).toList();
  }

  /// 安全获取嵌套 JSON 值
  ///
  /// [json] - 要提取值的 JSON 对象
  /// [path] - 路径字符串，用点号分隔（如 'user.address.city' ）
  /// [defaultValue] - 当路径不存在时返回的默认值
  dynamic getJsonValue(dynamic json, String path, {dynamic defaultValue}) {
    if (json == null || path.isEmpty) return defaultValue;

    try {
      var keys = path.split('.');
      dynamic current = json;

      for (var key in keys) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else if (current is List && int.tryParse(key) != null) {
          int index = int.parse(key);
          if (index >= 0 && index < current.length) {
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

  List<T> convertDynamicToList<T>(dynamic json,
      {List<T> defaultValue = const []}) {
    if (json is List) {
      try {
        return json.cast<T>(); // 强制转换为 List<T>
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// 整理条目数据, 对原始item拆分成item、creater、tag、attachment这些信息
  Item organizeItem(Map<String, dynamic> itemJson) {
    var itemKey = getJsonValue(itemJson, "key") ?? "";
    var item = Item(
        itemInfo: ItemInfo(
            id: 0,
            itemKey: itemKey,
            groupId: -1,
            version: getJsonValue(itemJson, "version") ?? 0,
            deleted: false),
        itemData: [],
        creators: [],
        tags: [],
        collections: []);

    var data = getJsonValue(itemJson, "data") ?? {};
    final creators = <Creator>[];
    final itemTags = <ItemTag>[];
    final collections = <String>[];
    final itemDatas = <ItemData>[];

    for (var key in data.keys) {
      if (key == "creators") {
        final creatorJsonList = convertDynamicToList<Map<String, dynamic>>(
            getJsonValue(data, "creators"));
        
        int order = 0;
        for (var creatorJson in creatorJsonList) {
          creators.add(Creator(
              id: 0,
              parent: itemKey,
              firstName: getJsonValue(creatorJson, "firstName"),
              lastName: getJsonValue(creatorJson, "lastName"),
              creatorType: getJsonValue(creatorJson, "creatorType"),
              order: order++));
        }
      } else if (key == "tags") {
        final tagJsonList = convertDynamicToList<Map<String, dynamic>>(
            getJsonValue(data, "tags"));
        
        for (var tagJson in tagJsonList) {
          itemTags.add(ItemTag(
              id: 0, parent: itemKey, tag: getJsonValue(tagJson, "tag")));
        }
      } else if (key == "collections") {
        final collectionList = convertDynamicToList<String>(
            getJsonValue(data, "collections"));
        
        collections.addAll(collectionList);
      } else {
        itemDatas.add(ItemData(
            id: 0,
            parent: itemKey,
            name: key,
            value: data[key].toString(),
            valueType: data[key].runtimeType.toString()));
      }
    }

    item.creators = creators;
    item.tags = itemTags;
    item.collections = collections;
    item.itemData = itemDatas;

    return item;
  }
}
