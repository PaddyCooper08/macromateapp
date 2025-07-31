import 'package:flutter/material.dart';
import '../models/macro_entry.dart';
import '../models/favorite_food.dart';
import '../models/daily_summary.dart';
import '../services/api_service.dart';
import '../services/user_storage_service.dart';

class MacroProvider with ChangeNotifier {
  String? _userId;
  List<MacroEntry> _todaysMeals = [];
  List<FavoriteFood> _favorites = [];
  List<DailySummary> _pastSummaries = [];
  bool _isLoading = false;
  String? _error;

  // Totals for today
  double _totalProtein = 0.0;
  double _totalCarbs = 0.0;
  double _totalFats = 0.0;
  double _totalCalories = 0.0;

  // Getters
  String? get userId => _userId;
  List<MacroEntry> get todaysMeals => _todaysMeals;
  List<FavoriteFood> get favorites => _favorites;
  List<DailySummary> get pastSummaries => _pastSummaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalProtein => _totalProtein;
  double get totalCarbs => _totalCarbs;
  double get totalFats => _totalFats;
  double get totalCalories => _totalCalories;

  bool get isLoggedIn => _userId != null;

  // Initialize the provider
  Future<void> initialize() async {
    _userId = await UserStorageService.getUserId();
    if (_userId != null) {
      await loadTodaysMacros();
      await loadFavorites();
      await loadPastSummaries();
    }
    notifyListeners();
  }

  // Login with Telegram ID
  Future<bool> login(String telegramId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Test connection first
      final connectionOk = await ApiService.checkConnection();
      if (!connectionOk) {
        throw Exception(
          'Cannot connect to server. Please check your internet connection.',
        );
      }

      // Save user ID
      await UserStorageService.saveUserId(telegramId);
      _userId = telegramId;

      // Load user data
      await loadTodaysMacros();
      await loadFavorites();
      await loadPastSummaries();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await UserStorageService.clearUserData();
    _userId = null;
    _todaysMeals.clear();
    _favorites.clear();
    _pastSummaries.clear();
    _totalProtein = 0.0;
    _totalCarbs = 0.0;
    _totalFats = 0.0;
    _totalCalories = 0.0;
    notifyListeners();
  }

  // Load today's macros
  Future<void> loadTodaysMacros() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final data = await ApiService.getTodayMacros(_userId!);

      _todaysMeals = data['meals'] as List<MacroEntry>;
      _totalProtein = data['totalProtein'] as double;
      _totalCarbs = data['totalCarbs'] as double;
      _totalFats = data['totalFats'] as double;
      _totalCalories = data['totalCalories'] as double;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }

  // Add macro entry from food description
  Future<bool> addMacroEntry(String foodDescription) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      final macroEntry = await ApiService.calculateMacros(
        _userId!,
        foodDescription,
      );
      _todaysMeals.add(macroEntry);
      _updateTotals();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Add macro entry from image
  Future<bool> addMacroEntryFromImage(
    List<int> imageBytes,
    String? weight,
  ) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      final macroEntry = await ApiService.calculateImageMacros(
        _userId!,
        imageBytes as dynamic,
        weight,
      );
      _todaysMeals.add(macroEntry);
      _updateTotals();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete macro entry
  Future<bool> deleteMacroEntry(String entryId) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      await ApiService.deleteMacroLog(entryId, _userId!);
      _todaysMeals.removeWhere((entry) => entry.id == entryId);
      _updateTotals();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Load favorites
  Future<void> loadFavorites() async {
    if (_userId == null) return;

    try {
      _setError(null);
      _favorites = await ApiService.getFavorites(_userId!);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
    }
  }

  // Add to favorites
  Future<bool> addToFavorites(MacroEntry macroEntry) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      final favorite = await ApiService.addToFavorites(_userId!, macroEntry);
      _favorites.insert(0, favorite);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Add favorite to today's meals
  Future<bool> addFavoriteToMeals(String favoriteId) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      final macroEntry = await ApiService.addFavoriteToMeals(
        _userId!,
        favoriteId,
      );
      _todaysMeals.add(macroEntry);
      _updateTotals();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete favorite
  Future<bool> deleteFavorite(String favoriteId) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      await ApiService.deleteFavorite(_userId!, favoriteId);
      _favorites.removeWhere((fav) => fav.id == favoriteId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Load past summaries
  Future<void> loadPastSummaries([int days = 7]) async {
    if (_userId == null) return;

    try {
      _setError(null);
      _pastSummaries = await ApiService.getPastMacros(_userId!, days);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String? error) {
    _error = error;
  }

  void _updateTotals() {
    _totalProtein = _todaysMeals.fold(0.0, (sum, entry) => sum + entry.protein);
    _totalCarbs = _todaysMeals.fold(0.0, (sum, entry) => sum + entry.carbs);
    _totalFats = _todaysMeals.fold(0.0, (sum, entry) => sum + entry.fats);
    _totalCalories = _todaysMeals.fold(
      0.0,
      (sum, entry) => sum + entry.calories,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
