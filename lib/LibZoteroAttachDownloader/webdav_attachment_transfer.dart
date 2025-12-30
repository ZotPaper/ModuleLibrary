import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:module_base/utils/log/app_log_event.dart';
import 'package:module_library/LibZoteroAttachDownloader/bean/exception/zotero_upload_exception.dart';
import 'package:module_library/LibZoteroAttachDownloader/zotero_attachment_transfer.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:webdav_client/webdav_client.dart' as WebDAV;
import 'package:path/path.dart' as p;

import 'bean/exception/zotero_download_exception.dart';
import 'package:dio/dio.dart';

/// WebDAV属性文件内容
class WebdavProp {
  final int mtime;
  final String hash;

  WebdavProp(this.mtime, this.hash);

  WebdavProp.fromString(String propContent)
      : mtime = _extractMtime(propContent),
        hash = _extractHash(propContent);

  String serialize() {
    return '<properties version="1"><mtime>$mtime</mtime><hash>$hash</hash></properties>';
  }

  static int _extractMtime(String content) {
    final regex = RegExp(r'<mtime>(\d+)</mtime>');
    final match = regex.firstMatch(content);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  static String _extractHash(String content) {
    final regex = RegExp(r'<hash>([^<]+)</hash>');
    final match = regex.firstMatch(content);
    return match?.group(1) ?? '';
  }
}

class WebDAVAttachmentTransfer implements IAttachmentTransfer {
  final String webdavAddress;
  final String username;
  final String password;
  final bool verifySSL;
  final bool useGroup;
  final IAttachmentStorage attachmentStorageManager;

  // WebDAV客户端
  late WebDAV.Client client;
  String? _baseAddress;

  WebDAVAttachmentTransfer({
    required this.webdavAddress,
    required this.username,
    required this.password,
    required this.attachmentStorageManager,
    this.verifySSL = true,
    this.useGroup = false,
  }) {
    _initializeClient();
  }

  void _initializeClient() {
    // todo 解决zotoro后缀的问题
    // 标准化WebDAV地址
    String normalizedAddress = webdavAddress;
    if (normalizedAddress.endsWith("/zotero") ||
        normalizedAddress.endsWith("/zotero/")) {
      _baseAddress = normalizedAddress;
    } else {
      if (normalizedAddress.endsWith("/")) {
        _baseAddress = normalizedAddress + "zotero";
      } else {
        _baseAddress = normalizedAddress + "/zotero";
      }
    }

    var debug = false;
    final wbDio = WebDAV.WdDio();

    client = WebDAV.Client(
      uri: normalizedAddress,
      c: wbDio,
      auth: WebDAV.Auth(user: username, pwd: password),
      debug: debug,
    );

    client.setHeaders({
      "Accept-Encoding": "identity",
      //添加这句话避免gzip压缩导致在Response中获取不到Content-Length属性
    });
  }

  @override
  Stream<DownloadProgress> downloadItemRx(Item item, {int groupId = -1}) {
    return _downloadAttachment(item);
  }

  bool _isValidUrl(String url) {
    try {
      final Uri uri = Uri.parse(url);
      // 检查是否包含scheme(http/https)和host
      if (uri.scheme.isEmpty || uri.host.isEmpty) {
        return false;
      }
      // 只允许http和https协议
      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 下载附件的核心实现
  Stream<DownloadProgress> _downloadAttachment(Item item) async* {
    try {
      final itemKey = item.itemKey.toUpperCase();
      final webpathProp = '$_baseAddress/$itemKey.prop';
      final webpathZip = '$_baseAddress/$itemKey.zip';

      // 先验证_baseAddress是不是一个有效的地址
      if (!_isValidUrl(_baseAddress!)) {
        throw WedDAVException('Invalid WebDAV address');
      }

      // 1. 下载.prop文件获取元数据
      WebdavProp prop;
      try {
        final propBytes = await client.read(webpathProp);
        final propContent = String.fromCharCodes(propBytes);
        prop = WebdavProp.fromString(propContent);
      } catch (e) {
        var errorMsg = e.toString();
        if (e is DioException) {
          errorMsg = '[${e.response?.statusCode}] ${e.message}';
        }

        throw DownloadException(
            errorType: DownloadErrorType.notFound,
            message: 'Failed to download .prop file: $errorMsg');
      }

      // 2. 获取ZIP文件大小（用于进度计算）
      int? zipFileSize;
      try {
        // 注意：webdav_client可能不支持获取文件大小，这里使用默认值
        zipFileSize = null; // 如果无法获取，进度将是不确定的
      } catch (e) {
        // 忽略错误，使用不确定的进度
      }

      // 3. 创建临时文件用于下载
      final tempFile = await attachmentStorageManager.getItemOutputStream(item);

      MyLogger.d("开始下载附件：$webpathZip 到临时文件：${tempFile.path}");

      // 4. 下载ZIP文件到临时位置
      yield* _downloadWithProgress(
          webpathZip, tempFile as File, zipFileSize, prop);

      // 5. 解压ZIP文件
      yield DownloadProgress(
          progress: 95, total: 100, mtime: prop.mtime, metadataHash: prop.hash);

      await _extractZipFile(tempFile as File, item);

      // 6. 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // 7. 完成下载
      yield DownloadProgress(
          progress: 100,
          total: 100,
          mtime: prop.mtime,
          metadataHash: prop.hash);
    } catch (e) {
      rethrow;
    }
  }

  /// 带进度的下载实现
  Stream<DownloadProgress> _downloadWithProgress(String remotePath,
      File localFile, int? totalSize, WebdavProp prop) async* {
    final controller = StreamController<DownloadProgress>();
    try {
      int downloaded = 0;
      int total = totalSize ?? 0;

      unawaited(
        client.read2File(
          remotePath,
          localFile.path,
          onProgress: (int bytes, int totalBytes) {
            downloaded = bytes;
            total = totalBytes;
            controller.add(DownloadProgress(
              progress: downloaded,
              total: total,
              mtime: prop.mtime,
              metadataHash: prop.hash,
            ));
          },
        ).then((_) {
          controller.close();
        }).catchError((e) {
          controller.addError(Exception('Download failed: $e'));
          controller.close();
        }),
      );

      yield* controller.stream;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// 解压ZIP文件到最终位置
  /// 遍历ZIP中的所有文件和目录并解压到目标目录
  Future<void> _extractZipFile(File zipFile, Item item) async {
    try {
      // 读取ZIP文件内容
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      if (archive.files.isEmpty) {
        throw ZipException('文件不存在或已损坏');
      }

      // 获取目标附件目录
      final attachmentDir = p.dirname(
          (await attachmentStorageManager.getItemOutputStream(item)).path);

      // 确保根目录存在
      await Directory(attachmentDir).create(recursive: true);

      // 获取期望的主附件文件名（用于 attachmentExists 检查）
      final expectedFilename = await attachmentStorageManager.getFilenameForItem(item);
      final expectedExtension = p.extension(expectedFilename).toLowerCase();

      int extractedFileCount = 0;
      int extractedDirCount = 0;
      int totalSize = 0;

      // 遍历所有条目（包括目录和文件）
      for (final archiveEntry in archive.files) {
        final originalPath = archiveEntry.name;

        if (archiveEntry.isFile) {
          // 处理文件
          String targetPath = originalPath;

          // 获取文件名（不含路径）
          final originalFilename = p.basename(originalPath);
          final originalExtension = p.extension(originalFilename).toLowerCase();

          // 如果这是主附件文件（扩展名匹配且在根目录），使用期望的文件名
          // 这样可以确保 attachmentExists 能够正确检测到文件
          if (originalExtension == expectedExtension && !originalPath.contains('/')) {
            targetPath = expectedFilename;
            if (kDebugMode) {
              MyLogger.d('主附件文件: $originalPath -> $targetPath');
            }
          }

          final finalFile = File(p.join(attachmentDir, targetPath));

          // 确保文件的父目录存在
          await finalFile.parent.create(recursive: true);

          // 解压文件内容
          final fileContent = archiveEntry.content;
          await finalFile.writeAsBytes(fileContent);

          // 验证解压后的文件
          if (!await finalFile.exists()) {
            throw ZipException('解压后的文件未能正确创建: $targetPath');
          }

          final extractedSize = await finalFile.length();
          if (extractedSize == 0 && archiveEntry.size > 0) {
            throw ZipException('解压后的文件大小为0: $targetPath');
          }

          extractedFileCount++;
          totalSize += extractedSize;

          if (kDebugMode) {
            MyLogger.d('解压文件: $targetPath ($extractedSize bytes)');
          }
        } else {
          // 处理目录：创建目录结构
          final targetDir = Directory(p.join(attachmentDir, originalPath));
          await targetDir.create(recursive: true);
          extractedDirCount++;

          if (kDebugMode) {
            MyLogger.d('创建目录: $originalPath');
          }
        }
      }

      if (extractedFileCount == 0) {
        throw ZipException('ZIP文件中没有找到有效的附件文件');
      }

      if (kDebugMode) {
        MyLogger.d('成功解压附件: 共 $extractedFileCount 个文件, $extractedDirCount 个目录, 总大小 $totalSize bytes');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateAttachment(Item attachment) async {
    try {
      final itemKey = attachment.itemKey.toUpperCase();

      // 1. 创建ZIP文件
      final zipFile = await _createZipFile(attachment);

      // 2. 创建.prop文件
      final propFile = await _createPropFile(attachment);

      // 3. 上传临时文件到WebDAV
      await _uploadFiles(itemKey, zipFile, propFile);

      // 4. 删除和重命名文件
      await _finalizeUpload(itemKey);

      // 5. 清理临时文件
      await zipFile.delete();
      await propFile.delete();
    } catch (e) {
      if (e is UploadException) {
        rethrow;
      } else {
        throw UploadException(message: 'Upload failed: $e', errorType: ErrorType.unknown);
      }
    }
  }

  /// 创建ZIP文件
  Future<File> _createZipFile(Item attachment) async {
    final sourceUri =
        await attachmentStorageManager.getAttachmentUri(attachment);
    final sourceFile = File.fromUri(sourceUri);

    if (!await sourceFile.exists()) {
      throw FileNotFoundException('源文件不存在: ${sourceFile.path}');
    }

    // 创建临时ZIP文件
    final tempDir = Directory.systemTemp;
    final zipFile = File(
        p.join(tempDir.path, '${attachment.itemKey.toUpperCase()}_NEW.zip'));

    try {
      // 获取原始文件名和内容
      final filename =
          await attachmentStorageManager.getFilenameForItem(attachment);
      final sourceBytes = await sourceFile.readAsBytes();

      // 验证源文件
      if (sourceBytes.isEmpty) {
        throw UploadException(message: '找不到源文件：${sourceFile.path}', errorType: ErrorType.notFound);
      }

      // 创建ZIP归档
      final archive = Archive();

      // 创建归档文件条目
      final archiveFile =
          ArchiveFile(filename, sourceBytes.length, sourceBytes);

      // 设置文件属性
      archiveFile.mode = 644; // 标准文件权限
      archiveFile.isFile = true;

      // 添加到归档
      archive.addFile(archiveFile);

      // 编码ZIP文件
      final zipBytes = ZipEncoder().encode(archive);

      // 写入ZIP文件
      await zipFile.writeAsBytes(zipBytes);

      // 验证创建的ZIP文件
      if (!await zipFile.exists()) {
        throw ZipException('ZIP文件创建失败');
      }

      final zipSize = await zipFile.length();
      if (zipSize == 0) {
        throw ZipException('创建的ZIP文件大小为0');
      }

      if (kDebugMode) {
        MyLogger.d('成功创建ZIP文件: $filename -> ${zipFile.path} ($zipSize bytes)');
      }

      return zipFile;
    } catch (e) {
      // 清理失败的临时文件
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
      if (e is ZipException) {
        throw ZipException('ZIP压缩失败: ${e.message}');
      } else {
        throw ZipException('ZIP压缩失败: $e');
      }
    }
  }

  /// 创建.prop文件
  Future<File> _createPropFile(Item attachment) async {
    final tempDir = Directory.systemTemp;
    final propFile = File(
        p.join(tempDir.path, '${attachment.itemKey.toUpperCase()}_NEW.prop'));

    final mtime = await attachmentStorageManager.getMtime(attachment);
    final hash = await attachmentStorageManager.calculateMd5(attachment);

    final prop = WebdavProp(mtime, hash);
    final propContent = prop.serialize();

    await propFile.writeAsString(propContent);
    return propFile;
  }

  /// 上传文件到WebDAV
  Future<void> _uploadFiles(String itemKey, File zipFile, File propFile) async {
    final newZipPath = '$_baseAddress/${itemKey}_NEW.zip';
    final newPropPath = '$_baseAddress/${itemKey}_NEW.prop';

    // 删除可能存在的旧的_NEW文件
    try {
      await client.remove(newPropPath);
      await client.remove(newZipPath);
    } catch (e) {
      // 忽略错误，文件可能不存在
    }

    MyLogger.d("准备上传新的文件到webdav: ${zipFile.path} -> $newZipPath");

    // 上传新文件
    final propBytes = await propFile.readAsBytes();
    final zipBytes = await zipFile.readAsBytes();

    try {
      await client.write(newPropPath, Uint8List.fromList(propBytes));
    } catch (e) {
      MyLogger.e("上传新的文件[${newPropPath}]到webdav发生错误：$e");
    }

    try {
      await client.write(newZipPath, Uint8List.fromList(zipBytes));
    } catch (e) {
      MyLogger.e("上传新的文件[${newZipPath}]到webdav发生错误：$e");
    }
  }

  /// 完成上传：删除旧文件并重命名新文件
  Future<void> _finalizeUpload(String itemKey) async {
    final zipPath = '$_baseAddress/$itemKey.zip';
    final propPath = '$_baseAddress/$itemKey.prop';
    final newZipPath = '$_baseAddress/${itemKey}_NEW.zip';
    final newPropPath = '$_baseAddress/${itemKey}_NEW.prop';

    // 删除旧文件
    try {
      await client.remove(propPath);
      await client.remove(zipPath);
    } catch (e) {
      // 如果旧文件不存在，忽略错误
    }

    // 重命名新文件（通过复制和删除实现）
    final newPropBytes = await client.read(newPropPath);
    final newZipBytes = await client.read(newZipPath);

    await client.write(propPath, Uint8List.fromList(newPropBytes));
    await client.write(zipPath, Uint8List.fromList(newZipBytes));

    // 删除临时文件
    await client.remove(newPropPath);
    await client.remove(newZipPath);
  }

  @override
  IAttachmentStorage getAttachmentStorage() {
    return attachmentStorageManager;
  }

  @override
  String getTransferType() {
    return "WebDAV";
  }
}
