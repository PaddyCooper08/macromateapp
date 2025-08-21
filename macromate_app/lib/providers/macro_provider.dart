import 'package:flutter/material.dart';
import '../models/macro_entry.dart';
import '../models/favorite_food.dart';
import '../models/daily_summary.dart';
import '../services/api_service.dart';
import '../services/user_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gemini_usage_service.dart';
import '../services/rewarded_ad_service.dart';

class MacroProvider with ChangeNotifier {
  // Gemini usage/ad gating
  int _geminiUses = 0;
  bool _adFree = false;
  final RewardedAdService rewardedAdService = RewardedAdService();

  int get geminiUses => _geminiUses;
  bool get adFree => _adFree;
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

  // Transient state for selected day details
  List<MacroEntry> _selectedDayMeals = [];
  double _selectedDayProtein = 0.0;
  double _selectedDayCarbs = 0.0;
  double _selectedDayFats = 0.0;
  double _selectedDayCalories = 0.0;

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

  List<MacroEntry> get selectedDayMeals => _selectedDayMeals;
  double get selectedDayProtein => _selectedDayProtein;
  double get selectedDayCarbs => _selectedDayCarbs;
  double get selectedDayFats => _selectedDayFats;
  double get selectedDayCalories => _selectedDayCalories;

  bool get isLoggedIn => _userId != null;

  bool get _supabaseReady {
    try {
      // Accessing instance throws if not initialized
      // ignore: unnecessary_statements
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Initialize the provider
  Future<void> initialize() async {
    _userId = await UserStorageService.getUserId();

    // Load Gemini usage/ad-free state
    _geminiUses = await GeminiUsageService.getGeminiUses();
    _adFree = await GeminiUsageService.isAdFree();

    // If not found in local storage, try Supabase session only if initialized
    if (_userId == null && _supabaseReady) {
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null) {
        _userId = supabaseUser.id;
        await UserStorageService.saveUserId(_userId!, source: 'supabase');
      }
    }

    if (_userId != null) {
      await loadTodaysMacros();
      await loadFavorites();
      await loadPastSummaries();
    }
    notifyListeners();
  }

  // Gemini usage logic
  Future<bool> canUseGemini() async {
    if (_adFree) return true;
    if (_geminiUses < 3) return true; // Changed to 3 for testing
    return false;
  }

  Future<void> incrementGeminiUses({int increment = 1}) async {
    _geminiUses += increment;
    await GeminiUsageService.setGeminiUses(_geminiUses);
    notifyListeners();
  }

  Future<void> resetGeminiUses() async {
    _geminiUses = 0;
    await GeminiUsageService.resetGeminiUses();
    notifyListeners();
  }

  Future<void> setAdFree(bool value) async {
    _adFree = value;
    await GeminiUsageService.setAdFree(value);
    notifyListeners();
  }

  void loadRewardedAd(VoidCallback? onLoaded, {VoidCallback? onFailed}) {
    rewardedAdService.loadAd(onLoaded, onFailed: onFailed);
  }

  // For testing: simulate ad reward when real ads fail
  void simulateAdReward() {
    incrementGeminiUses(increment: 10);
  }

  void showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onClosed,
    VoidCallback? onFailed,
  }) {
    rewardedAdService.showAd(
      onRewarded: onRewarded,
      onClosed: onClosed,
      onFailed: onFailed,
    );
  }

  bool get isRewardedAdLoaded => rewardedAdService.isLoaded;

  // Login with user ID (Telegram numeric or Supabase UUID)
  Future<bool> login(String userId, {String? source}) async {
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

      // Save user ID (can be Telegram ID or Supabase auth user.id)
      await UserStorageService.saveUserId(userId, source: source);
      _userId = userId;

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
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
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
  Future<bool> addMacroEntry(
    String foodDescription, {
    String? customName,
  }) async {
    if (_userId == null) return false;

    // Check if user can use Gemini before making the API call
    if (!await canUseGemini()) {
      _setError('Gemini usage limit reached. Watch an ad to get more uses.');
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      var macroEntry = await ApiService.calculateMacros(
        _userId!,
        foodDescription,
      );
      // Apply custom name if provided
      if (customName != null && customName.trim().isNotEmpty) {
        macroEntry = macroEntry.copyWith(foodItem: customName.trim());
      }
      // Gemini usage: increment count after successful API call
      await incrementGeminiUses();
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
    String? weight, {
    String? customName,
  }) async {
    if (_userId == null) return false;

    // Check if user can use Gemini before making the API call
    if (!await canUseGemini()) {
      _setError('Gemini usage limit reached. Watch an ad to get more uses.');
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      var macroEntry = await ApiService.calculateImageMacros(
        _userId!,
        imageBytes as dynamic,
        weight,
      );
      // Apply custom name if provided
      if (customName != null && customName.trim().isNotEmpty) {
        macroEntry = macroEntry.copyWith(foodItem: customName.trim());
      }
      // Gemini usage: increment count after successful API call
      await incrementGeminiUses();
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

  // Add macro entry from barcode
  Future<bool> addMacroEntryFromBarcode(
    String barcode,
    String? weight, {
    String? customName,
  }) async {
    if (_userId == null) return false;
    try {
      _setLoading(true);
      _setError(null);

      var macroEntry = await ApiService.calculateBarcodeMacros(
        _userId!,
        barcode,
        weight,
      );
      // Apply custom name if provided
      if (customName != null && customName.trim().isNotEmpty) {
        macroEntry = macroEntry.copyWith(foodItem: customName.trim());
      }
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

  // Rename an existing meal entry in today's list
  Future<bool> renameMacroEntry(String entryId, String newName) async {
    if (_userId == null) return false;
    try {
      _setLoading(true);
      _setError(null);

      final updated = await ApiService.editMacroLogName(
        _userId!,
        entryId,
        newName,
      );

      final idx = _todaysMeals.indexWhere((e) => e.id == entryId);
      if (idx != -1) {
        _todaysMeals[idx] = updated;
      }
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

  // Edit favorite name
  Future<bool> editFavorite(String favoriteId, String newName) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      final updatedFavorite = await ApiService.editFavorite(
        _userId!,
        favoriteId,
        newName,
      );

      final index = _favorites.indexWhere((fav) => fav.id == favoriteId);
      if (index != -1) {
        _favorites[index] = updatedFavorite;
      }

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

  // Load macros for an arbitrary date (YYYY-MM-DD)
  Future<bool> loadDayMacros(String date) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      final data = await ApiService.getDayMacros(_userId!, date);

      _selectedDayMeals = data['meals'] as List<MacroEntry>;
      _selectedDayProtein = data['totalProtein'] as double;
      _selectedDayCarbs = data['totalCarbs'] as double;
      _selectedDayFats = data['totalFats'] as double;
      _selectedDayCalories = data['totalCalories'] as double;

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

  void clearSelectedDay() {
    _selectedDayMeals = [];
    _selectedDayProtein = 0.0;
    _selectedDayCarbs = 0.0;
    _selectedDayFats = 0.0;
    _selectedDayCalories = 0.0;
    notifyListeners();
  }

  // Relog a meal from a past day
  Future<bool> relogMeal(MacroEntry entry) async {
    if (_userId == null) return false;
    try {
      _setLoading(true);
      _setError(null);
      final newEntry = await ApiService.relogMacro(_userId!, entry);
      _todaysMeals.add(newEntry);
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
