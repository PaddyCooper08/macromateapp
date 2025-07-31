class DailySummary {
  final String date;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final double totalCalories;

  DailySummary({
    required this.date,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.totalCalories,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: json['date'] as String? ?? '',
      totalProtein: (json['totalProtein'] ?? 0.0).toDouble(),
      totalCarbs: (json['totalCarbs'] ?? 0.0).toDouble(),
      totalFats: (json['totalFats'] ?? 0.0).toDouble(),
      totalCalories: (json['totalCalories'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFats': totalFats,
      'totalCalories': totalCalories,
    };
  }
}
