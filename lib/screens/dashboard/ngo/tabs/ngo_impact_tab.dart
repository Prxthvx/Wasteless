import 'package:flutter/material.dart';


class NgoImpactTab extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const NgoImpactTab({
    super.key,
    required this.analytics,
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

          const _ImpactChartSection(),
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
  const _ImpactChartSection();

  @override
  Widget build(BuildContext context) {
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
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '📊 Impact chart would go here\n(Integration with charts library)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
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
