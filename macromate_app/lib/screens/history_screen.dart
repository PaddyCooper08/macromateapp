import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/daily_summary.dart';
import '../providers/macro_provider.dart';

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
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No history data',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging meals to see your history',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
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
                    _buildLegendItem('Protein', Colors.red[400]!),
                    _buildLegendItem('Carbs', Colors.blue[400]!),
                    _buildLegendItem('Fats', Colors.green[400]!),
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
              child: DailySummaryCard(summary: summary),
            );
          },
        ),
      ],
    );
  }

  LineChartData _buildCaloriesChartData(List<DailySummary> summaries) {
    final spots = summaries.asMap().entries.map((entry) {
      final index = entry.key;
      final summary = entry.value;
      return FlSpot(index.toDouble(), summary.totalCalories);
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < summaries.length) {
                final date = DateTime.parse(summaries[value.toInt()].date);
                return Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(fontSize: 12),
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
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.orange[500],
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }

  LineChartData _buildMacrosChartData(List<DailySummary> summaries) {
    final proteinSpots = summaries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalProtein);
    }).toList();

    final carbsSpots = summaries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalCarbs);
    }).toList();

    final fatsSpots = summaries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalFats);
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < summaries.length) {
                final date = DateTime.parse(summaries[value.toInt()].date);
                return Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(fontSize: 12),
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
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: proteinSpots,
          isCurved: true,
          color: Colors.red[400],
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: carbsSpots,
          isCurved: true,
          color: Colors.blue[400],
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: fatsSpots,
          isCurved: true,
          color: Colors.green[400],
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
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
                    color: Colors.red[400]!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroChip(
                    label: 'Carbs',
                    value: summary.totalCarbs,
                    unit: 'g',
                    color: Colors.blue[400]!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroChip(
                    label: 'Fats',
                    value: summary.totalFats,
                    unit: 'g',
                    color: Colors.green[400]!,
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange[600],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.totalCalories.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      color: Colors.orange[800],
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
