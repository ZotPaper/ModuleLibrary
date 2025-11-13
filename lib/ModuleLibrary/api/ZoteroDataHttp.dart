import 'package:flutter/cupertino.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/LibZoteroApi/Model/zotero_items_response.dart';
import 'package:module_library/LibZoteroApi/ZoteroAPIService.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';
import 'package:module_library/LibZoteroStorage/entity/Creator.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemData.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemInfo.dart';
import 'package:module_library/LibZoteroStorage/entity/ItemTag.dart';
import 'package:module_library/ModuleLibrary/utils/my_fun_tracer.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
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

  /// 获取zotero所有的条目 (并发优化版本)
  /// 注意：是全量数据
  Future getItems(ZoteroDB zoteroDB,
      {Function(int progress, int total, List<Item>?)? onProgress,
        Function(int total)? onFinish,
        Function(int errorCode, String msg)? onError}) async {

    final lastModifiedVersion = await zoteroDB.getLibraryVersion();
    final downloadedProgress = zoteroDB.getDownloadProgress();
    int startIndex = downloadedProgress?.nDownloaded ?? 0;

    try {
      // 使用并发优化版本
      await getItemsConcurrent(
        zoteroDB,
        lastModifiedVersion: lastModifiedVersion,
        startIndex: startIndex,
        onProgress: onProgress,
        onFinish: onFinish,
        onError: onError,
      );
    } catch (e) {
      onError?.call(1, e.toString());
    }
  }

  /// 并发下载Items - 大幅提升下载速度
  Future<List<Item>> getItemsConcurrent(ZoteroDB zoteroDB,
      {required int lastModifiedVersion,
        required int startIndex,
        Function(int progress, int total, List<Item>?)? onProgress,
        Function(int total)? onFinish,
        Function(int errorCode, String msg)? onError}) async {

    MyFunTracer.beginTrace(customKey: "getItemsConcurrent");

    // 1. 先发送第一个请求获取总数和第一页数据
    final firstResponse = await service.getItems(
        userId, ifModifiedSinceVersion: lastModifiedVersion,
        startIndex: startIndex);
    
    if (firstResponse == null) {
      onFinish?.call(-1);
      return [];
    }

    // 检查版本冲突
    final downloadedProgress = zoteroDB.getDownloadProgress();
    if (downloadedProgress != null && downloadedProgress.libraryVersion > 0 &&
        firstResponse.LastModifiedVersion != downloadedProgress.libraryVersion) {
      onError?.call(1, "Cannot continue, our version ${downloadedProgress
          .libraryVersion} doesn't match Server's ${firstResponse.LastModifiedVersion}");
    }

    if (firstResponse.data.isEmpty) {
      onFinish?.call(-1);
    }

    final total = firstResponse.totalResults;
    final pageSize = firstResponse.data.length; // 通常是25
    List<int> downloadedCount = [startIndex];

    // 处理第一页数据
    final allItems = <Item>[];
    _processPage(firstResponse.data, allItems, total, downloadedCount, onProgress, onFinish);
    
    // 缓存第一页进度
    await _cacheDownloadProgress(zoteroDB, firstResponse, downloadedCount[0], total);
    _checkProgress(downloadedCount, total, allItems.toList(), onProgress, onFinish);

    // 2. 如果还有剩余页面，使用并发请求
    if (downloadedCount[0] < total) {
      final remainingCount = total - downloadedCount[0];
      final remainingPages = (remainingCount / pageSize).ceil();
      
      MyLogger.d("并发下载剩余 $remainingPages 页，共 $remainingCount 条数据");

      // 创建并发请求任务
      final concurrentResults = await _downloadPagesConcurrently(
        startIndex: downloadedCount[0],
        pageSize: pageSize,
        remainingPages: remainingPages,
        lastModifiedVersion: lastModifiedVersion,
        total: total,
        downloadedCount: downloadedCount,
        zoteroDB: zoteroDB,
        firstResponse: firstResponse,
        onProgress: onProgress,
        onFinish: onFinish,
      );

      // 合并所有结果
      allItems.addAll(concurrentResults);
    }

    // 更新版本号
    if (lastModifiedVersion != firstResponse.LastModifiedVersion) {
      await zoteroDB.setItemsVersion(firstResponse.LastModifiedVersion);
      MyLogger.d("下载完成，更新版本号: ${firstResponse.LastModifiedVersion}");
    }

    MyFunTracer.endTrace(customKey: "getItemsConcurrent");
    MyLogger.d("并发下载完成，总共获取 ${allItems.length} 条数据");

    return allItems;
  }

  /// 并发下载多个页面
  Future<List<Item>> _downloadPagesConcurrently({
    required int startIndex,
    required int pageSize,
    required int remainingPages,
    required int lastModifiedVersion,
    required int total,
    required List<int> downloadedCount,
    required ZoteroDB zoteroDB,
    required var firstResponse,
    Function(int progress, int total, List<Item>?)? onProgress,
    Function(int total)? onFinish,
  }) async {

    const int maxConcurrency = 6; // 最大并发数，避免服务器压力过大
    final List<Item> concurrentResults = [];

    // 分批次处理并发请求
    for (int batchStart = 0; batchStart < remainingPages; batchStart += maxConcurrency) {
      final batchEnd = (batchStart + maxConcurrency).clamp(0, remainingPages);
      final batchSize = batchEnd - batchStart;

      MyLogger.d("处理批次 ${batchStart + 1}-$batchEnd ($batchSize 个请求)");

      // 创建当前批次的请求
      final List<Future<Map<String, dynamic>?>> futures = [];
      for (int i = batchStart; i < batchEnd; i++) {
        final pageStartIndex = startIndex + (i * pageSize);
        futures.add(_downloadSinglePage(pageStartIndex, lastModifiedVersion, i));
      }

      // 等待当前批次完成
      final batchResponses = await Future.wait(futures);

      // 处理批次结果
      final batchItems = <Item>[];
      for (int i = 0; i < batchResponses.length; i++) {
        final response = batchResponses[i];
        if (response != null && response['data'] != null) {
          final pageItems = <Item>[];
          _processPage(response['data'], pageItems, total, downloadedCount, null, null);
          batchItems.addAll(pageItems);

          // 缓存进度
          await _cacheDownloadProgress(zoteroDB, firstResponse, downloadedCount[0], total);
        }
      }

      concurrentResults.addAll(batchItems);

      // 报告批次进度
      _checkProgress(downloadedCount, total, batchItems, onProgress, onFinish);

      MyLogger.d("批次 ${batchStart + 1}-$batchEnd 完成，获取 ${batchItems.length} 条数据");

      // 批次间添加小延迟，避免服务器压力过大
      if (batchEnd < remainingPages) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return concurrentResults;
  }

  /// 下载单个页面的数据
  Future<Map<String, dynamic>?> _downloadSinglePage(
      int startIndex, int lastModifiedVersion, int pageIndex) async {
    try {
      MyFunTracer.beginTrace(customKey: "downloadPage_$pageIndex");
      
      final response = await service.getItems(
          userId, 
          ifModifiedSinceVersion: lastModifiedVersion,
          startIndex: startIndex);
      
      MyFunTracer.endTrace(customKey: "downloadPage_$pageIndex");

      if (response != null) {
        return {
          'data': response.data,
          'startIndex': startIndex,
          'pageIndex': pageIndex,
        };
      }
      return null;
    } catch (e) {
      MyLogger.d("下载页面 $pageIndex (startIndex: $startIndex) 失败: $e");
      return null;
    }
  }

  @Deprecated("这个方法暂时不用")
  /// 原始的顺序下载方法，作为并发下载的后备方案
  Future<List<Item>> getItemsSequential(ZoteroDB zoteroDB,
      {required int lastModifiedVersion,
        required int startIndex,
        Function(int progress, int total, List<Item>?)? onProgress,
        Function(int total)? onFinish,
        Function(int errorCode, String msg)? onError}) async {

    MyLogger.d("使用顺序下载模式");

    final response = await service.getItems(
        userId, ifModifiedSinceVersion: lastModifiedVersion,
        startIndex: startIndex);
    if (response == null) {
      return [];
    }

    // 检查版本冲突
    final downloadedProgress = zoteroDB.getDownloadProgress();
    if (downloadedProgress != null && downloadedProgress.libraryVersion > 0 &&
        response.LastModifiedVersion != downloadedProgress.libraryVersion) {
      onError?.call(1, "Cannot continue, our version ${downloadedProgress
          .libraryVersion} doesn't match Server's ${response
          .LastModifiedVersion}");
      return [];
    }

    if (response.data.isEmpty) {
      onFinish?.call(-1);
      return [];
    }

    final items = <Item>[];
    final total = response.totalResults;
    List<int> downloadedCount = [startIndex];

    // 处理第一页数据
    _processPage(response.data, items, total, downloadedCount, onProgress, onFinish);
    await _cacheDownloadProgress(zoteroDB, response, downloadedCount[0], total);
    _checkProgress(downloadedCount, total, items.toList(), onProgress, onFinish);
    items.clear();

    // 继续下载剩余页面 (顺序方式)
    while (downloadedCount[0] < total) {
      final pagedResponse = await service.getItems(
          userId, ifModifiedSinceVersion: lastModifiedVersion,
          startIndex: downloadedCount[0]);
      if (pagedResponse == null) {
        continue;
      }
      _processPage(pagedResponse.data, items, total, downloadedCount, onProgress, onFinish);
      await _cacheDownloadProgress(zoteroDB, response, downloadedCount[0], total);
      _checkProgress(downloadedCount, total, items.toList(), onProgress, onFinish);
      items.clear();
    }

    // 更新版本号
    if (lastModifiedVersion != response.LastModifiedVersion) {
      await zoteroDB.setItemsVersion(response.LastModifiedVersion);
      MyLogger.d("顺序下载完成，更新版本号: ${response.LastModifiedVersion}");
    }

    return items;
  }


  /// 处理分页数据
  void _processPage(List<dynamic> pageData,
      List<Item> items,
      int total,
      List<int> downloadedCount,
      Function(int progress, int total, List<Item>?)? onProgress,
      Function(int total)? onFinish) {

    for (int i = 0; i < pageData.length; i++) {
      var itemJson = pageData[i] ?? "";
      // debugPrint("Moyear==== index $i itemJson: $itemJson");

      Item item = organizeItem(itemJson);
      items.add(item);
      downloadedCount[0]++;
    }

    // _checkProgress(downloadedCount, total, items, onProgress, onFinish);
  }

  /// 处理 Collections 分页数据
  Future<void> _processCollectionsPage(List<dynamic> pageData,
      List<Collection> collections,
      int total,
      List<int> downloadedCount,
      Function(int progress, int total, List<Collection>?)? onProgress,
      Function(int total)? onFinish) async {
    for (int i = 0; i < pageData.length; i++) {
      var collectionPOJO = pageData[i];
      if (collectionPOJO != null) {
        Collection collection = Collection(
            key: collectionPOJO.key,
            version: collectionPOJO.version,
            parentCollection: collectionPOJO.collectionData.parentCollection,
            groupId: NO_GROUP_ID,
            name: collectionPOJO.collectionData.name);
        collections.add(collection);
        downloadedCount[0]++;
      }
    }
  }

  /// 检查条目Item下载进度，并且把结果回调出去
  void _checkProgress(List<int> downloadedCount,
      int total,
      List<Item> items,
      Function(int progress, int total, List<Item>? items)? onProgress,
      Function(int total)? onFinish) async {
    if (downloadedCount[0] == total) {
      // 为了保证最后不漏数据
      onProgress?.call(downloadedCount[0], total, items);
      onFinish?.call(total);
    } else {
      onProgress?.call(downloadedCount[0], total, items);
    }
  }

  /// 检查合集Collection的下载进度，并且把结果回调出去
  void _checkCollectionProgress(List<int> downloadedCount,
      int total,
      List<Collection> collections,
      Function(int progress, int total, List<Collection>? collections)? onProgress,
      Function(int total)? onFinish) async {
    if (downloadedCount[0] == total) {
      // 为了保证最后不漏数据
      onProgress?.call(downloadedCount[0], total, collections);
      onFinish?.call(total);
    } else {
      onProgress?.call(downloadedCount[0], total, collections);
    }
  }


  Future getCollections(ZoteroDB zoteroDB,
      {
        Function(int progress, int total, List<Collection>?)? onProgress,
        Function(int total)? onFinish,
        Function(int errorCode, String msg)? onError
      }) async {
    final lastModifiedVersion = await zoteroDB.getLibraryVersion();

    final downloadedProgress = zoteroDB.getCollectionsDownloadProgress();
    int startIndex = downloadedProgress?.nDownloaded ?? 0;

    try {
      // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
      final response = await service.getCollections(lastModifiedVersion, userId, startIndex);
      if (response == null) {
        onFinish?.call(-1);
        return;
      }

      // todo 检查本地版本号和远程版本号是否一致，不一致的话说明发生了冲突
      if (downloadedProgress != null && response?.LastModifiedVersion != downloadedProgress.libraryVersion) {
        // Due to possible miss-syncs, we cannot continue the download.
        // we will raise an exception which will tell the activity to redownload without the
        // progress object.
        throw Exception("Cannot continue, our version ${downloadedProgress
            .libraryVersion} doesn't match Server's ${response.LastModifiedVersion}");
      }

      // // 如果没有数据，则直接返回，调用onFinish
      // if (response.isEmpty) {
      //   onFinish?.call(-1);
      //   return [];
      // }

      // 这里的collections是每一次下载的集合数据
      final collections = <Collection>[];
      final total = response.totalResults; // Collections API 可能不返回总数，这里使用当前批次的长度
      List<int> downloadedCount = [0];

      // 处理第一页数据
      await _processCollectionsPage(
          response.data, collections, total, downloadedCount, onProgress, onFinish);
      
      // 缓存下载进度, 主要是为了避免后续重复下载
      if (response.data.isNotEmpty) {
        _cacheCollectionsDownloadProgress(zoteroDB, response.LastModifiedVersion, downloadedCount[0], total);
      }
      
      // 检查进度，并且把结果回调出去
      _checkCollectionProgress(downloadedCount, total, collections.toList(), onProgress, onFinish);

      // 清除临时暂存的数据
      collections.clear();

      // 继续下载剩余页面 (如果有更多数据)
      bool hasMoreData = response.data.length >= 25; // 假设每页25条，如果返回数量等于页面大小，可能还有更多数据
      while (hasMoreData && downloadedCount[0] < total) {
        final pagedResponse = await service.getCollections(
            lastModifiedVersion, userId, downloadedCount[0]);
        if (pagedResponse == null || pagedResponse.data.isEmpty) {
          break;
        }
        
        await _processCollectionsPage(
            pagedResponse.data, collections, total, downloadedCount, onProgress, onFinish);
        
        // 缓存下载进度, 主要是为了避免后续重复下载
        if (pagedResponse.data.isNotEmpty) {
          _cacheCollectionsDownloadProgress(zoteroDB, pagedResponse.LastModifiedVersion, downloadedCount[0], total);
        }
        
        // 检查进度，并且把结果回调出去
        _checkCollectionProgress(downloadedCount, total, collections.toList(), onProgress, onFinish);

        // 清除临时暂存的数据
        collections.clear();
        
        // 如果返回的数据少于预期页面大小，说明没有更多数据了
        hasMoreData = pagedResponse.data.length >= 25;
      }

      if (lastModifiedVersion > -1) {
        if (downloadedCount[0] == 0) {
          debugPrint("Moyear==== Collections already up to date.");
        } else {
          debugPrint("Moyear==== Updated ${downloadedCount[0]} collections.");
        }
      }

      // 下载完成数据后，更新本地的集合版本号
      if (response.data.isNotEmpty) {
        final newCollectionsVersion = response.LastModifiedVersion;
        if (lastModifiedVersion != newCollectionsVersion) {
          await zoteroDB.setCollectionsVersion(newCollectionsVersion);
          MyLogger.d("下载完成数据后，更新本地的集合版本号: $newCollectionsVersion 旧版本号: $lastModifiedVersion");
        }
      }
      
      return collections;
    } catch (e) {
      MyLogger.d("获取Collections时发生错误: $e");
      onError?.call(-1, e.toString());
      return [];
    }
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
              firstName: getJsonValue(creatorJson, "firstName") ?? "",
              lastName: getJsonValue(creatorJson, "lastName") ?? "",
              creatorType: getJsonValue(creatorJson, "creatorType") ?? "",
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
  Future<List<Item>> getTrashedItems(ZoteroDB zoteroDB,
      {Function(int progress, int total, List<Item>?)? onProgress,
        Function(int total)? onFinish,
        Function(int errorCode, String msg)? onError}) async {
    final lastTrashVersion = await zoteroDB.getTrashVersion();

    // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
    final response = await service.getTrashedItemsForUser(
        userId, ifModifiedSinceVersion: lastTrashVersion);
    if (response == null) {
      onFinish?.call(-1);
      return [];
    }

    // 如果没有数据，则直接返回，调用onFinish
    if (response.data.isEmpty) {
      onFinish?.call(-1);
      return [];
    }

    final items = <Item>[];
    final total = response.totalResults;

    List<int> downloadedCount = [0];

    // 处理第一页数据
    _processPage(
        response.data, items, total, downloadedCount, onProgress, onFinish);
    // 检查进度，并且把结果回调出去
    _checkProgress(downloadedCount, total, items.toList(), onProgress, onFinish);
    // 清除临时暂存的数据
    items.clear();

    // 继续下载剩余页面
    while (downloadedCount[0] < total) {
      final pagedResponse = await service.getItems(
          userId, startIndex: downloadedCount[0]);
      if (pagedResponse == null) {
        continue;
      }
      _processPage(
          pagedResponse.data, items, total, downloadedCount, onProgress,
          onFinish);
      // 检查进度，并且把结果回调出去
      _checkProgress(downloadedCount, total, items.toList(), onProgress, onFinish);
      // 清除临时暂存的数据
      items.clear();
    }

    final newTrashVersion = response.LastModifiedVersion;
    // 更新trash回收站数据库版本号
    await zoteroDB.setTrashVersion(newTrashVersion);

    debugPrint("Moyear=== 更新回收站数据库版本号：$newTrashVersion");
    return items;
  }

  /// 获取zotero删除的条目
  Future<DeletedEntriesPojo?> getDeletedEntries(int sinceVersion,
      {Function(int progress, int total)? onProgress,
        Function(List<Item>)? onFinish,
        Function(int errorCode, String msg)? onError}) async {
    // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
    final response = await service.getDeletedEntriesSince(userId, sinceVersion);
    return response;
  }

  Future<void> _cacheDownloadProgress(ZoteroDB zoteroDB,
      ZoteroAPIItemsResponse response, int downloadedCount, int total) async {
    MyLogger.d("缓存下载进度：${response
        .LastModifiedVersion} $downloadedCount/$total");
    await zoteroDB.setDownloadProgress(
        ItemsDownloadProgress(
          response.LastModifiedVersion,
          downloadedCount,
          total,
        )
    );
  }

  void _cacheCollectionsDownloadProgress(ZoteroDB zoteroDB,
      int version, int downloadedCount, int total) {
    MyLogger.d("缓存Collections下载进度：$version $downloadedCount/$total");
    zoteroDB.setCollectionsDownloadProgress(
        CollectionsDownloadProgress(
          version,
          downloadedCount,
          total,
        )
    );
  }

  Future<ZoteroSettingsResponse?> getZoteroSettings(int sinceVersion) async {
    // 发送请求下载数据，注意默认返回最多为25条（依赖后端而定），所以需要分页下载
    try {
      final response = await service.getSettings(
          userId, sinceVersion, sinceVersion);
      return response;
    } catch (e) {
      debugPrint("Moyear=== getZoteroSettings error: $e");
      return null;
    }
  }

  Future<dynamic> moveItemToTrash(
      ZoteroDB zoteroDB,
      Item item, {
        Function(Item deletedItem, int newTrashVersion)? onSuccess,
        Function(int errorCode, String msg)? onError,
      }) async {
    try {
      int itemVersion = item.getVersion();
      final response = await service.deleteItem(userId, item.itemKey, itemVersion);
      // todo 判断是否成功删除，删除成功，更新数据库数据与版本号
      // 204 No Content	The item was deleted.
      // 409 Conflict	The target library is locked.
      // 412 Precondition Failed	The item has changed since retrieval (i.e., the provided item version no longer matches).
      // 428 Precondition Required	If-Unmodified-Since-Version was not provided.

      if (response.statusCode == 200) {
        onSuccess?.call(item, response.LastModifiedVersion);
       }

      if (response.statusCode == 204 || response.statusCode == 428 || response.statusCode == 412 || response.statusCode == 409) {
        onError?.call(response.statusCode, response.reasonPhrase);
      }

      return response;
    } catch (e) {
      debugPrint("Moyear=== moveItemToTrash error: $e");
      return null;
    }
  }

  /// 更新条目信息
  Future<dynamic> patchItem({
    required Item item,
    required Map<String, dynamic> json
  }) async {
    var lastModifiedVersion = item.getVersion();
    String itemKey = item.itemKey;
    return service.patchItem(userId, itemKey, json, lastModifiedVersion);
  }


}
