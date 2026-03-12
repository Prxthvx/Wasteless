import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';


class NgoImpactTab extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final Map<String, int> monthlyClaimsData;

  const NgoImpactTab({
    super.key,
    required this.analytics,
    required this.monthlyClaimsData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthlyOverviewSection(analytics: analytics),
          const SizedBox(height: 16),

          _ImpactChartSection(monthlyClaimsData: monthlyClaimsData),
          const SizedBox(height: 16),

          const _TopCategoriesSection(),
          const SizedBox(height: 16),

          const _AchievementsSection(),
        ],
      ),
    );
  }
}

class _MonthlyOverviewSection extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const _MonthlyOverviewSection({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month\'s Impact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AnalyticCard(
                    title: 'Donations Claimed',
                    value: '${analytics['totalDonationsClaimed'] ?? 0}',
                    icon: Icons.favorite,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnalyticCard(
                    title: 'People Helped',
                    value: '${analytics['peopleHelped'] ?? 0}',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AnalyticCard(
                    title: 'Food Rescued',
                    value: '${analytics['foodRescued'] ?? 0} kg',
                    icon: Icons.recycling,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnalyticCard(
                    title: 'Restaurants',
                    value: '${analytics['restaurantsConnected'] ?? 0}',
                    icon: Icons.restaurant,
                    color: Colors.orange,
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

class _AnalyticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactChartSection extends StatelessWidget {
  final Map<String, int> monthlyClaimsData;

  const _ImpactChartSection({required this.monthlyClaimsData});

  @override
  Widget build(BuildContext context) {
    // Sort the data by month
    final sortedEntries = monthlyClaimsData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Prepare data for the chart
    final List<BarChartGroupData> barGroups = [];
    final List<String> monthLabels = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final count = entry.value;
      
      // Parse month from key (format: 'YYYY-MM')
      try {
        final parts = entry.key.split('-');
        if (parts.length == 2) {
          final month = int.parse(parts[1]);
          final monthName = DateFormat('MMM').format(DateTime(2000, month));
          monthLabels.add(monthName);
        } else {
          monthLabels.add(entry.key);
        }
      } catch (e) {
        monthLabels.add(entry.key);
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.blue,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Impact Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (monthlyClaimsData.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No data available yet.\nStart claiming donations to see your impact!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10, top: 16),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${monthLabels[group.x.toInt()]}\n${rod.toY.toInt()} donations',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < monthLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    monthLabels[index],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: RotatedBox(
                              quarterTurns: 4,
                              child: Text(
                                'Donations Claimed',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          axisNameSize: 55,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopCategoriesSection extends StatelessWidget {
  const _TopCategoriesSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Claimed Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _TopCategoryRow('Vegetables', 25, 'kg'),
            _TopCategoryRow('Bread & Pastries', 18, 'kg'),
            _TopCategoryRow('Fruits', 15, 'kg'),
            _TopCategoryRow('Dairy', 12, 'kg'),
          ],
        ),
      ),
    );
  }
}

class _TopCategoryRow extends StatelessWidget {
  final String name;
  final int amount;
  final String unit;

  const _TopCategoryRow(this.name, this.amount, this.unit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text('$amount $unit', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _AchievementRow(
              title: 'First Donation',
              description: 'Claimed your first donation',
              icon: Icons.star,
              color: Colors.amber,
            ),
            _AchievementRow(
              title: 'Helping Hand',
              description: 'Helped 50+ people',
              icon: Icons.people,
              color: Colors.blue,
            ),
            _AchievementRow(
              title: 'Waste Warrior',
              description: 'Rescued 100kg of food',
              icon: Icons.recycling,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _AchievementRow({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(description),
    );
  }
}
