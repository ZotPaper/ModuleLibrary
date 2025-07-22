import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:module_library/LibZoteroApi/Model/CollectionPojo.dart';
import 'package:module_library/LibZoteroApi/Model/KeyInfo.dart';
import 'package:module_library/LibZoteroApi/Model/zotero_collections_response.dart';
import 'package:module_library/LibZoteroApi/Model/zotero_items_response.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';

import 'Model/DeletedEntriesPojo.dart';
import 'Model/GroupPojo.dart';
import 'Model/ZoteroSettingsResponse.dart';
import 'ZoteroAPIService.dart';

class ZoteroAPI {
  final String apiKey;

  late ZoteroAPIService service;

  ZoteroAPI({required this.apiKey}) {
    service = ZoteroAPIService(api: apiKey);
  }

  /// 获取用户所有条目信息
  /// 注意：此接口返回的接口默认是分页的
  Future<ZoteroAPIItemsResponse?> getItems(String userId, {int ifModifiedSinceVersion = -1, int startIndex = 0 }) async {
    MyLogger.d('Moyear==== 获取用户所有条目信息 userId: $userId, ifModifiedSinceVersion: $ifModifiedSinceVersion, startIndex: $startIndex');

    final itemRes = await service.getItems(userId, ifModifiedSinceVersion, startIndex);

    if (itemRes.statusCode != 200) {
      if (itemRes.statusCode == 304) {
        debugPrint('Moyear==== 304 条目数据已经是最新了.');
        return itemRes;
      } else {
        throw Exception('请求失败，状态码: ${itemRes.statusCode}');
      }
    } else if (itemRes.statusCode == 200) {
      return itemRes;
    }
    return null;
  }

  /// 获取指定位置开始的条目信息
  Future<List> getItemsSince(
      String userId,
      int ifModifiedSinceVersion,
      int modificationSinceVersion,
      int index,
      ) async {
    final itemRes = await service.getItemsSince(
        ifModifiedSinceVersion, userId, modificationSinceVersion, index);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return [];
  }

  Future<List<GroupPojo>> getGroupInfo(String userId) async {
    final itemRes = await service.getGroupInfo(userId);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      final List<dynamic> data = itemRes.data;
      return data.map((json) => GroupPojo.fromJson(json)).toList();
    }
    return [];
  }

  Future<dynamic> getItemsForGroup(
      int ifModifiedSinceVersion, int groupID, int index) async {
    final itemRes =
        await service.getItemsForGroup(ifModifiedSinceVersion, groupID, index);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> getItemsForGroupSince(int ifModifiedSinceVersion, int groupID,
      int modificationSinceVersion, int index) async {
    final itemRes =
        await service.getItemsForGroup(ifModifiedSinceVersion, groupID, index);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<List> getCollectionsForGroup(
      int ifModifiedSinceVersion, int groupID, int index) async {
    final itemRes = await service.getCollectionsForGroup(
        ifModifiedSinceVersion, groupID, index);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return [];
  }

  Future<dynamic> getAttachmentFileFromGroup(
      int groupID, String itemKey) async {
    final itemRes = await service.getAttachmentFileFromGroup(groupID, itemKey);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<KeyInfo> getKeyInfo(String key) async {
    final itemRes = await service.getKeyInfo(key);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return KeyInfo.fromJson(itemRes.data);
    }
    return KeyInfo(key: "", userId: 0, username: "");
  }

  Future<DeletedEntriesPojo> getDeletedEntriesSince(
      String user, int since) async {
    final itemRes = await service.getDeletedEntriesSince(user, since);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return DeletedEntriesPojo.fromJson(itemRes.data);
    }
    return DeletedEntriesPojo(
        collections: [], items: [], searches: [], tags: [], settings: []);
  }

  Future<DeletedEntriesPojo> getDeletedEntriesForGroupSince(
      int groupID, int since) async {
    final itemRes =
        await service.getDeletedEntriesForGroupSince(groupID, since);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return DeletedEntriesPojo.fromJson(itemRes.data);
    }
    return DeletedEntriesPojo(
        collections: [], items: [], searches: [], tags: [], settings: []);
  }

  Future<ZoteroAPIItemsResponse?> getTrashedItemsForUser(
      String user, {
        int ifModifiedSinceVersion = 0,
        int since = 0,
        int index = 0,
      }) async {
    MyLogger.d("发送网络请求getTrashedItemsForUser，user: $user ifModifiedSinceVersion: $ifModifiedSinceVersion since: $since index: $index");

    final itemRes = await service.getTrashedItemsForUser(
        ifModifiedSinceVersion, user, since, index);
    if (itemRes.statusCode != 200) {
      if (itemRes.statusCode == 304) {
        debugPrint('Moyear==== 304 回收站数据已经是最新了.');
        return itemRes;
      } else {
        throw Exception('请求失败，状态码: ${itemRes.statusCode}');
      }
    } else if (itemRes.statusCode == 200) {
      return itemRes;
    }
    return null;
  }

  Future<dynamic> getTrashedItemsForGroup(
      int ifModifiedSinceVersion, int groupID, int since, int index) async {
    final itemRes = await service.getTrashedItemsForGroup(
        ifModifiedSinceVersion, groupID, since, index);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  /// 获取用户收藏的集合
  /// 注意⚠️：这个接口默认返回的是分页数据，而不是全量数据
  Future<ZoteroAPICollectionsResponse?> getCollections(
      int ifModifiedSinceVersion, String user, int index) async {

    final itemRes =
        await service.getCollections(ifModifiedSinceVersion, user, index);
    if (itemRes.statusCode != 200) {
      if (itemRes.statusCode == 304) {
        debugPrint('Moyear==== 304 集合列表已经是最新了.');
        return itemRes;
      } else {
        throw Exception('请求失败，状态码: ${itemRes.statusCode}');
      }

      // todo 解决304问题
    } else if (itemRes.statusCode == 200) {
      return itemRes;
    }
    return null;
  }

  Future<dynamic> getFileForUser(String user, String itemKey) async {
    final itemRes = await service.getFileForUser(user, itemKey);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> getFileForGroup(int group, String itemKey) async {
    final itemRes = await service.getFileForGroup(group, itemKey);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> writeItem(String user, List<dynamic> json) async {
    final itemRes = await service.writeItem(user, json);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> uploadNote(String user, List<dynamic> json) async {
    final itemRes = await service.uploadNote(user, json);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> patchItem(String user, String itemKey,
      Map<String, dynamic> json, int ifUnmodifiedSinceVersion) async {
    final itemRes =
        await service.patchItem(user, itemKey, json, ifUnmodifiedSinceVersion);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> deleteItem(
      String user, String itemKey, int ifUnmodifiedSinceVersion) async {
    final itemRes =
        await service.deleteItem(user, itemKey, ifUnmodifiedSinceVersion);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> uploadAttachmentAuthorization(
      String user,
      String itemKey,
      String md5,
      String filename,
      int filesize,
      int mtime,
      int params,
      String bodyText,
      String oldMd5Key) async {
    final itemRes = await service.uploadAttachmentAuthorization(user, itemKey,
        md5, filename, filesize, mtime, params, bodyText, oldMd5Key);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> registerUpload(String user, String itemKey, String uploadKey,
      String body, String oldMd5Key) async {
    final itemRes =
        await service.registerUpload(user, itemKey, uploadKey, body, oldMd5Key);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<dynamic> uploadAttachmentToAmazon(String url, FormData data) async {
    final itemRes = await service.uploadAttachmentToAmazon(url, data);
    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      return itemRes.data;
    }
    return null;
  }

  Future<ZoteroSettingsResponse> getSettings(
      String user,
      int ifModifiedSinceVersion,
      int since) async {
    final itemRes =
        await service.getSettings(ifModifiedSinceVersion, user, since);

    if (itemRes.statusCode != 200) {
      throw Exception('请求失败，状态码: ${itemRes.statusCode}');
    } else if (itemRes.statusCode == 200) {
      var res = ZoteroSettingsResponse.fromHttpJson(itemRes.data);
      // 从响应头中获取版本号
      var rawVersion = itemRes.headers?['last-modified-version']?[0]
          .toString()
          .replaceAll('', '') ?? "-1";
      res.lastModifiedVersion = int.parse(rawVersion);
      return res;
    }
    return ZoteroSettingsResponse();
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
}
