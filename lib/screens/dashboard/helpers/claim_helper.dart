import 'package:flutter/material.dart';
import '../../../models/donation.dart';
import '../../../models/user_profile.dart';
import '../../../services/repositories/donation_repository.dart';
import '../../../services/chat_navigation_helper.dart';

class ClaimHelper {
  static Future<void> showClaimDialog({
    required BuildContext context,
    required Donation donation,
    required UserProfile profile,
    required Function(Donation) onClaim,
    Function()? onRefresh,
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
              if (restaurantProfile.phoneNumber != null && restaurantProfile.phoneNumber!.isNotEmpty)
                Text('Phone: ${restaurantProfile.phoneNumber}'),
            ] else ...[
              Text('Restaurant details not available.'),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('Contact'),
            onPressed: () {
              Navigator.of(context).pop();
              ChatNavigationHelper.navigateToChatFromDonation(
                context: parentContext,
                donation: donation,
                currentUserId: profile.id,
                currentUserRole: 'ngo',
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = DonationRepository();
              bool claimSuccessful = false;
              try {
                // Perform atomic claim operation
                await repo.claimDonation(
                  donationId: donation.id,
                  ngoId: profile.id,
                  claimMessage: 'Interested in claiming this donation.',
                );
                
                claimSuccessful = true;
                
                // Update local state
                onClaim(donation);
                
                Navigator.of(context).pop();
                
                // Show success message
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Donation claimed successfully!'),
                    backgroundColor: Colors.green,),
                );             // Refresh the data from backend
                if (onRefresh != null) {
                  onRefresh();
                }
              } catch (e) {
                Navigator.of(context).pop();
                print('[ClaimHelper] Error during claim: $e');
                
                // Show user-friendly error message
                String errorMessage = 'Error claiming donation';
                if (e.toString().contains('no longer available')) {
                  errorMessage = 'This donation was already claimed by another NGO';
                } else if (e.toString().contains('expired')) {
                  errorMessage = 'This donation has expired';
                } else if (e.toString().contains('duplicate')) {
                  errorMessage = 'You have already claimed this donation';
                } else {
                  errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
                }
                
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
                
                // If claim failed, refresh to show current state
                if (!claimSuccessful && onRefresh != null) {
                  onRefresh();
                }
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
