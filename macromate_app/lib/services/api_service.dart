import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/macro_entry.dart';
import '../models/favorite_food.dart';
import '../models/daily_summary.dart';

class ApiService {
  // Production server URL - Google Cloud Run
  static const String baseUrl =
      'https://macromate-server-290899070829.europe-west1.run.app';
  // Development URLs (uncomment for local development):
  // static const String baseUrl = 'http://10.0.2.2:3000'; // For Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // For iOS simulator
  // static const String baseUrl = 'http://YOUR_IP_ADDRESS:3000'; // For physical device

  static Future<Map<String, dynamic>> _makeRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {'Content-Type': 'application/json', ...?headers};

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: defaultHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Health check
  static Future<bool> checkConnection() async {
    try {
      final response = await _makeRequest('/health', 'GET');
      return response['status'] == 'OK';
    } catch (e) {
      return false;
    }
  }

  // Calculate macros from food description
  static Future<MacroEntry> calculateMacros(
    String userId,
    String foodDescription,
  ) async {
    final response = await _makeRequest(
      '/api/calculate-macros',
      'POST',
      body: {'userId': userId, 'foodDescription': foodDescription},
    );

    if (response['success'] == true) {
      return MacroEntry.fromJson(response['data']);
    } else {
      throw Exception(response['error'] ?? 'Failed to calculate macros');
    }
  }

  // Calculate macros from image
  static Future<MacroEntry> calculateImageMacros(
    String userId,
    Uint8List imageBytes,
    String? weight,
  ) async {
    final uri = Uri.parse('$baseUrl/api/calculate-image-macros');

    var request = http.MultipartRequest('POST', uri);
    request.fields['userId'] = userId;
    if (weight != null && weight.isNotEmpty) {
      request.fields['weight'] = weight;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'nutrition_label.jpg',
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        return MacroEntry.fromJson(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Failed to process image');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Calculate macros from barcode
  static Future<MacroEntry> calculateBarcodeMacros(
    String userId,
    String barcode,
    String? weight,
  ) async {
    final response = await _makeRequest(
      '/api/barcode-macros',
      'POST',
      body: {
        'userId': userId,
        'barcode': barcode,
        if (weight != null && weight.isNotEmpty) 'weight': weight,
      },
    );

    if (response['success'] == true) {
      return MacroEntry.fromJson(response['data']);
    } else {
      throw Exception(
        response['error'] ?? 'Failed to calculate barcode macros',
      );
    }
  }

  // Get today's macros
  static Future<Map<String, dynamic>> getTodayMacros(String userId) async {
    final response = await _makeRequest('/api/today-macros/$userId', 'GET');

    if (response['success'] == true) {
      final data = response['data'];
      final totalMacros = data['totalMacros'] ?? {};
      return {
        'totalProtein': (totalMacros['protein'] ?? 0.0).toDouble(),
        'totalCarbs': (totalMacros['carbs'] ?? 0.0).toDouble(),
        'totalFats': (totalMacros['fats'] ?? 0.0).toDouble(),
        'totalCalories': (totalMacros['calories'] ?? 0.0).toDouble(),
        'meals': (data['meals'] as List<dynamic>)
            .map((meal) => MacroEntry.fromJson(meal))
            .toList(),
      };
    } else {
      throw Exception(response['error'] ?? 'Failed to get today\'s macros');
    }
  }

  // Get past macros
  static Future<List<DailySummary>> getPastMacros(
    String userId, [
    int days = 7,
  ]) async {
    final response = await _makeRequest(
      '/api/past-macros/$userId/$days',
      'GET',
    );

    if (response['success'] == true) {
      final data = response['data'];
      final dailySummaries = data['dailySummaries'] as List<dynamic>;
      return dailySummaries.map((item) => DailySummary.fromJson(item)).toList();
    } else {
      throw Exception(response['error'] ?? 'Failed to get past macros');
    }
  }

  // Get macros for a specific day (YYYY-MM-DD)
  static Future<Map<String, dynamic>> getDayMacros(
    String userId,
    String date,
  ) async {
    final response = await _makeRequest('/api/day-macros/$userId/$date', 'GET');

    if (response['success'] == true) {
      final data = response['data'];
      final totalMacros = data['totalMacros'] ?? {};
      return {
        'date': data['date'] as String,
        'totalProtein': (totalMacros['protein'] ?? 0.0).toDouble(),
        'totalCarbs': (totalMacros['carbs'] ?? 0.0).toDouble(),
        'totalFats': (totalMacros['fats'] ?? 0.0).toDouble(),
        'totalCalories': (totalMacros['calories'] ?? 0.0).toDouble(),
        'meals': (data['meals'] as List<dynamic>)
            .map((meal) => MacroEntry.fromJson(meal))
            .toList(),
      };
    } else {
      throw Exception(response['error'] ?? 'Failed to get day\'s macros');
    }
  }

  // Delete macro log entry
  static Future<void> deleteMacroLog(String logId, String userId) async {
    final response = await _makeRequest(
      '/api/macro-log/$logId?userId=$userId',
      'DELETE',
    );

    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Failed to delete macro log');
    }
  }

  // Get favorite foods
  static Future<List<FavoriteFood>> getFavorites(String userId) async {
    final response = await _makeRequest('/api/favorites/$userId', 'GET');

    if (response['success'] == true) {
      final data = response['data'];
      final favorites = data['favorites'] as List<dynamic>;
      return favorites.map((item) => FavoriteFood.fromJson(item)).toList();
    } else {
      throw Exception(response['error'] ?? 'Failed to get favorites');
    }
  }

  // Add food to favorites
  static Future<FavoriteFood> addToFavorites(
    String userId,
    MacroEntry macroEntry,
  ) async {
    final response = await _makeRequest(
      '/api/favorites/$userId',
      'POST',
      body: {
        'foodItem': macroEntry.foodItem,
        'protein': macroEntry.protein,
        'carbs': macroEntry.carbs,
        'fats': macroEntry.fats,
        'calories': macroEntry.calories,
      },
    );

    if (response['success'] == true) {
      return FavoriteFood.fromJson(response['data']);
    } else {
      throw Exception(response['error'] ?? 'Failed to add to favorites');
    }
  }

  // Add favorite to today's meals
  static Future<MacroEntry> addFavoriteToMeals(
    String userId,
    String favoriteId,
  ) async {
    final response = await _makeRequest(
      '/api/favorites/$userId/add-to-meals',
      'POST',
      body: {'favoriteId': favoriteId},
    );

    if (response['success'] == true) {
      return MacroEntry.fromJson(response['data']);
    } else {
      throw Exception(response['error'] ?? 'Failed to add favorite to meals');
    }
  }

  // Delete favorite
  static Future<void> deleteFavorite(String userId, String favoriteId) async {
    final response = await _makeRequest(
      '/api/favorites/$userId/$favoriteId',
      'DELETE',
    );

    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Failed to delete favorite');
    }
  }

  // Edit favorite name
  static Future<FavoriteFood> editFavorite(
    String userId,
    String favoriteId,
    String newName,
  ) async {
    final response = await _makeRequest(
      '/api/favorites/$userId/$favoriteId',
      'PUT',
      body: {'foodItem': newName},
    );

    if (response['success'] == true) {
      return FavoriteFood.fromJson(response['data']);
    } else {
      throw Exception(response['error'] ?? 'Failed to edit favorite');
    }
  }

  // Link/migrate Telegram data to Supabase user
  static Future<bool> migrateTelegramToSupabase({
    required String telegramId,
    required String supabaseUserId,
  }) async {
    final response = await _makeRequest(
      '/api/migrate-user',
      'POST',
      body: {'telegramId': telegramId, 'supabaseUserId': supabaseUserId},
    );

    if (response['success'] == true) {
      return true;
    } else {
      throw Exception(response['error'] ?? 'Migration failed');
    }
  }

  // Re-log a past macro entry into today
  static Future<MacroEntry> relogMacro(String userId, MacroEntry entry) async {
    final response = await _makeRequest(
      '/api/relog-macro',
      'POST',
      body: {
        'userId': userId,
        'foodItem': entry.foodItem,
        'protein': entry.protein,
        'carbs': entry.carbs,
        'fats': entry.fats,
        'calories': entry.calories,
      },
    );
    if (response['success'] == true) {
      return MacroEntry.fromJson(response['data']);
    } else {
      throw Exception(response['error'] ?? 'Failed to re-log meal');
    }
  }
}
