import 'package:flutter/material.dart';
import '../../models/chat_thread.dart';
import '../dashboard/view_model/chat_view_model.dart';

class ChatListScreen extends StatelessWidget {
  final ChatViewModel viewModel;
  final String currentUserId;
  final void Function(ChatThread thread) onThreadTap;

  const ChatListScreen({
    super.key,
    required this.viewModel,
    required this.currentUserId,
    required this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (viewModel.totalUnreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _UnreadBadge(count: viewModel.totalUnreadCount),
              ),
            ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.threads.isEmpty
          ? _EmptyState()
          : _ThreadsList(
              threads: viewModel.threads,
              currentUserId: currentUserId,
              getUnreadCount: (threadId) =>
                  viewModel.getThreadUnreadCount(threadId),
              onThreadTap: onThreadTap,
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Start chatting with restaurants or NGOs',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ThreadsList extends StatelessWidget {
  final List<ChatThread> threads;
  final String currentUserId;
  final int Function(String threadId) getUnreadCount;
  final void Function(ChatThread thread) onThreadTap;

  const _ThreadsList({
    required this.threads,
    required this.currentUserId,
    required this.getUnreadCount,
    required this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        final unreadCount = getUnreadCount(thread.id);

        return _ThreadListItem(
          thread: thread,
          currentUserId: currentUserId,
          unreadCount: unreadCount,
          onTap: () => onThreadTap(thread),
        );
      },
    );
  }
}

class _ThreadListItem extends StatelessWidget {
  final ChatThread thread;
  final String currentUserId;
  final int unreadCount;
  final VoidCallback onTap;

  const _ThreadListItem({
    required this.thread,
    required this.currentUserId,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the other user's ID and role
    final isRestaurant = thread.restaurantId == currentUserId;
    final otherUserName = thread.getOtherUserName(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRestaurant ? Colors.blue : Colors.green,
          child: Icon(
            isRestaurant ? Icons.business : Icons.volunteer_activism,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: TextStyle(
                  fontWeight: unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (unreadCount > 0) _UnreadBadge(count: unreadCount),
          ],
        ),
        subtitle: Text(
          _formatLastMessageTime(thread.lastMessageAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 20),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
