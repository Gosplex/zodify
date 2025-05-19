import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const _keyLoggedIn = 'isLoggedIn';
  static const _keyUserId = 'userId';

  static Future<void> setLoggedIn(bool value, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, value);
    if (userId != null) {
      await prefs.setString(_keyUserId, userId);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUserId);
  }
}