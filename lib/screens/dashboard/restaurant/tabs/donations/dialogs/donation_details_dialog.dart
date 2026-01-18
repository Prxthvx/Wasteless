import 'package:flutter/material.dart';
import '../../../../../../models/donation.dart';

Future<void> showDonationDetailsDialog({
  required BuildContext context,
  required Donation donation,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
