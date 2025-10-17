import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';

import '../LibZoteroStorage/entity/Item.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// 定义异常类
class AlreadyUploadedException implements Exception {
  final String message;
  AlreadyUploadedException(this.message);
}

class PreconditionFailedException implements Exception {
  final String message;
  PreconditionFailedException(this.message);
}

class RequestEntityTooLarge implements Exception {
  final String message;
  RequestEntityTooLarge(this.message);
}

class ZoteroNotFoundException implements Exception {
  final String message;
  ZoteroNotFoundException(this.message);
}

// 定义数据模型
class DownloadProgress {
  final int progress;
  final int total;
  final String metadataHash;
  final int mtime;

  DownloadProgress({
    required this.progress,
    required this.total,
    required this.metadataHash,
    required this.mtime,
  });
}

class ZoteroUploadAuthorizationPojo {
  final String? uploadKey;
  final String? url;
  final ZoteroUploadParams? params;

  ZoteroUploadAuthorizationPojo({
    required this.uploadKey,
    required this.url,
    required this.params,
  });

  factory ZoteroUploadAuthorizationPojo.fromJson(Map<String, dynamic> json) {
    return ZoteroUploadAuthorizationPojo(
      uploadKey: json['uploadKey'] ?? "",
      url: json['url'] ?? "",
      params: ZoteroUploadParams.fromJson(json['params']),
    );
  }
}

class ZoteroUploadParams {
  final String key;
  final String acl;
  final String content_MD5;
  final String success_action_status;
  final String policy;
  final String x_amz_algorithm;
  final String x_amz_credential;
  final String x_amz_date;
  final String x_amz_signature;
  final String x_amz_security_token;

  ZoteroUploadParams({
    required this.key,
    required this.acl,
    required this.content_MD5,
    required this.success_action_status,
    required this.policy,
    required this.x_amz_algorithm,
    required this.x_amz_credential,
    required this.x_amz_date,
    required this.x_amz_signature,
    required this.x_amz_security_token,
  });

  factory ZoteroUploadParams.fromJson(Map<String, dynamic> json) {
    return ZoteroUploadParams(
      key: json['key'] ?? "",
      acl: json['acl'] ?? "",
      content_MD5: json['Content-MD5'] ?? "",
      success_action_status: json['success_action_status'] ?? "",
      policy: json['policy'] ?? "",
      x_amz_algorithm: json['x-amz-algorithm'] ?? "",
      x_amz_credential: json['x-amz-credential'] ?? "",
      x_amz_date: json['x-amz-date'] ?? "",
      x_amz_signature: json['x-amz-signature'] ?? "",
      x_amz_security_token: json['x-amz-security-token'] ?? "",
    );
  }
}

// 定义接口
abstract class IAttachmentStorage {
  Future<File> getItemOutputStream(Item item);
  Future<void> deleteAttachment(Item item);
  Future<Uri> getAttachmentUri(Item attachment);
  Future<String> calculateMd5(Item attachment);
  Future<int> getMtime(Item attachment);
  Future<String> getFilenameForItem(Item attachment);
  Future<int> getFileSize(Uri attachmentUri);
  Future<List<int>> readBytes(Item attachment);
}

abstract class IAttachmentTransfer {
  String getTransferType();
  IAttachmentStorage getAttachmentStorage();
  Stream<DownloadProgress> downloadItemRx(Item item, {int groupId = -1});
  Future<void> updateAttachment(Item attachment);
}

class ZoteroAttachmentTransfer implements IAttachmentTransfer {
  final String userID;
  final String API_KEY;
  final IAttachmentStorage attachmentStorageManager;
  final bool useGroup;
  late final Dio _dio;
  late final Dio _amazonDio;

  static const String BASE_URL = "https://api.zotero.org";

  ZoteroAttachmentTransfer({
    required this.userID,
    required this.API_KEY,
    required this.attachmentStorageManager,
    this.useGroup = false,
  }) {
    _dio = _createDio();
    _amazonDio = _createAmazonDio();
  }

  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: BASE_URL,
      connectTimeout:  const Duration(milliseconds: 600000), // 10 minutes
      receiveTimeout: const Duration(milliseconds: 600000),
      sendTimeout: const Duration(milliseconds: 600000),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers.addAll({
          'Zotero-API-Version': '3',
          'Zotero-API-Key': API_KEY,
        });
        return handler.next(options);
      },
    ));
    if (kDebugMode) {
      dio.interceptors.add(
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
    return dio;
  }

  @override
  String getTransferType() {
    return "Zotero";
  }

  @override
  IAttachmentStorage getAttachmentStorage() {
    return attachmentStorageManager;
  }

  @override
  Stream<DownloadProgress> downloadItemRx(Item item, {int groupId = -1}) {
    return _downloadItem(item, groupID: groupId);
  }

  Stream<DownloadProgress> _downloadItem(Item item, {int groupID = -1}) async* {
    final outputFile = await attachmentStorageManager.getItemOutputStream(item);
    final url = useGroup
        ? '/groups/$groupID/items/${item.itemKey}/file'
        : '/users/$userID/items/${item.itemKey}/file';

    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.stream),
      );

      final responseStream = response.data as ResponseBody;
      final total = int.tryParse(response.headers.value('content-length') ?? '0') ?? 0;
      final md5Hash = item.data['md5'] ?? '';
      final mtime = int.tryParse(item.data['mtime'] ?? '0') ?? 0;

      int progress = 0;
      final file = outputFile.openWrite();
      await for (final chunk in responseStream.stream) {
        if (chunk is List<int>) {
          progress += chunk.length;
          file.add(chunk);
          // 这里可以添加进度回调
          yield DownloadProgress(
            progress: progress,
            total: total,
            metadataHash: md5Hash,
            mtime: mtime,
          );
        }
      }
      await file.close();
    } on DioError catch (e) {
      if (e.response?.statusCode == 404) {
        throw ZoteroNotFoundException("Not found on server.");
      } else {
        throw Exception("Download failed: ${e.message}");
      }
    }
  }

  @override
  Future<void> updateAttachment(Item attachment) async {
    final attachmentUri = await attachmentStorageManager.getAttachmentUri(attachment);
    var oldMd5 = attachment.getMd5Key();
    if (oldMd5.isEmpty) {
      oldMd5 = '*';
    }

    final newMd5 = await attachmentStorageManager.calculateMd5(attachment);
    if (oldMd5 == newMd5) {
      throw AlreadyUploadedException("Local attachment version is the same as Zotero's.");
    }

    final mtime = await attachmentStorageManager.getMtime(attachment);
    final filename = await attachmentStorageManager.getFilenameForItem(attachment);
    final filesize = await attachmentStorageManager.getFileSize(attachmentUri);

    try {
      final authorizationPojo = await _getUploadAuthorization(
        attachment,
        oldMd5,
        newMd5,
        filename,
        filesize,
        mtime,
      );

      await _uploadToAmazon(authorizationPojo, attachment, attachmentUri, oldMd5);
    } catch (e) {
      rethrow;
    }
  }

  Future<ZoteroUploadAuthorizationPojo> _getUploadAuthorization(
      Item item,
      String oldMd5,
      String newMd5,
      String filename,
      int filesize,
      int mtime,
      ) async {

    MyLogger.d("upload attachment[${item.itemKey}] version[${item.getVersion()}], oldMD5: $oldMd5 newMD5: $newMd5");

    final url = '/users/$userID/items/${item.itemKey}/file';
    final response = await _dio.post(
      url,
      options: Options(
        headers: {
          'If-Match': oldMd5,
        },
      ),
      data:  {
        'contentType': 'application/x-www-form-urlencoded',
      },
      queryParameters: {
        'md5': newMd5,
        'filename': filename,
        'filesize': filesize,
        'mtime': mtime,
        'params': 1,
      },
    );

    if (response.statusCode == 200) {
      if (response.data['exists'] == 1) {
        throw AlreadyUploadedException("File already uploaded");
      }
      return ZoteroUploadAuthorizationPojo.fromJson(response.data);
    } else {
      throw Exception("Server Response: ${response.statusCode} ${response.data}");
    }
  }

  Future<void> _registerUpload(Item attachment, String uploadKey, String oldMd5) async {
    final url = '/users/$userID/items/${attachment.itemKey}/file';
    final response = await _dio.post(
      url,
      options: Options(
        headers: {
          'If-Match': oldMd5,
        },
      ),
      queryParameters: {
        'upload': uploadKey,
      },
      data: 'upload=$uploadKey',
    );

    switch (response.statusCode) {
      case 204:
        return;
      case 412:
        throw PreconditionFailedException("register upload returned");
      case 413:
        throw RequestEntityTooLarge("Your file is too large");
      default:
        throw Exception("Zotero server replied: ${response.statusCode}");
    }
  }

  Dio _createAmazonDio() {
    // Amazon 上传客户端
    var amazonDio = Dio();
    amazonDio.options.connectTimeout = const Duration(seconds: 30);
    amazonDio.options.receiveTimeout = const Duration(minutes: 10);
    if (kDebugMode) {
      amazonDio.interceptors.add(
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
    return amazonDio;
  }

  _uploadToAmazon(ZoteroUploadAuthorizationPojo authorizationPojo, Item attachment, Uri attachmentUri, String oldMd5) async {
    // 上传到 Amazon
    final formData = FormData.fromMap({
      'key': authorizationPojo.params?.key ?? "",
      'acl': authorizationPojo.params?.acl,
      'Content-MD5': authorizationPojo.params?.content_MD5,
      'success_action_status': authorizationPojo.params?.success_action_status ?? "",
      'policy': authorizationPojo.params?.policy,
      'x-amz-algorithm': authorizationPojo.params?.x_amz_algorithm,
      'x-amz-credential': authorizationPojo.params?.x_amz_credential,
      'x-amz-date': authorizationPojo.params?.x_amz_date,
      'x-amz-signature': authorizationPojo.params?.x_amz_signature,
      'x-amz-security-token': authorizationPojo.params?.x_amz_security_token,
      'file': await MultipartFile.fromFile(Uri.decodeFull(attachmentUri.path)),
    });
    
    MyLogger.d("Moyear=== _uploadToAmazon");

    final amazonResponse = await _amazonDio.post(
      authorizationPojo.url ?? "",
      data: formData,
    );

    if (amazonResponse.statusCode == 412) {
      throw PreconditionFailedException(
          '412 Precondition failed when uploading ${attachment.itemKey}');
    }

    if (amazonResponse.statusCode == 201) {
      // 注册上传到 Zotero
      await _registerUpload(attachment, authorizationPojo.uploadKey ?? "", oldMd5);
    } else {
      throw Exception(
          'Amazon Attachment Server Gave server error: ${amazonResponse
              .statusCode}');
    }
  }
}