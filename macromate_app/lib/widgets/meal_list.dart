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

    // Group meals by identical macro signature + food name
    final Map<String, _MealGroup> grouped = {};
    for (final m in meals) {
      final key =
          '${m.foodItem}|${m.protein}|${m.carbs}|${m.fats}|${m.calories}';
      grouped.putIfAbsent(key, () => _MealGroup(sample: m, entries: []));
      grouped[key]!.entries.add(m);
    }

    final groups = grouped.values.toList().reversed.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final group = groups[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            index == 0 ? 0 : 8,
            16,
            index == groups.length - 1 ? 16 : 8,
          ),
          child: _GroupedMealCard(group: group),
        );
      }, childCount: groups.length),
    );
  }
}

class _MealGroup {
  final MacroEntry sample;
  final List<MacroEntry> entries;
  _MealGroup({required this.sample, required this.entries});
  int get count => entries.length;
  double get proteinTotal => sample.protein * count;
  double get carbsTotal => sample.carbs * count;
  double get fatsTotal => sample.fats * count;
  double get caloriesTotal => sample.calories * count;
}

class _GroupedMealCard extends StatelessWidget {
  final _MealGroup group;
  const _GroupedMealCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormatter = DateFormat('HH:mm');
    final firstTime = group.entries.first.mealTime;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.sample.foodItem,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'First: ${timeFormatter.format(firstTime)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(
                            0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _QuantityAdjust(group: group),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MacroChip(
                    label: 'Protein',
                    value: group.proteinTotal,
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
                    value: group.carbsTotal,
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
                    value: group.fatsTotal,
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
                    '${group.caloriesTotal.toStringAsFixed(0)} kcal',
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
}

class _QuantityAdjust extends StatelessWidget {
  final _MealGroup group;
  const _QuantityAdjust({required this.group});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MacroProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Rename',
          onPressed: group.entries.isNotEmpty && group.entries.first.id != null
              ? () async {
                  final id = group.entries.first.id!;
                  final controller = TextEditingController(
                    text: group.sample.foodItem,
                  );
                  final newName = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Rename Meal'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(ctx).pop(controller.text.trim()),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                  if (newName != null && newName.isNotEmpty) {
                    final ok = await provider.renameMacroEntry(id, newName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Meal renamed'
                                : 'Rename failed: ${provider.error}',
                          ),
                          backgroundColor: ok
                              ? themeProvider.getSuccessColor(context)
                              : themeProvider.getErrorColor(context),
                        ),
                      );
                    }
                  }
                }
              : null,
          icon: Icon(Icons.edit, color: themeProvider.getAccentColor(context)),
        ),
        IconButton(
          tooltip: 'Decrease',
          onPressed: group.count > 1
              ? () async {
                  // Delete one matching entry (choose last for determinism)
                  final entry = group.entries.last;
                  if (entry.id != null) {
                    await provider.deleteMacroEntry(entry.id!);
                  }
                }
              : null,
          icon: Icon(
            Icons.remove,
            color: themeProvider.getAccentColor(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: themeProvider.getAccentColor(context).withOpacity(0.4),
            ),
          ),
          child: Text(
            'x${group.count}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: 'Increase',
          onPressed: () async {
            await provider.relogMeal(group.sample);
          },
          icon: Icon(Icons.add, color: themeProvider.getAccentColor(context)),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Add to Favorites',
          onPressed: () async {
            final ok = await provider.addToFavorites(group.sample);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Added to favorites' : 'Failed: ${provider.error}',
                  ),
                  backgroundColor: ok
                      ? themeProvider.getSuccessColor(context)
                      : themeProvider.getErrorColor(context),
                ),
              );
            }
          },
          icon: Icon(
            Icons.favorite_border,
            color: themeProvider.getAccentColor(context),
          ),
        ),
        IconButton(
          tooltip: 'Delete All',
          onPressed: () async {
            final confirmed =
                await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete meals?'),
                    content: Text(
                      'Are you sure you want to delete ${group.count} instance${group.count == 1 ? '' : 's'} of "${group.sample.foodItem}" from today? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            themeProvider.getErrorColor(context),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!confirmed) return;

            for (final e in List<MacroEntry>.from(group.entries)) {
              if (e.id != null) {
                await provider.deleteMacroEntry(e.id!);
              }
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Deleted ${group.count} item${group.count == 1 ? '' : 's'}',
                  ),
                  backgroundColor: themeProvider.getErrorColor(context),
                ),
              );
            }
          },
          icon: Icon(
            Icons.delete_outline,
            color: themeProvider.getErrorColor(context),
          ),
        ),
      ],
    );
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
