import 'package:flutter/material.dart';

class RecentActivityCard extends StatelessWidget {
  final int claimedDonationsCount;
  const RecentActivityCard({super.key, required this.claimedDonationsCount});

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.volunteer_activism, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Donation Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Number of NGOs who claimed food: 5\nNumber of items donations claimed: $claimedDonationsCount",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
