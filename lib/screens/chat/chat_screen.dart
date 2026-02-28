import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../dashboard/view_model/chat_view_model.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final ChatViewModel viewModel;
  final String currentUserId;
  final String otherUserName;
  final String? otherUserRole; // 'restaurant' or 'ngo'

  const ChatScreen({
    super.key,
    required this.viewModel,
    required this.currentUserId,
    required this.otherUserName,
    this.otherUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Listen to ViewModel changes to rebuild UI when messages are added/updated
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Remove ViewModel listener
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    // Rebuild the widget when ViewModel notifies changes
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    // Load more messages when scrolled to top
    if (_scrollController.position.pixels <= 100 &&
        widget.viewModel.hasMoreMessages &&
        !widget.viewModel.isLoadingMore) {
      widget.viewModel.loadMoreMessages(userId: widget.currentUserId);
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();

    debugPrint('[ChatScreen] _sendMessage called');
    debugPrint('[ChatScreen] Content: "$content"');
    debugPrint('[ChatScreen] Content isEmpty: ${content.isEmpty}');

    if (content.isEmpty) {
      debugPrint('[ChatScreen] Content is empty, returning');
      return;
    }

    final thread = widget.viewModel.currentThread;
    debugPrint('[ChatScreen] Current thread: ${thread?.id ?? "NULL"}');

    if (thread == null) {
      debugPrint('[ChatScreen] Thread is null, returning');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Chat thread not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Determine receiver ID based on current user
    final receiverId = thread.restaurantId == widget.currentUserId
        ? thread.ngoId
        : thread.restaurantId;

    debugPrint('[ChatScreen] Sending message:');
    debugPrint('[ChatScreen]   - Current User: ${widget.currentUserId}');
    debugPrint('[ChatScreen]   - Thread Restaurant: ${thread.restaurantId}');
    debugPrint('[ChatScreen]   - Thread NGO: ${thread.ngoId}');
    debugPrint('[ChatScreen]   - Receiver: $receiverId');

    try {
      widget.viewModel.sendMessage(
        senderId: widget.currentUserId,
        receiverId: receiverId,
        content: content,
      );

      _messageController.clear();

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('[ChatScreen] Error in sendMessage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug current state
    debugPrint(
      '[ChatScreen] Building - Messages: ${widget.viewModel.messages.length}, Error: ${widget.viewModel.errorMessage}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            if (widget.otherUserRole != null)
              Text(
                widget.otherUserRole == 'restaurant' ? 'Restaurant' : 'NGO',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Error message banner
          if (widget.viewModel.errorMessage != null)
            _ErrorBanner(
              message: widget.viewModel.errorMessage!,
              onDismiss: () => widget.viewModel.clearError(),
            ),

          // Messages list
          Expanded(
            child: widget.viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _MessagesList(
                    messages: widget.viewModel.messages,
                    currentUserId: widget.currentUserId,
                    scrollController: _scrollController,
                    isLoadingMore: widget.viewModel.isLoadingMore,
                    onDeleteMessage: (messageId) {
                      widget.viewModel.deleteMessage(
                        messageId: messageId,
                        userId: widget.currentUserId,
                      );
                    },
                  ),
          ),

          // Message input
          SafeArea(
            child: _MessageInput(
              controller: _messageController,
              isSending: widget.viewModel.isSendingMessage,
              onSend: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final void Function(String messageId) onDeleteMessage;

  const _MessagesList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onDeleteMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at top
        if (index == 0 && isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final messageIndex = isLoadingMore ? index - 1 : index;
        final message = messages[messageIndex];
        final isMe = message.senderId == currentUserId;

        // Show date separator
        final showDateSeparator = _shouldShowDateSeparator(
          messages,
          messageIndex,
        );

        return Column(
          children: [
            if (showDateSeparator) _DateSeparator(date: message.createdAt),

            MessageBubble(
              message: message,
              isMe: isMe,
              onDelete: isMe ? () => onDeleteMessage(message.id) : null,
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDateSeparator(List<Message> messages, int index) {
    if (index == 0) return true;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    final currentDate = DateTime(
      currentMessage.createdAt.year,
      currentMessage.createdAt.month,
      currentMessage.createdAt.day,
    );

    final previousDate = DateTime(
      previousMessage.createdAt.year,
      previousMessage.createdAt.month,
      previousMessage.createdAt.day,
    );

    return currentDate != previousDate;
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String label;
    if (messageDate == today) {
      label = 'Today';
    } else if (messageDate == yesterday) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              enabled: !isSending,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: isSending ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
