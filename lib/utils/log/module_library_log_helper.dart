import 'package:module_base/utils/log/app_log_event.dart';
import 'package:module_base/utils/tracking/dot_tracker.dart';

import '../../LibZoteroAttachDownloader/bean/exception/zotero_download_exception.dart';
import '../../LibZoteroAttachDownloader/default_attachment_storage.dart';
import '../../LibZoteroAttachDownloader/model/transfer_info.dart';
import '../../LibZoteroAttachDownloader/webdav_attachment_transfer.dart';
import '../../LibZoteroAttachDownloader/zotero_attach_downloader_helper.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../webdav_configuration.dart';

class ModuleLibraryLogHelper {
  static const String tag = "ModuleLibrary";

  static AttachmentTransferLogger attachmentTransfer = AttachmentTransferLogger();

}

class AttachmentTransferLogger {
  static const String tag = "AttachmentLoger";

  /// 上报下载成功信息
  Future<void> logDownloadSuccess(AttachmentDownloadInfo info, Item targetPdfAttachmentItem) async {
    var totalSize = await DefaultAttachmentStorage.instance.getFileSizeFromItem(targetPdfAttachmentItem);
    var totalSizeStr = "${(totalSize / 1024).floor()} KB";
    var downloadSuccessLog = {
      'type': 'Zotero',
      'title': targetPdfAttachmentItem.getTitle(),
      'totalSize': totalSizeStr,
    };
    if (ZoteroAttachDownloaderHelper.instance.transfer is WebDAVAttachmentTransfer) {
      downloadSuccessLog = {
        'type': 'WebDAV',
        'title': targetPdfAttachmentItem.getTitle(),
        'webdav_path': WebdavConfiguration.webdavUrl,
        'totalSize': totalSizeStr,
      };
    }

    logEvent(message: "附件下载成功：$downloadSuccessLog", logLevel: LogLevel.info);
    DotTracker
        .addBot("ATTACHMENT_DOWNLOAD_SUCCESS", description: "附件下载成功")
        .addParam("detail", downloadSuccessLog)
        .report();
  }

  /// 记录下载失败
  void logDownloadError(Item item, Object e) {
    var errorMsg = e.toString();
    if (e is DownloadException) {
      errorMsg = "errorType: ${e.errorType} errorMsg: ${e.message}";
    }

    var downloadErrorLog = {
      'type': 'Zotero',
      'title': item.getTitle(),
      'error': errorMsg,
    };
    if (ZoteroAttachDownloaderHelper.instance.transfer is WebDAVAttachmentTransfer) {
      downloadErrorLog = {
        'type': 'WebDAV',
        'title': item.getTitle(),
        'webdav_path': WebdavConfiguration.webdavUrl,
        'error': errorMsg,
      };
    }

    logEvent(message: "附件下载失败：$downloadErrorLog", logLevel: LogLevel.error);
    DotTracker
        .addBot("ATTACHMENT_DOWNLOAD_FAIL", description: "附件下载失败")
        .addParam("detail", downloadErrorLog)
        .report();
  }


  /// 记录上传错误
  void logUploadError(Item item, Object e) {
    var uploadErrorLog = {
      'type': 'Zotero',
      'title': item.getTitle(),
      'error': e.toString(),
    };
    if (ZoteroAttachDownloaderHelper.instance.transfer is WebDAVAttachmentTransfer) {
      uploadErrorLog = {
        'type': 'WebDAV',
        'title': item.getTitle(),
        'webdav_path': WebdavConfiguration.webdavUrl,
        'error': e.toString(),
      };
    }

    logEvent(message: "附件上传失败: $uploadErrorLog", logLevel: LogLevel.error);
    DotTracker
        .addBot("ATTACHMENT_UPLOAD_SUCCESS", description: "附件上传失败")
        .addParam("detail", uploadErrorLog)
        .report();
  }

  /// 上报上传成功信息
  Future<void> logUploadSuccess(Item targetPdfAttachmentItem) async {
    var totalSize = await DefaultAttachmentStorage.instance.getFileSizeFromItem(targetPdfAttachmentItem);
    var totalSizeStr = "${(totalSize / 1024).floor()} KB";
    var uploadSuccessLog = {
      'type': 'Zotero',
      'title': targetPdfAttachmentItem.getTitle(),
      'totalSize': totalSizeStr,
    };
    if (ZoteroAttachDownloaderHelper.instance.transfer is WebDAVAttachmentTransfer) {
      uploadSuccessLog = {
        'type': 'WebDAV',
        'title': targetPdfAttachmentItem.getTitle(),
        'webdav_path': WebdavConfiguration.webdavUrl,
        'totalSize': totalSizeStr,
      };
    }

    logEvent(message: "附件上传成功：$uploadSuccessLog", logLevel: LogLevel.info);
    DotTracker
        .addBot("ATTACHMENT_UPLOAD_SUCCESS", description: "附件上传成功")
        .addParam("detail", uploadSuccessLog)
        .report();
  }


}