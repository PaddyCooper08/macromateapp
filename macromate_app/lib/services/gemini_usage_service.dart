import 'package:shared_preferences/shared_preferences.dart';

class GeminiUsageService {
  static const String _geminiUsesKey = 'gemini_uses';
  static const String _adFreeKey = 'ad_free';

  static Future<int> getGeminiUses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_geminiUsesKey) ?? 0;
  }

  static Future<void> setGeminiUses(int uses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_geminiUsesKey, uses);
  }

  static Future<void> incrementGeminiUses(int increment) async {
    final uses = await getGeminiUses();
    await setGeminiUses(uses + increment);
  }

  static Future<void> resetGeminiUses() async {
    await setGeminiUses(0);
  }

  static Future<bool> isAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adFreeKey) ?? false;
  }

  static Future<void> setAdFree(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adFreeKey, value);
  }
}
