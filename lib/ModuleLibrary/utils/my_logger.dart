import 'package:flutter/foundation.dart';

class MyLogger {
  static const String TAG = "ModuleLibrary";

  static void d(String msg, {String tag = TAG,}){
    debugPrint("$tag: $msg");
  }

  static void v(String msg, {String tag = TAG,}){
    debugPrint("$tag: $msg");
  }

  static void e(String msg, {String tag = TAG}){
    debugPrint("$tag: $msg");
  }

  static void i(String msg, {String tag = TAG}){
    debugPrint("$tag: $msg");
  }

  static void w(String msg, {String tag = TAG}){
    debugPrint("$tag: $msg");
  }

}