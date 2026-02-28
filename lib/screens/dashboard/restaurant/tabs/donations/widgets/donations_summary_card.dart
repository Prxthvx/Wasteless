import 'package:flutter/material.dart';
import '../../../../../../../models/donation.dart';

class DonationsSummaryCard extends StatelessWidget {
  final List<Donation> donations;

  const DonationsSummaryCard({
    super.key,
    required this.donations,
  });

  @override
  Widget build(BuildContext context) {
    final activeDonations =
        donations.where((d) => d.status == 'available').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Donations: ${donations.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Active: $activeDonations',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
