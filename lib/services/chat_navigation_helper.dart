import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/dashboard/view_model/chat_view_model.dart';

/// Helper class for chat navigation
class ChatNavigationHelper {
  /// Navigate to chat list screen
  static Future<void> navigateToChatList({
    required BuildContext context,
    required String currentUserId,
  }) async {
    final chatViewModel = ChatViewModel();

    // Load chat threads
    await chatViewModel.loadChatThreads(userId: currentUserId);

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatListScreen(
          viewModel: chatViewModel,
          currentUserId: currentUserId,
          onThreadTap: (thread) async {
            // Initialize chat for this specific thread
            await chatViewModel.initializeChat(
              threadId: thread.id,
              userId: currentUserId,
            );

            if (!context.mounted) return;

            // Determine other user info
            final isRestaurant = thread.restaurantId == currentUserId;
            final otherUserRole = isRestaurant ? 'ngo' : 'restaurant';
            final otherUserName = thread.getOtherUserName(currentUserId);

            // Navigate to chat screen
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  viewModel: chatViewModel,
                  currentUserId: currentUserId,
                  otherUserName: otherUserName,
                  otherUserRole: otherUserRole,
                ),
              ),
            );
          },
        ),
      ),
    );

    // Cleanup
    chatViewModel.dispose();
  }

  /// Navigate to chat screen with specific user and donation
  static Future<void> navigateToChat({
    required BuildContext context,
    required String currentUserId,
    required String restaurantId,
    required String ngoId,
    required String otherUserName,
    required String otherUserRole, // 'restaurant' or 'ngo'
    String? donationId,
  }) async {
    debugPrint('[ChatNavigationHelper] navigateToChat called');
    debugPrint('[ChatNavigationHelper]   - Current User: $currentUserId');
    debugPrint('[ChatNavigationHelper]   - Restaurant ID: $restaurantId');
    debugPrint('[ChatNavigationHelper]   - NGO ID: $ngoId');
    debugPrint(
      '[ChatNavigationHelper]   - Other User: $otherUserName ($otherUserRole)',
    );
    debugPrint('[ChatNavigationHelper]   - Donation ID: $donationId');

    final chatViewModel = ChatViewModel();

    try {
      // Initialize chat
      debugPrint('[ChatNavigationHelper] Calling initializeChatWithUsers...');
      await chatViewModel.initializeChatWithUsers(
        restaurantId: restaurantId,
        ngoId: ngoId,
        currentUserId: currentUserId,
        donationId: donationId,
      );

      debugPrint(
        '[ChatNavigationHelper] Chat initialized, thread ID: ${chatViewModel.currentThreadId}',
      );

      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            viewModel: chatViewModel,
            currentUserId: currentUserId,
            otherUserName: otherUserName,
            otherUserRole: otherUserRole,
          ),
        ),
      );

      // Cleanup
      chatViewModel.dispose();
    } catch (e, stackTrace) {
      debugPrint('[ChatNavigationHelper] ❌ Error navigating to chat: $e');
      debugPrint('Stack trace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to chat from donation (for NGO claiming donation)
  static Future<void> navigateToChatFromDonation({
    required BuildContext context,
    required Donation donation,
    required String currentUserId,
    required String currentUserRole, // 'restaurant' or 'ngo'
  }) async {
    final restaurantId = donation.restaurantId;
    final restaurantName =
        donation.restaurantProfile?.name ??
        donation.restaurantProfile?.orgName ??
        'Restaurant';

    if (currentUserRole == 'ngo') {
      // NGO contacting restaurant
      await navigateToChat(
        context: context,
        currentUserId: currentUserId,
        restaurantId: restaurantId,
        ngoId: currentUserId,
        otherUserName: restaurantName,
        otherUserRole: 'restaurant',
        donationId: donation.id,
      );
    } else {
      // Restaurant viewing their own donation - need NGO ID
      if (donation.claimedBy != null) {
        await navigateToChat(
          context: context,
          currentUserId: currentUserId,
          restaurantId: currentUserId,
          ngoId: donation.claimedBy!,
          otherUserName: 'NGO',
          otherUserRole: 'ngo',
          donationId: donation.id,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No NGO has claimed this donation yet.'),
          ),
        );
      }
    }
  }
}
