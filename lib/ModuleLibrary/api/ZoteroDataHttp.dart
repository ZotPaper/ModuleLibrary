import 'package:flutter/cupertino.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/LibZoteroApi/Model/zotero_items_response.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/LibZoteroStorage/entity/Creator.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemData.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemInfo.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemTag.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';

import '../../LibZoteroApi/Model/DeletedEntriesPojo.dart';
import '../../LibZoteroApi/ZoteroAPI.dart';
import '../model/zotero_item_downloaded.dart';

class ZoteroDataHttp {
  final String apiKey;

  final String userId;

  late ZoteroAPI service;

  ZoteroDataHttp({required this.userId, required this.apiKey}) {
    service = ZoteroAPI(apiKey: apiKey);
  }

  /// 获取zotero所有的条目,
  /// 注意：是全量数据
  Future<List<Item>> getItems(
      ZoteroDB zoteroDB,
      {Function(int progress, int total)? onProgress,
      Function(List<Item>)? onFinish,
      Function(int errorCode, String msg)? onError}) async {

    final lastModifiedVersion = await zoteroDB.getLibraryVersion();

    final downloadedProgress = zoteroDB.getDownloadProgress();
    int starIndex = downloadedProgress?.nDownloaded ?? 0;

    // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
    final response = await service.getItems(userId, ifModifiedSinceVersion: lastModifiedVersion, startIndex: starIndex);
    if (response == null) {
      return [];
    }

    // todo 检查本地版本号和远程版本号是否一致，不一致的话说明发生了冲突
    if (downloadedProgress != null && response.LastModifiedVersion != downloadedProgress.libraryVersion) {
      // Due to possible miss-syncs, we cannot continue the download.
      // we will raise an exception which will tell the activity to redownload without the
      // progress object.
      throw Exception("Cannot continue, our version ${downloadedProgress.libraryVersion} doesn't match Server's ${response.LastModifiedVersion}");
    }

    // 如果没有数据，则直接返回，调用onFinish
    if (response.data.isEmpty) {
      onFinish?.call([]);
      return [];
    }

    final items = <Item>[];
    final total = response.totalResults;
    List<int> downloadedCount = [0];

    // 处理第一页数据
    await _processPage(response.data, items, total, downloadedCount, onProgress, onFinish);
    // 缓存下载进度, 主要是为了避免后续重复下载
    _cacheDownloadProgress(zoteroDB, response, downloadedCount[0], total);
    // 检查进度，并且把结果回调出去
    _checkProgress(downloadedCount, total, items, onProgress, onFinish);

    // 继续下载剩余页面
    while (downloadedCount[0] < total) {
      final pagedResponse = await service.getItems(userId, ifModifiedSinceVersion: lastModifiedVersion, startIndex: downloadedCount[0]);
      if (pagedResponse == null) {
        continue;
      }
      await _processPage(pagedResponse.data, items, total, downloadedCount, onProgress, onFinish);
      // 缓存下载进度, 主要是为了避免后续重复下载
      _cacheDownloadProgress(zoteroDB, response, downloadedCount[0], total);
      // 检查进度，并且把结果回调出去
      _checkProgress(downloadedCount, total, items, onProgress, onFinish);
    }

    if (lastModifiedVersion > -1) {
      if (downloadedCount[0] == 0) {
        debugPrint("Moyear==== Already up to date.");
        // syncChangeListener?.makeToastAlert("Already up to date.")；
      } else {
        debugPrint("Moyear==== Updated ${downloadedCount[0]} items.");
        // syncChangeListener?.makeToastAlert("Updated ${downloaded} items.")
      }
    }
    zoteroDB.destroyDownloadProgress();

    // 下载完成数据后，更新本地的文库版本号
    final newLibraryVersion = response.LastModifiedVersion;
    await zoteroDB.setItemsVersion(newLibraryVersion);
    debugPrint("Moyear==== 下载完成数据后，更新本地的文库版本号: $newLibraryVersion");
    return items;
  }

  /// 处理分页数据
  Future<void> _processPage(
      List<dynamic> pageData,
      List<Item> items,
      int total,
      List<int> downloadedCount,
      Function(int progress, int total)? onProgress,
      Function(List<Item>)? onFinish) async {
    for (int i = 0; i < pageData.length; i++) {
      var itemJson = pageData[i] ?? "";
      debugPrint("Moyear==== index $i itemJson: $itemJson");

      Item item = organizeItem(itemJson);
      items.add(item);
      downloadedCount[0]++;
    }

    // _checkProgress(downloadedCount, total, items, onProgress, onFinish);
  }

  /// 检查下载进度，并且把结果回调出去
  void _checkProgress(
      List<int> downloadedCount,
      int total,
      List<Item> items,
      Function(int progress, int total)? onProgress,
      Function(List<Item>)? onFinish) async {

    if (downloadedCount[0] == total) {
      onFinish?.call(items);
    } else {
      onProgress?.call(downloadedCount[0], total);
    }

  }

  Future<List<Collection>> getCollections(
      ZoteroDB zoteroDB,
      { int index = 0}) async {

    final lastModifiedVersion = await zoteroDB.getLibraryVersion();

    final itemRes =
        await service.getCollections(lastModifiedVersion, userId, index);
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


  /// 获取zotero所有的条目,
  /// 注意：是全量数据
  Future<List<Item>> getTrashedItems(
      ZoteroDB zoteroDB,
      {Function(int progress, int total)? onProgress,
        Function(List<Item>)? onFinish,
        Function(int errorCode, String msg)? onError}) async {
    final lastTrashVersion = await zoteroDB.getTrashVersion();

    // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
    final response = await service.getTrashedItemsForUser(userId, ifModifiedSinceVersion: lastTrashVersion);
    if (response == null) {
      onFinish?.call([]);
      return [];
    }

    // 如果没有数据，则直接返回，调用onFinish
    if (response.data.isEmpty) {
      onFinish?.call([]);
      return [];
    }

    final items = <Item>[];
    final total = response.totalResults;

    List<int> downloadedCount = [0];

    // 处理第一页数据
    await _processPage(response.data, items, total, downloadedCount, onProgress, onFinish);
    // 检查进度，并且把结果回调出去
    _checkProgress(downloadedCount, total, items, onProgress, onFinish);

    // 继续下载剩余页面
    while (downloadedCount[0] < total) {
      final pagedResponse = await service.getItems(userId, startIndex: downloadedCount[0]);
      if (pagedResponse == null) {
        continue;
      }
      await _processPage(pagedResponse.data, items, total, downloadedCount, onProgress, onFinish);
      // 检查进度，并且把结果回调出去
      _checkProgress(downloadedCount, total, items, onProgress, onFinish);
    }

    final newTrashVersion = response.LastModifiedVersion;
    // 更新trash回收站数据库版本号
    await zoteroDB.setTrashVersion(newTrashVersion);

    debugPrint("Moyear=== 更新回收站数据库版本号：$newTrashVersion");
    return items;
  }

  /// 获取zotero删除的条目
  Future<DeletedEntriesPojo?> getDeletedEntries(
      int sinceVersion,
      {Function(int progress, int total)? onProgress,
        Function(List<Item>)? onFinish,
        Function(int errorCode, String msg)? onError}) async {

    // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
    final response = await service.getDeletedEntriesSince(userId, sinceVersion);
    return response;
  }

  void _cacheDownloadProgress(ZoteroDB zoteroDB, ZoteroAPIItemsResponse response, int downloadedCount, int total) {
    debugPrint("Moyear=== 缓存下载进度：${response.LastModifiedVersion} $downloadedCount/$total");
    zoteroDB.setDownloadProgress(
        ItemsDownloadProgress(
          response.LastModifiedVersion,
          downloadedCount,
          total,
        )
    );
  }

  Future<ZoteroSettingsResponse?> getZoteroSettings(int sinceVersion) async {
    // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
    try {
      final response = await service.getSettings(userId, sinceVersion, sinceVersion);
      return response;
    } catch (e) {
      debugPrint("Moyear=== getZoteroSettings error: $e");
      return null;
    }
  }



}
