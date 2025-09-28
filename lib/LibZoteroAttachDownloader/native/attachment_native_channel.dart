import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';

class PdfViewerNativeChannel {
  static const _zoteroChannelName = "com.moyear/pdf_native_channel";  // 1.方法通道名称
  static const MethodChannel _pdfViewerChannel = MethodChannel(_zoteroChannelName);

  static const String KEY_OPEN_PDF_VIEWER = "openPdfViewer";

  static const String KEY_GET_PDF_ANNOTATIONS = "getPdfAnnotations";



  static Future<dynamic> openPdfViewer({
    required String attachmentKey,
    required String attachmentPath,
    required String attachmentType}) async {
    try {
      final arguments = <String, String>{
        "attachment_key": attachmentKey,
        "attachment_path": attachmentPath,
        "attachment_type": attachmentType,
      };

      final String result = await _pdfViewerChannel.invokeMethod(KEY_OPEN_PDF_VIEWER, arguments);
    } on PlatformException catch (e) {
      debugPrint("Failed to get user name: '${e.message}'.");
    }
  }


  static Future<dynamic> init() async {
    _pdfViewerChannel.setMethodCallHandler((MethodCall call) async {

      switch (call.method) {
        case KEY_GET_PDF_ANNOTATIONS: // 获取
          String attachmentKey = call.arguments ?? "";

          ZoteroDB zoteroDB = ZoteroDB();
          Item? attachmentItem = await zoteroDB.getItemByKey(attachmentKey);

          // todo 获取附件的所有annotation


          break;

        default:
          return null;
      }

    });
  }







}