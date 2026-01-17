import 'package:flutter/material.dart';
import '../../../view_model/restaurant_dashboard_view_model.dart';
import 'impact_metric_item.dart';

class EnvironmentalImpactCard extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;

  const EnvironmentalImpactCard({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final totalWasteSaved = viewModel.analytics['totalWasteSaved'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: Colors.teal[600]),
                const SizedBox(width: 8),
                const Text(
                  'Environmental Impact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ImpactMetricItem(
                    title: 'CO₂ Saved',
                    value: '${(totalWasteSaved * 2.5).round()} kg',
                    icon: Icons.cloud,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ImpactMetricItem(
                    title: 'Water Saved',
                    value: '${(totalWasteSaved * 1000).round()} L',
                    icon: Icons.water_drop,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade50, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.teal[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You\'re making a difference!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                        Text(
                          'Your waste reduction efforts are helping the environment.',
                          style: TextStyle(
                            color: Colors.teal[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
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
