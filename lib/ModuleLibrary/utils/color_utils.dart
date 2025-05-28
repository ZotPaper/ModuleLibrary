import 'dart:ui';

class ColorUtils {

  static Color hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // 添加默认不透明度
    }
    return Color(int.parse(hex, radix: 16));
  }

}