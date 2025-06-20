import 'dart:ui';

import 'package:flutter/material.dart';

class ColorUtils {

  static Color hexToColor(String hex) {
    if (hex.isEmpty) {
      return Colors.transparent;
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // 添加默认不透明度
    }
    return Color(int.parse(hex, radix: 16));
  }

}