import 'package:flutter/material.dart';
import '../../../view_model/restaurant_dashboard_view_model.dart';

class CategoryBreakdown extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;

  const CategoryBreakdown({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final categories = viewModel.inventory.fold<Map<String, int>>(
      {},
      (map, item) {
        map[item.category] = (map[item.category] ?? 0) + 1;
        return map;
      },
    );

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
                Icon(Icons.pie_chart, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Inventory by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (categories.isEmpty)
              const Text(
                'No inventory data available',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...categories.entries.map(
                (entry) => _CategoryItem(
                  category: entry.key,
                  count: entry.value,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String category;
  final int count;

  const _CategoryItem({
    required this.category,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
