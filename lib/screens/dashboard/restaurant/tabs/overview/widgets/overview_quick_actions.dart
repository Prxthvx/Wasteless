import 'package:flutter/material.dart';

class OverviewQuickActions extends StatelessWidget {
  final VoidCallback onAddItem;
  final VoidCallback onViewDonations;
  final VoidCallback onGenerateRecipes;
  final VoidCallback onViewAnalytics;

  const OverviewQuickActions({
    super.key,
    required this.onAddItem,
    required this.onViewDonations,
    required this.onGenerateRecipes,
    required this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Add Item',
                    icon: Icons.add,
                    color: Colors.green,
                    onTap: onAddItem,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'View Donations',
                    icon: Icons.favorite,
                    color: Colors.red,
                    onTap: onViewDonations,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Generate Recipes',
                    icon: Icons.restaurant_menu,
                    color: Colors.orange,
                    onTap: onGenerateRecipes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'View Analytics',
                    icon: Icons.analytics,
                    color: Colors.purple,
                    onTap: onViewAnalytics,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
