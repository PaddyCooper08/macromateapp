class FavoriteFood {
  final String id;
  final String foodItem;
  final double protein;
  final double carbs;
  final double fats;
  final double calories;
  final DateTime createdAt;

  FavoriteFood({
    required this.id,
    required this.foodItem,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.calories,
    required this.createdAt,
  });

  factory FavoriteFood.fromJson(Map<String, dynamic> json) {
    return FavoriteFood(
      id: json['id'] as String? ?? '',
      foodItem: json['foodItem'] as String? ?? '',
      protein: (json['protein'] ?? 0.0).toDouble(),
      carbs: (json['carbs'] ?? 0.0).toDouble(),
      fats: (json['fats'] ?? 0.0).toDouble(),
      calories: (json['calories'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodItem': foodItem,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'calories': calories,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
