import 'package:flutter/material.dart';
import '../../../../../../models/inventory_item.dart';
import '../../../../../../models/donation.dart';

class OverviewRecentActivity extends StatelessWidget {
  final List<InventoryItem> recentInventory;
  final List<Donation> recentDonations;
  final VoidCallback onViewInventory;
  final VoidCallback onViewDonations;

  const OverviewRecentActivity({
    super.key,
    required this.recentInventory,
    required this.recentDonations,
    required this.onViewInventory,
    required this.onViewDonations,
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
            _buildHeader(context),
            const SizedBox(height: 12),

            if (recentInventory.isEmpty && recentDonations.isEmpty)
              _buildEmptyState(context)
            else ...[
              if (recentInventory.isNotEmpty) ...[
                _buildSectionTitle('Recent Inventory Items'),
                const SizedBox(height: 8),
                ...recentInventory.map(
                  (item) => _buildInventoryRow(context, item),
                ),
              ],

              if (recentDonations.isNotEmpty) ...[
                if (recentInventory.isNotEmpty) const SizedBox(height: 16),
                _buildSectionTitle('Recent Donations'),
                const SizedBox(height: 8),
                ...recentDonations.map(
                  (donation) => _buildDonationRow(context, donation),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────── helpers ─────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.history, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewInventory,
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'No recent activity. Start by adding inventory items!',
        style: TextStyle(color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildInventoryRow(BuildContext context, InventoryItem item) {
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    return InkWell(
      onTap: onViewInventory,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.inventory, size: 16, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '${item.quantity} • Expires in $daysLeft days',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationRow(BuildContext context, Donation donation) {
    return InkWell(
      onTap: onViewDonations,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.favorite, size: 16, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(donation.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '${donation.quantity} • ${donation.status}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
