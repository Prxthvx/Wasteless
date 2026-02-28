import 'package:flutter/material.dart';
import '../../../../../../../models/donation.dart';

class DonationsList extends StatelessWidget {
  final List<Donation> donations;
  final void Function(String action, Donation donation) onAction;

  const DonationsList({
    super.key,
    required this.donations,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      cacheExtent: 200.0, // Cache items for smoother scrolling
      addAutomaticKeepAlives: false, // Reduce memory usage
      addRepaintBoundaries: true, // Optimize repaints
      itemBuilder: (context, index) {
        final donation = donations[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(donation.status),
              child: Icon(
                _statusIcon(donation.status),
                color: Colors.white,
              ),
            ),
            title: Text(donation.title),
            subtitle: Text('Quantity: ${donation.quantity}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'view', child: Text('View Details')),
              ],
              onSelected: (value) => onAction(value, donation),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'claimed':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.favorite;
      case 'claimed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done;
      default:
        return Icons.info;
    }
  }
}
