import 'package:flutter/material.dart';

class OverviewWelcomeCard extends StatelessWidget {
  final String restaurantName;
  final int totalInventory;
  final int activeDonations;

  const OverviewWelcomeCard({
    super.key,
    required this.restaurantName,
    required this.totalInventory,
    required this.activeDonations,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.recycling, color: Colors.white, size: 32),
                SizedBox(width: 12),
              ],
            ),
            Text(
              'Welcome back, $restaurantName!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickStat(label: 'Total Items', value: '$totalInventory'),
                const SizedBox(width: 16),
                _QuickStat(label: 'Active Donations', value: '$activeDonations'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
