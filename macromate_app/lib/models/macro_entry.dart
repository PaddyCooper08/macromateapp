class MacroEntry {
  final String? id;
  final String foodItem;
  final double protein;
  final double carbs;
  final double fats;
  final double calories;
  final DateTime mealTime;
  final String date;

  MacroEntry({
    this.id,
    required this.foodItem,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.calories,
    required this.mealTime,
    required this.date,
  });

  factory MacroEntry.fromJson(Map<String, dynamic> json) {
    return MacroEntry(
      id: json['id'] as String?,
      foodItem:
          json['foodItem'] as String? ?? json['food_item'] as String? ?? '',
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      mealTime: _parseDateTime(json['mealTime'] ?? json['meal_time']),
      date: _parseDate(json['date'] ?? json['log_date']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _parseDate(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String().split('T')[0];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return DateTime.now().toIso8601String().split('T')[0];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodItem': foodItem,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'calories': calories,
      'mealTime': mealTime.toIso8601String(),
      'date': date,
    };
  }

  MacroEntry copyWith({
    String? id,
    String? foodItem,
    double? protein,
    double? carbs,
    double? fats,
    double? calories,
    DateTime? mealTime,
    String? date,
  }) {
    return MacroEntry(
      id: id ?? this.id,
      foodItem: foodItem ?? this.foodItem,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      calories: calories ?? this.calories,
      mealTime: mealTime ?? this.mealTime,
      date: date ?? this.date,
    );
  }
}
