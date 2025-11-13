import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

class DeviceUtils {
  /// 判断是否为平板设备
  /// 基于屏幕尺寸和屏幕方向来判断
  static bool isTablet(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    
    // 优先使用shortestSide进行判断（更可靠）
    // 600dp是Android平板的标准阈值
    final bool isLargeScreen = size.shortestSide >= 600;
    
    // 对于横屏，额外检查长边是否足够大
    final bool isWideScreen = size.longestSide >= 960;
    
    return isLargeScreen && isWideScreen;
  }
  
  /// 获取适合平板的侧边栏宽度
  static double getDrawerWidth(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (isTablet(context)) {
      // 平板上侧边栏占屏幕宽度的25%-30%，但不超过320px
      return (size.width * 0.28).clamp(280.0, 320.0);
    }
    return 280.0; // 手机默认宽度
  }
  
  /// 判断是否应该显示固定侧边栏
  /// 只有在平板设备且横屏时才显示固定侧边栏
  static bool shouldShowFixedDrawer(BuildContext context) {
    if (!isTablet(context)) return false;
    
    final mediaQuery = MediaQuery.of(context);
    final orientation = mediaQuery.orientation;
    
    // 只在横屏时显示固定侧边栏
    return orientation == Orientation.landscape;
  }
} 