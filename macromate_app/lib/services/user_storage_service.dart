import 'package:shared_preferences/shared_preferences.dart';

class UserStorageService {
  static const String _userIdKey = 'user_id';
  static const String _authSourceKey = 'auth_source'; // 'telegram' | 'supabase'

  // Save user ID to local storage
  static Future<void> saveUserId(String userId, {String? source}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    if (source != null) {
      await prefs.setString(_authSourceKey, source);
    }
  }

  // Get user ID from local storage
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get auth source
  static Future<String?> getAuthSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authSourceKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }

  // Clear user data (logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_authSourceKey);
  }
}
