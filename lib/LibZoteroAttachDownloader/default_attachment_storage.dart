import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:module_library/LibZoteroStorage/database/dao/RecentlyOpenedAttachmentDao.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:path/path.dart' as path;

import 'package:module_library/LibZoteroAttachDownloader/zotero_attachment_transfer.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/LibZoteroStorage/storage_provider.dart';

class DefaultAttachmentStorage implements IAttachmentStorage {
  /// 附件存放的路径在sdcard/Android/data/应用包名/files/zotero/storage
  /// 每个文件夹的名称都是attachmentItem的itemKey，里面对应的是附件文件
  ///

  DefaultAttachmentStorage._();
  static final DefaultAttachmentStorage instance = DefaultAttachmentStorage._();


  static const String STORAGE_DIR = "zotero/storage";
  
  Directory? _storageDir;

  /// 获取或创建存储目录
  Future<Directory> _getStorageDirectory() async {
    if (_storageDir != null) return _storageDir!;
    
    final appDir = await StorageProvider.getAppStorageDir();
    if (appDir == null) {
      throw Exception("无法获取应用存储目录");
    }
    
    _storageDir = Directory(path.join(appDir.path, STORAGE_DIR));
    if (!await _storageDir!.exists()) {
      await _storageDir!.create(recursive: true);
    }
    
    return _storageDir!;
  }

  /// 获取附件存储目录（基于itemKey）
  Future<Directory> _getAttachmentDirectory(String itemKey) async {
    final storageDir = await _getStorageDirectory();
    final attachmentDir = Directory(path.join(storageDir.path, itemKey));
    
    if (!await attachmentDir.exists()) {
      await attachmentDir.create(recursive: true);
    }
    
    return attachmentDir;
  }

  @override
  Future<String> calculateMd5(Item attachment) async {
    try {
      final file = await _getAttachmentFile(attachment);
      if (!await file.exists()) {
        return '';
      }
      
      final bytes = await file.readAsBytes();
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      return '';
    }
  }

  @override
  Future<void> deleteAttachment(Item item) async {
    try {
      final attachmentDir = await _getAttachmentDirectory(item.itemKey);
      if (await attachmentDir.exists()) {
        await attachmentDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception("删除附件失败: $e");
    }
  }

  @override
  Future<Uri> getAttachmentUri(Item attachment) async {
    final file = await _getAttachmentFile(attachment);
    return file.uri;
  }

  Future<File> getAttachmentFile(Item attachment) async {
    final file = await _getAttachmentFile(attachment);
    return file;
  }


  @override
  Future<int> getFileSize(Uri attachmentUri) async {
    try {
      final file = File.fromUri(attachmentUri);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<String> getFilenameForItem(Item attachment) async {
    // 从Item数据中获取文件名
    String filename = attachment.getItemData('filename') ?? '';
    if (filename.isEmpty) {
      filename = attachment.getItemData('title') ?? 'attachment';
      // 根据content type添加扩展名
      final extension = _getExtensionFromContentType(attachment.getItemData('contentType'));
      if (extension.isNotEmpty && !filename.endsWith('.$extension')) {
        filename += '.$extension';
      }
    }
    return filename;
  }

  String _getExtensionFromContentType(String? contentType) {
    if (contentType == null) return '';
    
    switch (contentType.toLowerCase()) {
      case 'application/pdf':
        return 'pdf';
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'application/zip':
        return 'zip';
      case 'text/plain':
        return 'txt';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'docx';
      default:
        return '';
    }
  }

  @override
  Future<File> getItemOutputStream(Item item) async {
    final attachmentDir = await _getAttachmentDirectory(item.itemKey);
    final filename = await getFilenameForItem(item);
    
    // 对于ZIP下载，使用临时文件名
    final outputFile = File(path.join(attachmentDir.path, '$filename.tmp'));
    
    // 确保文件父目录存在
    final parentDir = outputFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    
    return outputFile;
  }

  @override
  Future<int> getMtime(Item attachment) async {
    final file = await _getAttachmentFile(attachment);
    if (await file.exists()) {
      final stat = await file.stat();
      return stat.modified.millisecondsSinceEpoch ~/ 1000;
    }
    return 0;
  }

  @override
  Future<List<int>> readBytes(Item attachment) async {
    final file = await _getAttachmentFile(attachment);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return [];
  }

  /// 获取附件文件
  Future<File> _getAttachmentFile(Item attachment) async {
    final attachmentDir = await _getAttachmentDirectory(attachment.itemKey);
    final filename = await getFilenameForItem(attachment);
    return File(path.join(attachmentDir.path, filename));
  }

  /// 检查附件是否存在
  Future<bool> attachmentExists(Item attachment) async {
    final file = await _getAttachmentFile(attachment);
    return await file.exists();
  }

  /// 获取附件下载临时文件
  Future<File> getDownloadTempFile(Item item) async {
    final attachmentDir = await _getAttachmentDirectory(item.itemKey);
    final filename = await getFilenameForItem(item);
    
    // 返回与getItemOutputStream相同的临时文件路径
    return File(path.join(attachmentDir.path, '$filename.tmp'));
  }

  /// 完成下载，将临时文件重命名为最终文件
  Future<void> completeDownload(Item item, File tempFile) async {
    if (!await tempFile.exists()) {
      throw Exception('临时文件不存在: ${tempFile.path}');
    }

    final attachmentDir = await _getAttachmentDirectory(item.itemKey);
    
    // 获取正确的文件名（包含扩展名）
    final filename = await getFilenameForItem(item);
    final finalFile = File(path.join(attachmentDir.path, filename));
    
    try {
      // 如果最终文件已存在，先删除
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      
      // 重命名临时文件为最终文件
      await tempFile.rename(finalFile.path);
      
      // 验证文件是否成功创建
      if (!await finalFile.exists()) {
        throw Exception('文件重命名失败，最终文件不存在: ${finalFile.path}');
      }
      
    } catch (e) {
      throw Exception('完成下载时出错: $e');
    }
  }

  /// 提取ZIP文件到附件目录
  Future<void> extractZipFile(Item item, File zipFile) async {
    // 这里需要使用archive包来解压ZIP文件
    // 由于没有引入archive包，这里提供接口，实际使用时需要添加依赖
    throw UnimplementedError("需要添加archive包依赖来实现ZIP解压功能");
  }

  Future<bool> validateMd5ForItem(Item item, String md5key) async {
    if (item.itemType != Item.ATTACHMENT_TYPE) {
      throw(Exception("error invalid item ${item.itemKey}: ${item.itemType} cannot calculate md5."));
    }
    if (md5key == "") {
      MyLogger.d("error cannot check MD5, no MD5 Available");
      return true;
    }
    final calculatedMd5 = await calculateMd5(item);
    return calculatedMd5 == md5key;
  }
}