import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:module_library/LibZoteroAttachment/model/pdf_annotation.dart';
import 'package:module_library/ModuleLibrary/zotero_provider.dart';

/// PdfViewerNativeChannel - Flutter与Android之间的PDF查看器通信桥梁
/// 
/// 主要功能：
/// 1. 向Android端发送打开PDF查看器的请求
/// 2. 处理Android端请求获取PDF注释的调用
///
/// 注意事项：
/// - 必须在使用前调用init()方法来注册方法调用处理器
/// - 所有方法都是异步的，返回Future
/// - 包含完整的错误处理和参数验证
/// - 与Android端的PdfChannel类配合使用
/// 
/// @author Moyear
/// @since 1.0.0
class PdfViewerNativeChannel {
  static const _zoteroChannelName = "com.moyear/pdf_native_channel";  // 1.方法通道名称
  static const MethodChannel _pdfViewerChannel = MethodChannel(_zoteroChannelName);

  static const String KEY_OPEN_PDF_VIEWER = "openPdfViewer";
  static const String KEY_GET_PDF_ANNOTATIONS = "getPdfAnnotations";

  // 初始化状态跟踪
  static bool _isInitialized = false;
  
  /// 检查是否已初始化
  static bool get isInitialized => _isInitialized;


  static Future<dynamic> openPdfViewer({
    required String attachmentKey,
    required String attachmentPath,
    required String attachmentType}) async {
    
    // 确保通道已初始化
    await ensureInitialized();
    
    try {
      final arguments = <String, String>{
        "attachment_key": attachmentKey,
        "attachment_path": attachmentPath,
        "attachment_type": attachmentType,
      };

      debugPrint("Flutter: Opening PDF viewer with arguments: $arguments");
      final result = await _pdfViewerChannel.invokeMethod(KEY_OPEN_PDF_VIEWER, arguments);
      debugPrint("Flutter: PDF viewer opened successfully: $result");
      return result;
    } on PlatformException catch (e) {
      debugPrint("Flutter: Failed to open PDF viewer: '${e.message}'.");
      rethrow;
    }
  }


  static Future<dynamic> init() async {
    if (_isInitialized) {
      debugPrint("Flutter: PdfViewerNativeChannel already initialized");
      return;
    }
    
    debugPrint("Flutter: Initializing PdfViewerNativeChannel");
    
    try {
      _pdfViewerChannel.setMethodCallHandler((MethodCall call) async {
        debugPrint("Flutter: Received method call: ${call.method}");

        switch (call.method) {
          case KEY_GET_PDF_ANNOTATIONS: // 获取PDF注释
            String attachmentKey = call.arguments ?? "";
            
            // 参数验证
            if (attachmentKey.isEmpty) {
              debugPrint("Flutter: getPdfAnnotations called with empty attachmentKey");
              return <Map<String, dynamic>>[];
            }
            
            debugPrint("Flutter: getPdfAnnotations called for attachmentKey: $attachmentKey");

            try {
              // 检查ZoteroProvider是否可用
              final zoteroDB = ZoteroProvider.getZoteroDB();
              if (zoteroDB == null) {
                debugPrint("Flutter: ZoteroDB is not available");
                return <Map<String, dynamic>>[];
              }
              
              // 获取附件的所有annotation
              List<PdfAnnotation> annotations = await zoteroDB.getPdfAnnotations(attachmentKey);
              
              debugPrint("Flutter: Found ${annotations.length} annotations for attachment: $attachmentKey");
              
              // 将PdfAnnotation列表转换为Map列表，以便Android端能够解析
              List<Map<String, dynamic>> annotationMaps = annotations.map((annotation) {
                try {
                  return annotation.toMap();
                } catch (e) {
                  debugPrint("Flutter: Error converting annotation to map: $e");
                  return <String, dynamic>{}; // 返回空Map而不是null
                }
              }).where((map) => map.isNotEmpty).toList(); // 过滤掉空Map
              
              debugPrint("Flutter: Returning ${annotationMaps.length} annotation maps to Android");
              
              return annotationMaps;
            } catch (e) {
              debugPrint("Flutter: Error getting PDF annotations: $e");
              // 返回空列表而不是抛出异常
              return <Map<String, dynamic>>[];
            }
          default:
            debugPrint("Flutter: Unknown method called: ${call.method}");
            return null;
        }

      });
      
      _isInitialized = true;
      debugPrint("Flutter: PdfViewerNativeChannel initialized successfully");
      
    } catch (e) {
      debugPrint("Flutter: Error initializing PdfViewerNativeChannel: $e");
      _isInitialized = false;
      rethrow;
    }
  }

  /// 检查初始化状态并在需要时重新初始化
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      debugPrint("Flutter: PdfViewerNativeChannel not initialized, initializing now");
      await init();
    }
  }



}