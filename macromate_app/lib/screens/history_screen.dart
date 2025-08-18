import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/daily_summary.dart';
import '../providers/macro_provider.dart';
import '../providers/theme_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MacroProvider>(
        context,
        listen: false,
      ).loadPastSummaries(_selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MacroProvider>(
      builder: (context, macroProvider, child) {
        return Column(
          children: [
            // Days selector
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'View past:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(value: 7, label: Text('7 days')),
                        ButtonSegment<int>(value: 14, label: Text('14 days')),
                        ButtonSegment<int>(value: 30, label: Text('30 days')),
                      ],
                      selected: {_selectedDays},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _selectedDays = newSelection.first;
                        });
                        macroProvider.loadPastSummaries(_selectedDays);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(child: _buildContent(macroProvider)),
          ],
        );
      },
    );
  }

  Widget _buildContent(MacroProvider macroProvider) {
    if (macroProvider.isLoading && macroProvider.pastSummaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (macroProvider.pastSummaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No history data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging meals to see your history',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => macroProvider.loadPastSummaries(_selectedDays),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Charts
            _buildChartsSection(macroProvider.pastSummaries),
            const SizedBox(height: 24),

            // Daily summaries list
            _buildDailySummariesSection(macroProvider.pastSummaries),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(List<DailySummary> summaries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trends',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Calories chart
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Calories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(_buildCaloriesChartData(summaries)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Macros chart
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Macronutrients',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(_buildMacrosChartData(summaries)),
                ),
                const SizedBox(height: 16),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(
                      'Protein',
                      Provider.of<ThemeProvider>(
                        context,
                      ).getProteinColor(context),
                    ),
                    _buildLegendItem(
                      'Carbs',
                      Provider.of<ThemeProvider>(
                        context,
                      ).getCarbsColor(context),
                    ),
                    _buildLegendItem(
                      'Fats',
                      Provider.of<ThemeProvider>(context).getFatsColor(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDailySummariesSection(List<DailySummary> summaries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Breakdown',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final summary = summaries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _openDayDetails(summary),
                child: DailySummaryCard(summary: summary),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openDayDetails(DailySummary summary) async {
    final macroProvider = Provider.of<MacroProvider>(context, listen: false);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Load meals for the selected day
    await macroProvider.loadDayMacros(summary.date);

    if (!mounted) return;

    // Show bottom sheet with details
    // ignore: use_build_context_synchronously
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Consumer<MacroProvider>(
              builder: (context, provider, _) {
                final meals = provider.selectedDayMeals;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat(
                                'EEEE, MMM d',
                              ).format(DateTime.parse(summary.date)),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: cs.onBackground,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Totals row
                      Row(
                        children: [
                          _TotalPill(
                            label: 'Protein',
                            value: provider.selectedDayProtein,
                            unit: 'g',
                          ),
                          const SizedBox(width: 8),
                          _TotalPill(
                            label: 'Carbs',
                            value: provider.selectedDayCarbs,
                            unit: 'g',
                          ),
                          const SizedBox(width: 8),
                          _TotalPill(
                            label: 'Fats',
                            value: provider.selectedDayFats,
                            unit: 'g',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
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
                              '${provider.selectedDayCalories.toStringAsFixed(0)} kcal',
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
                      if (meals.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 48,
                                  color: cs.onBackground.withOpacity(0.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No meals logged for this day',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onBackground.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: controller,
                            itemCount: meals.length,
                            itemBuilder: (context, index) {
                              final meal = meals[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.foodItem,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat(
                                              'h:mm a',
                                            ).format(meal.mealTime.toLocal()),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: cs.onBackground
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${meal.calories.toStringAsFixed(0)} kcal',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'P ${meal.protein.toStringAsFixed(0)}g  C ${meal.carbs.toStringAsFixed(0)}g  F ${meal.fats.toStringAsFixed(0)}g',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        IconButton(
                                          tooltip: 'Add to Today',
                                          icon: Icon(
                                            Icons.add_circle_outline,
                                            color: Provider.of<ThemeProvider>(
                                              context,
                                              listen: false,
                                            ).getAccentColor(context),
                                          ),
                                          onPressed: () async {
                                            final macroProvider =
                                                Provider.of<MacroProvider>(
                                                  context,
                                                  listen: false,
                                                );
                                            final ok = await macroProvider
                                                .relogMeal(meal);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    ok
                                                        ? 'Added to today'
                                                        : 'Failed: ${macroProvider.error}',
                                                  ),
                                                  backgroundColor: ok
                                                      ? Provider.of<
                                                              ThemeProvider
                                                            >(
                                                              context,
                                                              listen: false,
                                                            )
                                                            .getSuccessColor(
                                                              context,
                                                            )
                                                      : Provider.of<
                                                              ThemeProvider
                                                            >(
                                                              context,
                                                              listen: false,
                                                            )
                                                            .getErrorColor(
                                                              context,
                                                            ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    macroProvider.clearSelectedDay();
  }

  LineChartData _buildCaloriesChartData(List<DailySummary> summaries) {
    final spots = summaries.asMap().entries.map((entry) {
      final index = entry.key;
      final summary = entry.value;
      return FlSpot(index.toDouble(), summary.totalCalories);
    }).toList();
    final interval = _calculateInterval(summaries.length);
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: interval,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: _calculateYAxisInterval(spots),
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: interval,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < summaries.length) {
                final date = DateTime.parse(summaries[value.toInt()].date);
                return Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).getCaloriesGradient(context),
          ),
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4,
                  color: Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).getCaloriesColor(context),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
          ),
        ),
      ],
    );
  }

  LineChartData _buildMacrosChartData(List<DailySummary> summaries) {
    final proteinSpots = summaries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.totalProtein))
        .toList();
    final carbsSpots = summaries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.totalCarbs))
        .toList();
    final fatsSpots = summaries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.totalFats))
        .toList();
    final interval = _calculateInterval(summaries.length);
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: interval,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: _calculateMacroYAxisInterval([
              proteinSpots,
              carbsSpots,
              fatsSpots,
            ]),
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: interval,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < summaries.length) {
                final date = DateTime.parse(summaries[value.toInt()].date);
                return Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: proteinSpots,
          isCurved: true,
          gradient: LinearGradient(
            colors: Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).getProteinGradient(context),
          ),
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: carbsSpots,
          isCurved: true,
          gradient: LinearGradient(
            colors: Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).getCarbsGradient(context),
          ),
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: fatsSpots,
          isCurved: true,
          gradient: LinearGradient(
            colors: Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).getFatsGradient(context),
          ),
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  double _calculateInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 14) return 2;
    if (dataLength <= 30) return 5;
    return (dataLength / 6).ceil().toDouble();
  }

  double? _calculateYAxisInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return null;
    final maxValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minValue = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    if (range <= 100) return 20;
    if (range <= 500) return 50;
    if (range <= 1000) return 100;
    return (range / 5).ceil().toDouble();
  }

  double? _calculateMacroYAxisInterval(List<List<FlSpot>> allSpots) {
    if (allSpots.isEmpty) return null;
    final values = allSpots.expand((l) => l.map((s) => s.y)).toList();
    if (values.isEmpty) return null;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 200) return 25;
    return (range / 5).ceil().toDouble();
  }
}

class DailySummaryCard extends StatelessWidget {
  final DailySummary summary;

  const DailySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(summary.date);
    final formatter = DateFormat('EEEE, MMM d');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatter.format(date),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Macros row
            Row(
              children: [
                Expanded(
                  child: _MacroChip(
                    label: 'Protein',
                    value: summary.totalProtein,
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
                    value: summary.totalCarbs,
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
                    value: summary.totalFats,
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
                    '${summary.totalCalories.toStringAsFixed(0)} kcal',
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

class _TotalPill extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  const _TotalPill({
    required this.label,
    required this.value,
    required this.unit,
  });
  @override
  Widget build(BuildContext context) {
    final color = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).getAccentColor(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
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
      ),
    );
  }
}
