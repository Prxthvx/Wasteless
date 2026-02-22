import 'package:flutter/material.dart';
import '../../../view_model/restaurant_dashboard_view_model.dart';

class WasteReductionChart extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;
  const WasteReductionChart({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Calculate expiring items per month
    final now = DateTime.now();
    final Map<int, int> monthCounts = {};
    for (var item in viewModel.inventory) {
      final month = item.expiryDate.month;
      monthCounts[month] = (monthCounts[month] ?? 0) + 1;
    }
    final months = List.generate(12, (i) => i + 1);

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
                Icon(Icons.trending_up, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Expiring Items Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: months.map((m) {
                final count = monthCounts[m] ?? 0;
                final label = _monthLabel(m);
                return _ChartBar(label: label, value: count);
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This chart shows the number of food items expiring each month.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
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

  String _monthLabel(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final int value;

  const _ChartBar({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: value == 0 ? 8 : (value * 12).toDouble(),
          width: 20,
          decoration: BoxDecoration(
            color: value == 0 ? Colors.grey[300] : Colors.green,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
