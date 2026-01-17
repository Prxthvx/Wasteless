import 'package:flutter/material.dart';
import '../../../../../../models/inventory_item.dart';
import '../../../../../../models/donation.dart';

class OverviewStatsGrid extends StatelessWidget {
  final List<InventoryItem> inventory;
  final List<Donation> donations;
  final void Function(int) onNavigate;

  const OverviewStatsGrid({
    super.key,
    required this.inventory,
    required this.donations,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final expiringSoon = inventory
        .where((i) => i.expiryDate.difference(DateTime.now()).inDays <= 2)
        .length;

    final activeDonations =
        donations.where((d) => d.status == 'available').length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _StatCard('Items Expiring Soon', '$expiringSoon', Icons.warning,
            Colors.orange, () => onNavigate(1)),
        _StatCard('Active Donations', '$activeDonations', Icons.favorite,
            Colors.red, () => onNavigate(2)),
        _StatCard('Total Inventory', '${inventory.length}', Icons.inventory,
            Colors.blue, () => onNavigate(1)),
        _StatCard('Total Donations', '${donations.length}',
            Icons.volunteer_activism, Colors.purple, () => onNavigate(2)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard(
      this.title, this.value, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color)),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
