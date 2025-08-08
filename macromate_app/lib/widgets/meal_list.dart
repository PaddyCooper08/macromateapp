import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/macro_entry.dart';
import '../providers/macro_provider.dart';
import '../providers/theme_provider.dart';

class MealList extends StatelessWidget {
  final List<MacroEntry> meals;

  const MealList({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No meals logged today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first meal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = meals.toList().reversed.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final meal = items[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            index == 0 ? 0 : 8,
            16,
            index == items.length - 1 ? 16 : 8,
          ),
          child: MealCard(meal: meal),
        );
      }, childCount: items.length),
    );
  }
}

class MealCard extends StatelessWidget {
  final MacroEntry meal;

  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('HH:mm');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with food name and time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.foodItem,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeFormatter.format(meal.mealTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _addToFavorites(context),
                      icon: Icon(
                        Icons.favorite_border,
                        color: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getAccentColor(context),
                      ),
                      tooltip: 'Add to Favorites',
                      style: IconButton.styleFrom(
                        backgroundColor: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getButtonBackgroundColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteMeal(context),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getErrorColor(context),
                      ),
                      tooltip: 'Delete',
                      style: IconButton.styleFrom(
                        backgroundColor: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getButtonBackgroundColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Macros row
            Row(
              children: [
                Expanded(
                  child: _MacroChip(
                    label: 'Protein',
                    value: meal.protein,
                    unit: 'g',
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getProteinColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroChip(
                    label: 'Carbs',
                    value: meal.carbs,
                    unit: 'g',
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getCarbsColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroChip(
                    label: 'Fats',
                    value: meal.fats,
                    unit: 'g',
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getFatsColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Calories
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).getCardBackgroundColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).getCardBorderColor(context),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getCaloriesColor(context),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${meal.calories.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      color: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getCaloriesColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToFavorites(BuildContext context) async {
    final macroProvider = Provider.of<MacroProvider>(context, listen: false);
    final success = await macroProvider.addToFavorites(meal);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Added to favorites!' : 'Failed to add to favorites',
          ),
          backgroundColor: success
              ? Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).getSuccessColor(context)
              : Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).getErrorColor(context),
        ),
      );
    }
  }

  Future<void> _deleteMeal(BuildContext context) async {
    if (meal.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal.foodItem}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).getErrorColor(context),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final macroProvider = Provider.of<MacroProvider>(context, listen: false);
      final success = await macroProvider.deleteMacroEntry(meal.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Meal deleted' : 'Failed to delete meal'),
            backgroundColor: success
                ? Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).getSuccessColor(context)
                : Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).getErrorColor(context),
          ),
        );
      }
    }
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
