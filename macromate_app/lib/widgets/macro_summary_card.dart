import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MacroSummaryCard extends StatelessWidget {
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final double totalCalories;

  const MacroSummaryCard({
    super.key,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.totalCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Calories
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).getCardBackgroundColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).getCardBorderColor(context),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getCaloriesColor(context),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calories',
                        style: TextStyle(
                          color: Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).getCaloriesColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${totalCalories.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          color: Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).getCaloriesColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Macro Breakdown
            Column(
              children: [
                // Protein
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getButtonBackgroundColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getCardBorderColor(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getProteinColor(context),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protein',
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(
                                context,
                                listen: false,
                              ).getProteinColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${totalProtein.toStringAsFixed(1)} g',
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(
                                context,
                                listen: false,
                              ).getProteinColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Carbs
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getButtonBackgroundColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getCardBorderColor(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grain,
                        color: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getCarbsColor(context),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Carbs',
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(
                                context,
                                listen: false,
                              ).getCarbsColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${totalCarbs.toStringAsFixed(1)} g',
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(
                                context,
                                listen: false,
                              ).getCarbsColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Fats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getButtonBackgroundColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getCardBorderColor(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getFatsColor(context),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fats',
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(
                                context,
                                listen: false,
                              ).getFatsColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${totalFats.toStringAsFixed(1)} g',
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(
                                context,
                                listen: false,
                              ).getFatsColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
