import 'package:module_library/ModuleLibrary/share_pref.dart';

class LocalZoteroCredential {
  static const String USER_ID = "user_id";
  static const String API_KEY = "api_key";
  static const String USER_NAME = "user_name";

  static Future<void> saveCredential(String apiKey, String userId, String userName) async {
    await SharedPref.setString(USER_ID, userId);
    await SharedPref.setString(API_KEY, apiKey);
    await SharedPref.setString(USER_NAME, userName);
  }

  static Future<void> clearCredential() async {
    await SharedPref.remove(USER_ID);
    await SharedPref.remove(API_KEY);
    await SharedPref.remove(USER_NAME);
  }

  static Future<String> getUserId() async {
    return SharedPref.getString(USER_ID);
  }

  static Future<String> getApiKey() async {
    return SharedPref.getString(API_KEY);
  }

  static Future<String> getUserName() async {
    return SharedPref.getString(USER_NAME);
  }

  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    final apiKey = await getApiKey();
    return userId.isNotEmpty && apiKey.isNotEmpty;
  }

}

