import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/favorite_food.dart';
import '../providers/macro_provider.dart';
import '../providers/theme_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MacroProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MacroProvider>(
      builder: (context, macroProvider, child) {
        if (macroProvider.isLoading && macroProvider.favorites.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (macroProvider.favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorite foods yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add meals to favorites from the Today tab',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => macroProvider.loadFavorites(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: macroProvider.favorites.length,
            itemBuilder: (context, index) {
              final favorite = macroProvider.favorites[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FavoriteCard(favorite: favorite),
              );
            },
          ),
        );
      },
    );
  }
}

class FavoriteCard extends StatelessWidget {
  final FavoriteFood favorite;

  const FavoriteCard({super.key, required this.favorite});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.foodItem,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Provider.of<ThemeProvider>(
                              context,
                              listen: false,
                            ).getAccentColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Favorite',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Provider.of<ThemeProvider>(
                                    context,
                                    listen: false,
                                  ).getAccentColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                    value: favorite.protein,
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
                    value: favorite.carbs,
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
                    value: favorite.fats,
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
                    '${favorite.calories.toStringAsFixed(0)} kcal',
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
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addToToday(context),
                    icon: Icon(Icons.add_circle_outline, size: 20),
                    label: Text('Add to Today'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getButtonBackgroundColor(context),
                      foregroundColor: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getAccentColor(context),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).getCardBorderColor(context),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _editFavorite(context),
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getAccentColor(context),
                  ),
                  tooltip: 'Edit',
                  style: IconButton.styleFrom(
                    backgroundColor: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getButtonBackgroundColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getCardBorderColor(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteFavorite(context),
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
                      side: BorderSide(
                        color: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getCardBorderColor(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToToday(BuildContext context) async {
    final macroProvider = Provider.of<MacroProvider>(context, listen: false);
    final success = await macroProvider.addFavoriteToMeals(favorite.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Added to today\'s meals!' : 'Failed to add to meals',
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

  Future<void> _deleteFavorite(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Favorite'),
        content: Text(
          'Are you sure you want to delete "${favorite.foodItem}" from favorites?',
        ),
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
      final success = await macroProvider.deleteFavorite(favorite.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Favorite deleted' : 'Failed to delete favorite',
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
  }

  Future<void> _editFavorite(BuildContext context) async {
    final controller = TextEditingController(text: favorite.foodItem);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Favorite'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Food name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty && trimmed != favorite.foodItem) {
                Navigator.of(context).pop(trimmed);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && context.mounted) {
      final macroProvider = Provider.of<MacroProvider>(context, listen: false);
      final success = await macroProvider.editFavorite(favorite.id, newName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Favorite updated' : 'Failed to update favorite',
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
