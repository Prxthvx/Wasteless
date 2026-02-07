import 'package:flutter/material.dart';
import '../../../../../../models/donation.dart';
import '../../../../../../services/chat_navigation_helper.dart';

Future<void> showDonationDetailsDialog({
  required BuildContext context,
  required Donation donation,
  required String currentUserId,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(donation.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quantity: ${donation.quantity}'),
          const SizedBox(height: 8),
          Text('Status: ${donation.status}'),
          const SizedBox(height: 8),
          Text(
            'Expires on: ${donation.expiryDate.toString().split(' ').first}',
          ),
          if (donation.description != null) ...[
            const SizedBox(height: 12),
            Text(donation.description!),
          ],
          if (donation.status == 'claimed' && donation.claimedBy != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'This donation has been claimed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      actions: [
        if (donation.status == 'claimed' && donation.claimedBy != null)
          TextButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('Contact NGO'),
            onPressed: () {
              Navigator.of(context).pop();
              ChatNavigationHelper.navigateToChatFromDonation(
                context: context,
                donation: donation,
                currentUserId: currentUserId,
                currentUserRole: 'restaurant',
              );
            },
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
