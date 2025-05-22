
// 定义一些辅助类型
import 'package:dio/dio.dart';
import 'package:module/LibZoteroApi/Model/zotero_items_response.dart';
import 'package:module/LibZoteroApi/NetworkConstants.dart';

import 'Model/CollectionPojo.dart';
import 'Model/DeletedEntriesPojo.dart';
import 'Model/GroupPojo.dart';
import 'Model/KeyInfo.dart';
import 'Model/ZoteroSettingsResponse.dart';


typedef Response<T> = DioResponse<T>;

class DioResponse<T> {
  final T data;
  final int statusCode;

  DioResponse(this.data,  this.statusCode);
}


class ZoteroAPIService {
  late Dio _dio;
  ZoteroAPIService({required String api}){
    String baseUrl = NetworkConstants.BASE_URL;
    _dio =Dio(BaseOptions(baseUrl: baseUrl,headers: {
      'Zotero-API-Key': api,
    },));
  }

  Future<ZoteroAPIItemsResponse> getItems(int ifModifiedSinceVersion, String user, int index) async {
    try {
      final headers = {
        'If-Modified-Since-Version': ifModifiedSinceVersion.toString()
      };
      final queryParameters = {
        'start': index.toString()
      };
      final response = await _dio.get('/users/$user/items',
          options: Options(headers: headers),
          queryParameters: queryParameters);
      final List<dynamic> data = response.data;

      final isCache = response.statusCode == 304;
      // final int LastModifiedVersion = response.headers.map['zotero-schema-version'] == null ? 0 : int.parse(response.headers.map['zotero-schema-version']!.first);
      final int LastModifiedVersion = int.tryParse(response.headers.value("zotero-schema-version") ?? "-1") ?? -1;
      final totalRes = int.tryParse(response.headers.value("total-results") ?? "-1") ?? -1;

      return ZoteroAPIItemsResponse(data,  response.statusCode!, totalRes, LastModifiedVersion, isCache);
      // return Response(data,  response.statusCode!);
    } catch (e) {
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
      final int LastModifiedVersion = int.tryParse(response.headers.value("zotero-schema-version") ?? "-1") ?? -1;
      final totalRes = int.tryParse(response.headers.value("total-results") ?? "-1") ?? -1;

      return ZoteroAPIItemsResponse(data,  response.statusCode!, totalRes, LastModifiedVersion, isCache);
    } catch (e) {
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
  Future<Response<dynamic>> getCollections(
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
      return Response(
        response.data, response.statusCode!,
      );
    } catch (e) {
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
              response.data, response.statusCode!,
            );
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }
}

