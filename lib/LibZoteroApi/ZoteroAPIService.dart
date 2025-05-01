
// 定义一些辅助类型
import 'package:dio/dio.dart';
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

  Future<Response<List<dynamic>>> getItems(int ifModifiedSinceVersion, String user, int index) async {
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
      return Response(data,  response.statusCode!);
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }
  Future<Response<List<dynamic>>> getItemsSince(int ifModifiedSinceVersion, String user, int modificationSinceVersion, int index) async {
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

  Future<List<GroupPojo>> getGroupInfo(String userID) async {
    try {
      final response = await _dio.get('/users/$userID/groups');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => GroupPojo.fromJson(json)).toList();
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
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
  Future<KeyInfo> getKeyInfo(String key) async {
    try {
      final response = await _dio.get('/keys/$key');
      if (response.statusCode == 200) {
        return KeyInfo.fromJson(response.data);
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 获取用户自指定时间以来已删除的条目
  Future<Response<DeletedEntriesPojo>> getDeletedEntriesSince(String user, int since) async {
    try {
      final queryParameters = {
        'since': since.toString()
      };
      final response = await _dio.get('/users/$user/deleted',
          queryParameters: queryParameters);
      if (response.statusCode == 200) {
        return Response(
          DeletedEntriesPojo.fromJson(response.data),
          response.statusCode!,
        );
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }


  // 获取群组自指定时间以来已删除的条目
  Future<Response<DeletedEntriesPojo>> getDeletedEntriesForGroupSince(int groupID, int since) async {
    try {
      final queryParameters = {
        'since': since.toString()
      };
      final response = await _dio.get('/groups/$groupID/deleted',
          queryParameters: queryParameters);
      if (response.statusCode == 200) {
        return Response(
          DeletedEntriesPojo.fromJson(response.data),
          response.statusCode!,

        );
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }

  // 获取用户的已删除项目
  Future<Response<dynamic>> getTrashedItemsForUser(
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
      return Response(
        response.data, response.statusCode!,
      );
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
  Future<Response<List<CollectionPOJO>>> getCollections(
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
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<CollectionPOJO> collections =
        data.map((json) => CollectionPOJO.fromJson(json)).toList();
        return Response(
          collections,
          response.statusCode!,

        );
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
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

  // 多部分上传附件到 Amazon
  // Future<Response<dynamic>> uploadAttachmentToAmazonMulti(
  //     String url,
  //     String key,
  //     String acl,
  //     String content_MD5,
  //     String success_action_status,
  //     String policy,
  //     String x_amz_algorithm,
  //     String x_amz_credential,
  //     String x_amz_date,
  //     String x_amz_signature,
  //     String x_amz_security_token,
  //     MultipartFile attachmentData) async {
  //   try {
  //     final formData = FormData.fromMap({
  //       'key': key,
  //       'acl': acl,
  //       'Content-MD5': content_MD5,
  //       'success_action_status': success_action_status,
  //       'policy': policy,
  //       'x-amz-algorithm': x_amz_algorithm,
  //       'x-amz-credential': x_amz_credential,
  //       'x-amz-date': x_amz_date,
  //       'x-amz-signature': x_amz_signature,
  //       'x-amz-security-token': x_amz_security_token,
  //       'file': await MultipartFile.fromFile(attachmentData.path,
  //           filename: attachmentData.filename)
  //     });
  //     final response = await _dio.post(url, data: formData);
  //     return Response(
  //       response.data, response.statusCode!,
  //     );
  //   } catch (e) {
  //     throw Exception('请求发生错误: $e');
  //   }
  // }

  // 获取用户设置
  Future<Response<ZoteroSettingsResponse>> getSettings(
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
      if (response.statusCode == 200) {
        return Response(
           ZoteroSettingsResponse.fromJson(response.data),
           response.statusCode!,

        );
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('请求发生错误: $e');
    }
  }
}

  //
  // // 获取组的项目
  // Observable<Response<ResponseBody>> getItemsForGroup(
  //     int ifModifiedSinceVersion, int groupID, int index) {
  //   return _dio.get<ResponseBody>(
  //     'groups/$groupID/items',
  //     options: Options(
  //       headers: {
  //         'If-Modified-Since-Version': ifModifiedSinceVersion,
  //       },
  //     ),
  //     queryParameters: {
  //       'start': index,
  //     },
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 获取组自上次更新以来的项目
  // Observable<Response<ResponseBody>> getItemsForGroupSince(
  //     int ifModifiedSinceVersion,
  //     int groupID,
  //     int modificationSinceVersion,
  //     int index) {
  //   return _dio.get<ResponseBody>(
  //     'groups/$groupID/items',
  //     options: Options(
  //       headers: {
  //         'If-Modified-Since-Version': ifModifiedSinceVersion,
  //       },
  //     ),
  //     queryParameters: {
  //       'since': modificationSinceVersion,
  //       'start': index,
  //     },
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }

  // // 获取组的集合
  // Observable<Response<List<CollectionPOJO>>> getCollectionsForGroup(
  //     int ifModifiedSinceVersion, int groupID, int index) {
  //   return _dio.get<List<dynamic>>(
  //     'groups/$groupID/collections',
  //     options: Options(
  //       headers: {
  //         'If-Modified-Since-Version': ifModifiedSinceVersion,
  //       },
  //     ),
  //     queryParameters: {
  //       'start': index,
  //     },
  //   ).asStream().map((response) {
  //     final collections =
  //     response.data!.map((e)  => CollectionPOJO()).toList();
  //     return Response(collections, response.statusCode!);
  //   });
  // }
  //
  // // 从组中获取附件文件
  // Future<ResponseBody> getAttachmentFileFromGroup(int user, String itemKey) {
  //   return _dio.get<ResponseBody>(
  //     'groups/$user/items/$itemKey/file',
  //     options: Options(responseType: ResponseType.stream),
  //   ).then((response) => response.data!);
  // }
  //
  // // 获取密钥信息
  // Future<KeyInfo> getKeyInfo(String key) {
  //   return _dio.get<dynamic>(
  //     'keys/$key',
  //   ).then((response) => KeyInfo());
  // }
  //
  // // 获取用户自某个版本以来删除的条目
  // Observable<Response<DeletedEntriesPojo>> getDeletedEntriesSince(
  //     String user, int since) {
  //   return _dio.get<dynamic>(
  //     'users/$user/deleted',
  //     queryParameters: {
  //       'since': since,
  //     },
  //   ).asStream().map((response) {
  //     return Response(DeletedEntriesPojo(), response.statusCode!);
  //   });
  // }
  //
  // // 获取组自某个版本以来删除的条目
  // Observable<Response<DeletedEntriesPojo>> getDeletedEntriesForGroupSince(
  //     int user, int since) {
  //   return _dio.get<dynamic>(
  //     'groups/$user/deleted',
  //     queryParameters: {
  //       'since': since,
  //     },
  //   ).asStream().map((response) {
  //     return Response(DeletedEntriesPojo(), response.statusCode!);
  //   });
  // }
  //
  // // 获取用户的回收站项目
  // Observable<Response<ResponseBody>> getTrashedItemsForUser(
  //     int ifModifiedSinceVersion, String user, int since, int index) {
  //   return _dio.get<ResponseBody>(
  //     'users/$user/items/trash',
  //     options: Options(
  //       headers: {
  //         'If-Modified-Since-Version': ifModifiedSinceVersion,
  //       },
  //     ),
  //     queryParameters: {
  //       'since': since,
  //       'start': index,
  //     },
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 获取组的回收站项目
  // Observable<Response<ResponseBody>> getTrashedItemsForGroup(
  //     int ifModifiedSinceVersion, int groupID, int since, int index) {
  //   return _dio.get<ResponseBody>(
  //     'groups/$groupID/items/trash',
  //     options: Options(
  //       headers: {
  //         'If-Modified-Since-Version': ifModifiedSinceVersion,
  //       },
  //     ),
  //     queryParameters: {
  //       'since': since,
  //       'start': index,
  //     },
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 获取用户的集合
  // Observable<Response<List<CollectionPOJO>>> getCollections(
  //     int ifModifiedSinceVersion, String user, int index) {
  //   return _dio.get<List<dynamic>>(
  //     'users/$user/collections',
  //     options: Options(
  //       headers: {
  //         'If-Modified-Since-Version': ifModifiedSinceVersion,
  //       },
  //     ),
  //     queryParameters: {
  //       'start': index,
  //     },
  //   ).asStream().map((response) {
  //     final collections =
  //     response.data!.map((e)  => CollectionPOJO()).toList();
  //     return Response(collections, response.statusCode!);
  //   });
  // }
  //
  // // 获取用户的文件
  // Observable<Response<ResponseBody>> getFileForUser(
  //     String user, String itemKey) {
  //   return _dio.get<ResponseBody>(
  //     'users/$user/items/$itemKey/file',
  //     options: Options(responseType: ResponseType.stream),
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 获取组的文件
  // Observable<Response<ResponseBody>> getFileForGroup(int group, String itemKey) {
  //   return _dio.get<ResponseBody>(
  //     'groups/$group/items/$itemKey/file',
  //     options: Options(responseType: ResponseType.stream),
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 写入项目
  // Future<ResponseBody> writeItem(String user, List<dynamic> json) {
  //   return _dio.post<ResponseBody>(
  //     'users/$user/items',
  //     data: json,
  //   ).then((response) => response.data!);
  // }
  //
  // // 上传笔记
  // Observable<Response<ResponseBody>> uploadNote(String user, List<dynamic> json) {
  //   return _dio.post<ResponseBody>(
  //     'users/$user/items',
  //     data: json,
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 修补项目
  // Observable<Response<ResponseBody>> patchItem(
  //     String user,
  //     String itemKey,
  //     Map<String, dynamic> json,
  //     int ifUnmodifiedSinceVersion) {
  //   return _dio.patch<ResponseBody>(
  //     'users/$user/items/$itemKey',
  //     data: json,
  //     options: Options(
  //       headers: {
  //         'If-Unmodified-Since-Version': ifUnmodifiedSinceVersion,
  //       },
  //     ),
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 删除项目
  // Future<ResponseBody> deleteItem(
  //     String user, String itemKey, int ifUnmodifiedSinceVersion) {
  //   return _dio.delete<ResponseBody>(
  //     'users/$user/items/$itemKey',
  //     options: Options(
  //       headers: {
  //         'If-Unmodified-Since-Version': ifUnmodifiedSinceVersion,
  //       },
  //     ),
  //   ).then((response) => response.data!);
  // }
  //
  // // 上传附件授权
  // Observable<Response<ResponseBody>> uploadAttachmentAuthorization(
  //     String user,
  //     String itemKey,
  //     String md5,
  //     String filename,
  //     int filesize,
  //     int mtime,
  //     int params,
  //     String bodyText,
  //     String oldMd5Key) {
  //   return _dio.post<ResponseBody>(
  //     'users/$user/items/$itemKey/file',
  //     data: bodyText,
  //     options: Options(
  //       headers: {
  //         'If-Match': oldMd5Key,
  //       },
  //     ),
  //     queryParameters: {
  //       'md5': md5,
  //       'filename': filename,
  //       'filesize': filesize,
  //       'mtime': mtime,
  //       'params': params,
  //     },
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 注册上传
  // Observable<Response<ResponseBody>> registerUpload(
  //     String user, String itemKey, String uploadKey, String body, String oldMd5Key) {
  //   return _dio.post<ResponseBody>(
  //     'users/$user/items/$itemKey/file',
  //     data: body,
  //     options: Options(
  //       headers: {
  //         'If-Match': oldMd5Key,
  //       },
  //     ),
  //     queryParameters: {
  //       'upload': uploadKey,
  //     },
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 上传附件到 Amazon
  // Observable<Response<ResponseBody>> uploadAttachmentToAmazon(
  //     String url, RequestBody data) {
  //   return _dio.post<ResponseBody>(
  //     url,
  //     data: data,
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 多部分上传附件到 Amazon
  // Observable<Response<ResponseBody>> uploadAttachmentToAmazonMulti(
  //     String url,
  //     RequestBody key,
  //     RequestBody acl,
  //     RequestBody content_MD5,
  //     RequestBody success_action_status,
  //     RequestBody policy,
  //     RequestBody x_amz_algorithm,
  //     RequestBody x_amz_credential,
  //     RequestBody x_amz_date,
  //     RequestBody x_amz_signature,
  //     RequestBody x_amz_security_token,
  //     RequestBody attachmentData) {
  //   FormData formData = FormData.fromMap({
  //     'key': key,
  //     'acl': acl,
  //     'Content-MD5': content_MD5,
  //     'success_action_status': success_action_status,
  //     'policy': policy,
  //     'x-amz-algorithm': x_amz_algorithm,
  //     'x-amz-credential': x_amz_credential,
  //     'x-amz-date': x_amz_date,
  //     'x-amz-signature': x_amz_signature,
  //     'x-amz-security-token': x_amz_security_token,
  //     'file': attachmentData,
  //   });
  //
  //   return _dio.post<ResponseBody>(
  //     url,
  //     data: formData,
  //   ).asStream().map((response) =>
  //       Response(response.data!,  response.statusCode!));
  // }
  //
  // // 获取用户设置
  // Observable<Response<ZoteroSettingsResponse>> getSettings(
  //     int ifModifiedSinceVersion, String user, int since) {
  //   return _dio.get<dynamic>(
  //     'users/$user/settings',
  //     options: Options(
  //       headers: {
  //         'If-Modified-Since-Version': ifModifiedSinceVersion,
  //       },
  //     ),
  //     queryParameters: {
  //       'since': since,
  //     },
  //   ).asStream().map((response) {
  //     return Response(ZoteroSettingsResponse(), response.statusCode!);
  //   });
  // }

