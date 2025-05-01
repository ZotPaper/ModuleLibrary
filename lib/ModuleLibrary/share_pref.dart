import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  // Singleton pattern
  static final SharedPref _instance = SharedPref._internal();
  factory SharedPref() => _instance;
  SharedPref._internal();

  static SharedPreferences? _prefs;

  // Initialize the SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Clear all saved data
  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // Remove a specific key
  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  // Check if a key exists
  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  //* String methods
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  static String getString(String key, [String defaultValue = '']) {
    return _prefs?.getString(key) ?? defaultValue;
  }

  //* Int methods
  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  static int getInt(String key, [int defaultValue = 0]) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  //* Double methods
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  static double getDouble(String key, [double defaultValue = 0.0]) {
    return _prefs?.getDouble(key) ?? defaultValue;
  }

  //* Bool methods
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  static bool getBool(String key, [bool defaultValue = false]) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  //* List<String> methods
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  static List<String> getStringList(String key,
      [List<String> defaultValue = const []]) {
    return _prefs?.getStringList(key) ?? defaultValue;
  }

  //* Object methods (uses JSON serialization)
  static Future<bool> setObject<T>(String key, T value) async {
    if (value == null) return await remove(key);
    try {
      final json = _jsonEncode(value);
      return await setString(key, json);
    } catch (e) {
      return false;
    }
  }

  static T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final jsonString = getString(key);
    if (jsonString.isEmpty)  return null;
    try {
      final jsonMap = _jsonDecode(jsonString);
      return fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  // Helper methods for JSON encoding/decoding
  static String _jsonEncode(Object object) {
    // If you need more complex serialization, consider using json_serializable
    // or another JSON package
    return jsonEncode(object);
  }

  static Map<String, dynamic> _jsonDecode(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}

class PrefString{
  static var isFirst = "isFirstStart";
}