
// 定义一些辅助类型
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:module_library/LibZoteroApi/Model/zotero_collections_response.dart';
import 'package:module_library/LibZoteroApi/Model/zotero_items_response.dart';
import 'package:module_library/LibZoteroApi/NetworkConstants.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'Model/CollectionPojo.dart';
import 'Model/DeletedEntriesPojo.dart';
import 'Model/GroupPojo.dart';
import 'Model/KeyInfo.dart';
import 'Model/ZoteroSettingsResponse.dart';


typedef Response<T> = DioResponse<T>;

class DioResponse<T> {
  final T data;
  final int statusCode;

  Headers? headers;

  DioResponse(this.data,  this.statusCode, {this.headers});
}


class ZoteroAPIService {
  late Dio _dio;
  ZoteroAPIService({required String api}){
    String baseUrl = NetworkConstants.BASE_URL;
    _dio =Dio(BaseOptions(baseUrl: baseUrl,headers: {
      'Zotero-API-Key': api,
    },));

    if (kDebugMode) {
      // 添加日志拦截器（核心配置）
      // 配置PrettyDioLogger
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: false,
          responseHeader: false,
          compact: false,
          error: true,
        ),
      );
    }
  }


  Future<ZoteroAPIItemsResponse> getItems(String user, int ifModifiedSinceVersion, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'start': index.toString(),
        'since': ifModifiedSinceVersion.toString()
      };
      final response = await _dio.get('/users/$user/items',
          options: Options(headers: headers),
          queryParameters: queryParameters);
      final List<dynamic> data = response.data;

      final isCache = response.statusCode == 304;
      // final int LastModifiedVersion = response.headers.map['zotero-schema-version'] == null ? 0 : int.parse(response.headers.map['zotero-schema-version']!.first);
      final int LastModifiedVersion = int.tryParse(response.headers.value("Last-Modified-Version") ?? "-1") ?? -1;
      final totalRes = int.tryParse(response.headers.value("total-results") ?? "-1") ?? -1;

      return ZoteroAPIItemsResponse(data,  response.statusCode!, totalRes, LastModifiedVersion, isCache);
      // return Response(data,  response.statusCode!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        // Use cached data
        return ZoteroAPIItemsResponse([], 304, 0, ifModifiedSinceVersion, true);
      }
      throw Exception('请求发生错误: $e');
    }
  }

  Future<Response<dynamic>> getItemsSince(int ifModifiedSinceVersion, String user, int modificationSinceVersion, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'since': modificationSinceVersion.toString(),
        'start': index.toString()
      };
      final response = await _dio.get('/users/$user/items',
          options: Options(headers: headers),
          queryParameters: queryParameters);
      final List<dynamic> data = response.data;
      return Response(data,  response.statusCode!);
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  Future<Response<dynamic>> getGroupInfo(String userID) async {
    try {
      final response = await _dio.get('/users/$userID/groups');
      final List<dynamic> data = response.data;
      return Response(data,  response.statusCode!);
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }
  Future<Response<dynamic>> getItemsForGroup(int ifModifiedSinceVersion, int groupID, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'start': index.toString()
      };
      final response = await _dio.get('/groups/$groupID/items',
          options: Options(headers: headers),
          queryParameters: queryParameters);
      return Response(response.data!,  response.statusCode!);
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }


  }
  Future<Response<dynamic>> getItemsForGroupSince(int ifModifiedSinceVersion, int groupID, int modificationSinceVersion, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'since': modificationSinceVersion.toString(),
        'start': index.toString()
      };
      final response = await _dio.get('/groups/$groupID/items',
          options: Options(headers: headers),
          queryParameters: queryParameters);
      return Response(response.data!,  response.statusCode!);
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  Future<Response<List<dynamic>>> getCollectionsForGroup(int ifModifiedSinceVersion, int groupID, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'start': index.toString()
      };
      final response = await _dio.get('/groups/$groupID/collections',
          options: Options(headers: headers),
          queryParameters: queryParameters);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<CollectionPOJO> collections = data.map((json) => CollectionPOJO.fromJson(json)).toList();
        return Response(
          collections, response.statusCode!,
        );
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  Future<Response<dynamic>> getAttachmentFileFromGroup(int groupID, String itemKey) async {
    try {
      final response = await _dio.get('/groups/$groupID/items/$itemKey/file',
          options: Options(responseType: ResponseType.stream));
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 获取键信息
  Future<Response<dynamic>> getKeyInfo(String key) async {
    try {
      final response = await _dio.get('/keys/$key');
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 获取用户自指定时间以来已删除的条目
  Future<Response<dynamic>> getDeletedEntriesSince(String user, int since) async {
    try {
      final queryParameters = {
        'since': since.toString()
      };
      final response = await _dio.get('/users/$user/deleted',
          queryParameters: queryParameters);
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }


  // 获取群组自指定时间以来已删除的条目
  Future<Response<dynamic>> getDeletedEntriesForGroupSince(int groupID, int since) async {
    try {
      final queryParameters = {
        'since': since.toString()
      };
      final response = await _dio.get('/groups/$groupID/deleted',
          queryParameters: queryParameters);
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 获取用户的已删除项目
  Future<ZoteroAPIItemsResponse> getTrashedItemsForUser(
      int ifModifiedSinceVersion, String user, int since, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'since': since.toString(),
        'start': index.toString()
      };
      final response = await _dio.get('/users/$user/items/trash',
          options: Options(headers: headers),
          queryParameters: queryParameters);

      final List<dynamic> data = response.data;

      final isCache = response.statusCode == 304;
      // final int LastModifiedVersion = response.headers.map['zotero-schema-version'] == null ? 0 : int.parse(response.headers.map['zotero-schema-version']!.first);
      final int LastModifiedVersion = int.tryParse(response.headers.value("Last-Modified-Version") ?? "-1") ?? -1;
      final totalRes = int.tryParse(response.headers.value("total-results") ?? "-1") ?? -1;

      return ZoteroAPIItemsResponse(data,  response.statusCode!, totalRes, LastModifiedVersion, isCache);
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        // Use cached data
        return ZoteroAPIItemsResponse([], 304, 0, ifModifiedSinceVersion, true);
      }
      throw Exception('请求发生错误: $e');
    }
  }


  // 获取群组的已删除项目
  Future<Response<dynamic>> getTrashedItemsForGroup(
      int ifModifiedSinceVersion, int groupID, int since, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'since': since.toString(),
        'start': index.toString()
      };
      final response = await _dio.get('/groups/$groupID/items/trash',
          options: Options(headers: headers),
          queryParameters: queryParameters);
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 获取用户的集合
  Future<ZoteroAPICollectionsResponse> getCollections(
      int ifModifiedSinceVersion, String user, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'start': index.toString()
      };
      final response = await _dio.get('/users/$user/collections',
          options: Options(headers: headers),
          queryParameters: queryParameters);

      // final List<dynamic> data = response.data;

      final isCache = response.statusCode == 304;
      // final int LastModifiedVersion = response.headers.map['zotero-schema-version'] == null ? 0 : int.parse(response.headers.map['zotero-schema-version']!.first);
      final int LastModifiedVersion = int.tryParse(response.headers.value("Last-Modified-Version") ?? "-1") ?? -1;
      final totalRes = int.tryParse(response.headers.value("total-results") ?? "-1") ?? -1;

      final List<dynamic> data = response.data;
      final List<CollectionPOJO> collections = [];
      for (var one in data) {
        var inData = getJsonValue(one, 'data');
        collections.add(CollectionPOJO(
            key: getJsonValue(one, 'key'),
            version: getJsonValue(one, 'version'),
            collectionData: CollectionData(
                name: getJsonValue(inData, 'name'),
                parentCollection:
                getJsonValue(inData, 'parentCollection').toString())));
      }
      return ZoteroAPICollectionsResponse(collections,  response.statusCode!, totalRes, LastModifiedVersion, isCache);
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        // Use cached data
        return ZoteroAPICollectionsResponse([], 304, 0, ifModifiedSinceVersion, true);
      }
      throw Exception('请求发生错误: $e');
    }
  }

  // 获取用户的文件
  Future<Response<dynamic>> getFileForUser(String user, String itemKey) async {
    try {
      final response = await _dio.get('/users/$user/items/$itemKey/file',
          options: Options(responseType: ResponseType.stream));
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 获取群组的文件
  Future<Response<dynamic>> getFileForGroup(int group, String itemKey) async {
    try {
      final response = await _dio.get('/groups/$group/items/$itemKey/file',
          options: Options(responseType: ResponseType.stream));
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 写入项目
  Future<Response<dynamic>> writeItem(String user, List<dynamic> json) async {
    try {
      final response = await _dio.post('/users/$user/items', data: json);
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 上传笔记
  Future<Response<dynamic>> uploadNote(String user, List<dynamic> json) async {
    try {
      final response = await _dio.post('/users/$user/items', data: json);
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 修补项目
  Future<Response<dynamic>> patchItem(
      String user, String itemKey, Map<String, dynamic> json, int ifUnmodifiedSinceVersion) async {
    try {
      final headers = {
        'If-Unmodified-Since-Version': ifUnmodifiedSinceVersion.toString()
      };
      final response = await _dio.patch('/users/$user/items/$itemKey',
          data: json, options: Options(headers: headers));
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 删除项目
  Future<Response<dynamic>> deleteItem(String user, String itemKey, int ifUnmodifiedSinceVersion) async {
    try {
      final headers = {
        'If-Unmodified-Since-Version': ifUnmodifiedSinceVersion.toString()
      };
      final response = await _dio.delete('/users/$user/items/$itemKey',
          options: Options(headers: headers));
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }
  // 上传附件授权
  Future<Response<dynamic>> uploadAttachmentAuthorization(
      String user, String itemKey, String md5, String filename, int filesize, int mtime, int params,
      String bodyText, String oldMd5Key) async {
    try {
      final headers = {
        'If-Match': oldMd5Key
      };
      final queryParameters = {
        'md5': md5,
        'filename': filename,
        'filesize': filesize.toString(),
        'mtime': mtime.toString(),
        'params': params.toString()
      };
      final response = await _dio.post('/users/$user/items/$itemKey/file',
          data: bodyText,
          options: Options(headers: headers),
          queryParameters: queryParameters);
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 注册上传
  Future<Response<dynamic>> registerUpload(
      String user, String itemKey, String uploadKey, String body, String oldMd5Key) async {
    try {
      final headers = {
        'If-Match': oldMd5Key
      };
      final queryParameters = {
        'upload': uploadKey
      };
      final response = await _dio.post('/users/$user/items/$itemKey/file',
          data: body,
          options: Options(headers: headers),
          queryParameters: queryParameters);
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 上传附件到 Amazon
  Future<Response<dynamic>> uploadAttachmentToAmazon(String url, FormData data) async {
    try {
      final response = await _dio.post(url, data: data);
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }



  // 获取用户设置
  Future<Response<dynamic>> getSettings(
      int ifModifiedSinceVersion, String user, int since) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'since': since.toString()
      };
      final response = await _dio.get('/users/$user/settings',
          options: Options(headers: headers),
          queryParameters: queryParameters);

      return Response(
              response.data, response.statusCode!, headers: response.headers,
            );
    } on DioException catch (e) {
      // 304 不是异常
      if (e.error != 304) {
        throw Exception('请求发生错误: $e');
      } else {
        return Response(
          null, e.response!.statusCode!, headers: e.response!.headers,
        );
      }
    }
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

