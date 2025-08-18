import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white, // unify background
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, // match light icon background
      surfaceTintColor: Colors.transparent, // remove M3 tonal overlay
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[500],
      foregroundColor: Colors.white,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.white,
      onSecondary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      error: Colors.white,
      onError: Colors.black,
      outline: Colors.white24,
      outlineVariant: Colors.white12,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: Colors.white24, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Colors.white),
      headlineMedium: TextStyle(color: Colors.white),
      headlineSmall: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
      labelLarge: TextStyle(color: Colors.white),
      labelMedium: TextStyle(color: Colors.white),
      labelSmall: TextStyle(color: Colors.white70),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(color: Colors.black),
      actionTextColor: Colors.black,
    ),
  );

  // Helper methods for getting theme-appropriate colors
  // In dark mode, use only black/white with varying opacity for distinction
  // In light mode, keep the original colors
  Color getProteinColor(BuildContext context) {
    return _isDarkMode ? Colors.white : Colors.red[400]!;
  }

  Color getCarbsColor(BuildContext context) {
    return _isDarkMode ? Colors.white.withOpacity(0.7) : Colors.blue[400]!;
  }

  Color getFatsColor(BuildContext context) {
    return _isDarkMode ? Colors.white.withOpacity(0.5) : Colors.green[400]!;
  }

  Color getCaloriesColor(BuildContext context) {
    return _isDarkMode ? Colors.white.withOpacity(0.85) : Colors.orange[600]!;
  }

  Color getAccentColor(BuildContext context) {
    return _isDarkMode ? Colors.white : Colors.blue[500]!;
  }

  Color getErrorColor(BuildContext context) {
    return _isDarkMode ? Colors.white : Colors.red[600]!;
  }

  Color getSuccessColor(BuildContext context) {
    return _isDarkMode ? Colors.white : Colors.green;
  }

  Color getCardBackgroundColor(BuildContext context) {
    return _isDarkMode ? Colors.black : Colors.orange[50]!;
  }

  Color getCardBorderColor(BuildContext context) {
    return _isDarkMode ? Colors.white24 : Colors.orange[200]!;
  }

  Color getButtonBackgroundColor(BuildContext context) {
    return _isDarkMode ? Colors.black : Colors.blue[50]!;
  }

  // Chart colors (single-color "gradients" for clarity)
  List<Color> getProteinGradient(BuildContext context) {
    return _isDarkMode
        ? [Colors.white, Colors.white]
        : [Colors.red[300]!, Colors.red[600]!];
  }

  List<Color> getCarbsGradient(BuildContext context) {
    return _isDarkMode
        ? [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.7)]
        : [Colors.blue[300]!, Colors.blue[600]!];
  }

  List<Color> getFatsGradient(BuildContext context) {
    return _isDarkMode
        ? [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.5)]
        : [Colors.green[300]!, Colors.green[600]!];
  }

  List<Color> getCaloriesGradient(BuildContext context) {
    return _isDarkMode
        ? [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.85)]
        : [Colors.orange[300]!, Colors.orange[600]!];
  }
}
