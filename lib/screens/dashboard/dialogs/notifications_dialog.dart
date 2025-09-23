import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // <-- Add this import
import '../../../models/donation.dart';

class NotificationsDialog extends StatelessWidget {
  final List<Donation> donations;

  const NotificationsDialog({super.key, required this.donations});

  @override
  Widget build(BuildContext context) {
    // Sort donations by date (assuming Donation has a DateTime field called 'postedAt')
    final sortedDonations = List<Donation>.from(donations)
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    final topDonations = sortedDonations.take(2).toList();

    return AlertDialog(
      title: const Text('Recent Donations'),
      content: topDonations.isEmpty
          ? const Text('No recent donations available.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: topDonations.map((donation) => ListTile(
                title: Text(donation.title ?? 'Donation'),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(donation.postedAt)} • ${DateFormat.Hm().format(donation.postedAt)}',
                ),
              )).toList(),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
