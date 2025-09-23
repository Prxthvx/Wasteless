import 'package:flutter/material.dart';
import '../../../models/donation.dart';
import '../../../models/user_profile.dart';
import '../../../services/repositories/donation_repository.dart';

class ClaimHelper {
  static Future<void> showClaimDialog({
    required BuildContext context,
    required Donation donation,
    required UserProfile profile,
    required Function(Donation) onClaim,
  }) async {
    final restaurantProfile = donation.restaurantProfile;
    final parentContext = context;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Donation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claim "${donation.title}"?'),
            const SizedBox(height: 16),
            const Text('This will notify the restaurant of your interest.'),
            const SizedBox(height: 16),
            if (restaurantProfile != null) ...[
              Text('Organization Name: ${restaurantProfile.orgName ?? "Not available"}'),
              if ((restaurantProfile.phoneNumber ?? '').isNotEmpty)
                Text('Phone: ${restaurantProfile.phoneNumber}'),
            ] else ...[
              Text('Restaurant details not available.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = DonationRepository();
              try {
                final claimResult = await repo.claimDonation(
                  donationId: donation.id,
                  ngoId: profile.id,
                  claimMessage: 'Interested in claiming this donation.',
                );
                // Set status to 'claimed' after claim
                await repo.updateDonationStatus(
                  donationId: donation.id,
                  status: 'claimed',
                  claimedBy: profile.id,
                  claimedAt: DateTime.now(),
                  claimMessage: 'Interested in claiming this donation.',
                );
                onClaim(donation);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Donation claimed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                print('[ClaimHelper] Error during claim: $e');
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('Error claiming donation: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }
}
