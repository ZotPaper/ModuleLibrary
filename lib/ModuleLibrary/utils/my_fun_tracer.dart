import 'package:flutter/foundation.dart';

import 'my_logger.dart';

class MyFunTracer {
  static const String TAG = "MyFunTracer";

  static Map<String, DateTime> _traceMap = {};

  static void log(String msg) {
    MyLogger.d(msg, tag: TAG);
  }

  static void beginTrace({String msg = "", String? customKey}) {
    if (!kDebugMode) return;

    // 获取调用的函数名
    final key = customKey ?? _getCallerKey();
    if (_traceMap.containsKey(key)) {
      MyLogger.w("[$TAG] ⚠️ Trace already started for key: $key");
      return;
    }

    _traceMap[key] = DateTime.now();

    MyLogger.d("[$TAG] 🚀 BEGIN [$key] ${msg.isNotEmpty ? '($msg)' : ''}");

  }

  static void endTrace({String msg = "", String? customKey}) {
    if (!kDebugMode) return;

    final key = customKey ?? _getCallerKey();
    final startTime = _traceMap.remove(key);

    if (startTime == null) {
      MyLogger.w("[$TAG] ⚠️ No matching beginTrace for key: $key");
      return;
    }

    final duration = DateTime.now().difference(startTime);
    MyLogger.d("[$TAG] ✅ END [$key] ${msg.isNotEmpty ? '($msg)' : ''} "
        "⏱️ ${duration.inMilliseconds}ms");
  }

  static String _getCallerKey() {
    try {
      final stack = StackTrace.current;
      final frames = stack.toString().split('\n');

      // 查找第一个非 MyFunTracer 的堆栈帧
      for (final frame in frames) {
        if (!frame.contains('MyFunTracer') &&
            !frame.contains('<asynchronous suspension>')) {
          return _parseFrame(frame);
        }
      }

      return _parseFrame(frames.length > 2 ? frames[2] : frames.last);
    } catch (e) {
      MyLogger.e("[$TAG] Failed to parse stack trace: $e");
      return "unknown_function";
    }
  }

  static String _parseFrame(String frame) {
    try {
      // 不同环境下的堆栈格式处理
      if (frame.contains('(') && frame.contains(')')) {
        // Flutter/Dart VM 格式: #0 Class.function (file.dart:line:column)
        final parts = frame.split(' ');
        if (parts.length > 1) {
          return parts.sublist(1).join(' ').replaceAll(RegExp(r' \(.*\)$'), '');
        }
      } else if (frame.contains('-')) {
        // Web/JS 格式: at Class.function (http://localhost:12345/file.dart:123:45)
        return frame
            .split('-')
            .first
            .trim();
      }

      // 通用回退方案
      return frame
          .replaceAll(RegExp(r'#\d+\s+'), '')
          .replaceAll(RegExp(r' \(.*\)$'), '')
          .trim();
    } catch (e) {
      MyLogger.e("[$TAG] Frame parse error: $e");
      return frame;
    }
  }

  /// 自动跟踪函数执行的便捷方法
  static T trace<T>(T Function() fn, {String tag = ""}) {
    final key = _getCallerKey();
    beginTrace(customKey: key, msg: tag);
    try {
      return fn();
    } finally {
      endTrace(customKey: key, msg: tag);
    }
  }

  /// 异步函数跟踪
  static Future<T> traceAsync<T>(Future<T> Function() fn, {String tag = ""}) async {
    final key = _getCallerKey();
    beginTrace(customKey: key, msg: tag);
    try {
      return await fn();
    } finally {
      endTrace(customKey: key, msg: tag);
    }
  }

}