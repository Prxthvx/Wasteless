import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/message.dart';
import '../../../../models/chat_thread.dart';
import '../../../../services/repositories/message_repository.dart';
import '../../../../services/chat_service.dart';

class ChatViewModel extends ChangeNotifier {
  final MessageRepository _messageRepository;
  final ChatService _chatService;

  ChatViewModel({
    MessageRepository? messageRepository,
    ChatService? chatService,
  })  : _messageRepository = messageRepository ?? MessageRepository(),
        _chatService = chatService ?? ChatService();

  // ============================================================
  // STATE
  // ============================================================

  /// Loading states
  bool isLoading = false;
  bool isSendingMessage = false;
  bool isLoadingMore = false;

  /// Current thread
  ChatThread? currentThread;
  String? currentThreadId;

  /// Messages for current thread
  List<Message> messages = [];

  /// Chat threads list
  List<ChatThread> threads = [];

  /// Unread counts
  int totalUnreadCount = 0;
  Map<String, int> threadUnreadCounts = {};

  /// Pagination
  int _currentOffset = 0;
  final int _pageSize = 50;
  bool hasMoreMessages = true;

  /// Error handling
  String? errorMessage;

  /// Realtime subscription
  RealtimeChannel? _activeSubscription;

  // ============================================================
  // INITIALIZATION & LIFECYCLE
  // ============================================================

  /// Initialize chat for a specific thread
  Future<void> initializeChat({
    required String threadId,
    required String userId,
  }) async {
    debugPrint('[ChatViewModel] Initializing chat for thread: $threadId, user: $userId');
    
    currentThreadId = threadId;
    messages = [];
    _currentOffset = 0;
    hasMoreMessages = true;
    errorMessage = null;

    try {
      // Fetch the thread object (needed for getting receiver ID when sending messages)
      debugPrint('[ChatViewModel] Fetching thread details from repository...');
      final threadData = await _chatService.getThreadById(threadId: threadId);
      if (threadData != null) {
        currentThread = threadData;
        debugPrint('[ChatViewModel] Thread loaded: restaurant=${currentThread?.restaurantId}, ngo=${currentThread?.ngoId}');
      } else {
        debugPrint('[ChatViewModel] ⚠️ Warning: Could not fetch thread object for ID: $threadId');
      }
    } catch (e) {
      debugPrint('[ChatViewModel] ⚠️ Error fetching thread: $e (continuing without thread object)');
      // Continue anyway - we can still load messages with just the threadId
    }

    await loadMessages(userId: userId);
    _subscribeToThread(threadId, userId);
    
    debugPrint('[ChatViewModel] Chat initialized with ${messages.length} messages, thread: ${currentThread != null ? "exists" : "NULL"}');
  }

  /// Initialize chat with restaurant and NGO (creates thread if needed)
  Future<void> initializeChatWithUsers({
    required String restaurantId,
    required String ngoId,
    required String currentUserId,
    String? donationId,
  }) async {
    debugPrint('[ChatViewModel] Initializing chat: restaurant=$restaurantId, ngo=$ngoId, user=$currentUserId, donation=$donationId');
    
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Get or create thread
      currentThread = await _chatService.getChatThread(
        restaurantId: restaurantId,
        ngoId: ngoId,
        donationId: donationId,
      );

      debugPrint('[ChatViewModel] Got thread: ${currentThread!.id}');
      currentThreadId = currentThread!.id;

      // Load messages for this thread
      await initializeChat(
        threadId: currentThread!.id,
        userId: currentUserId,
      );
      
      debugPrint('[ChatViewModel] Chat initialized successfully with ${messages.length} messages');
    } catch (e, stackTrace) {
      debugPrint('[ChatViewModel] Error initializing chat: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = 'Failed to load chat: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load chat threads for user
  Future<void> loadChatThreads({required String userId}) async {
    debugPrint('[ChatViewModel] Loading chat threads for user: $userId');
    
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      threads = await _chatService.fetchChatThreads(userId: userId);
      
      // Load unread counts for each thread
      for (final thread in threads) {
        final unreadCount = await _chatService.getThreadUnreadCount(
          threadId: thread.id,
          userId: userId,
        );
        threadUnreadCounts[thread.id] = unreadCount;
      }

      // Load total unread count
      totalUnreadCount = await _chatService.getUnreadCount(userId: userId);
      
      debugPrint('[ChatViewModel] Loaded ${threads.length} threads');
    } catch (e, stackTrace) {
      debugPrint('[ChatViewModel] Error loading threads: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = 'Failed to load conversations: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // MESSAGE OPERATIONS
  // ============================================================

  /// Load messages for current thread
  Future<void> loadMessages({
    required String userId,
    bool refresh = false,
  }) async {
    if (currentThreadId == null) {
      debugPrint('[ChatViewModel] No thread selected');
      return;
    }

    if (refresh) {
      messages = [];
      _currentOffset = 0;
      hasMoreMessages = true;
    }

    isLoading = refresh;
    errorMessage = null;
    notifyListeners();

    try {
      final fetchedMessages = await _chatService.fetchMessageHistory(
        threadId: currentThreadId!,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (fetchedMessages.length < _pageSize) {
        hasMoreMessages = false;
      }

      if (refresh) {
        messages = fetchedMessages.reversed.toList();
      } else {
        messages.insertAll(0, fetchedMessages.reversed.toList());
      }

      _currentOffset += fetchedMessages.length;

      // Mark thread as read
      await markThreadAsRead(userId: userId);

      debugPrint('[ChatViewModel] Loaded ${fetchedMessages.length} messages. Total: ${messages.length}');
    } catch (e, stackTrace) {
      debugPrint('[ChatViewModel] Error loading messages: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = 'Failed to load messages: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages({required String userId}) async {
    if (!hasMoreMessages || isLoadingMore || currentThreadId == null) {
      return;
    }

    isLoadingMore = true;
    notifyListeners();

    try {
      final fetchedMessages = await _chatService.fetchMessageHistory(
        threadId: currentThreadId!,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (fetchedMessages.length < _pageSize) {
        hasMoreMessages = false;
      }

      messages.insertAll(0, fetchedMessages.reversed.toList());
      _currentOffset += fetchedMessages.length;

      debugPrint('[ChatViewModel] Loaded ${fetchedMessages.length} more messages. Total: ${messages.length}');
    } catch (e, stackTrace) {
      debugPrint('[ChatViewModel] Error loading more messages: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Send a message with optimistic UI update
  // Future<void> sendMessage({
  //   required String senderId,
  //   required String receiverId,
  //   required String content,
  // }) async {
  //   if (currentThreadId == null || content.trim().isEmpty) {
  //     debugPrint('[ChatViewModel] Cannot send message: threadId=$currentThreadId, content="${content.trim()}"');
  //     errorMessage = 'Cannot send message: Invalid data';
  //     notifyListeners();
  //     return;
  //   }

  //   debugPrint('[ChatViewModel] Sending message in thread: $currentThreadId');
  //   debugPrint('[ChatViewModel] Sender: $senderId, Receiver: $receiverId');
  //   debugPrint('[ChatViewModel] Content: "${content.trim()}"');

  //   // Create optimistic message
  //   final optimisticMessage = Message(
  //     id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
  //     threadId: currentThreadId!,
  //     senderId: senderId,
  //     receiverId: receiverId,
  //     content: content.trim(),
  //     createdAt: DateTime.now(),
  //     updatedAt: DateTime.now(),
  //     isRead: false,
  //   );

  //   // Add optimistic message to list
  //   messages.add(optimisticMessage);
  //   isSendingMessage = true;
  //   notifyListeners();

  //   try {
  //     // Send actual message
  //     debugPrint('[ChatViewModel] Calling chatService.sendMessage...');
  //     final sentMessage = await _chatService.sendMessage(
  //       threadId: currentThreadId!,
  //       senderId: senderId,
  //       receiverId: receiverId,
  //       content: content.trim(),
  //     );

  //     debugPrint('[ChatViewModel] Message sent successfully, ID: ${sentMessage.id}');

  //     // Replace optimistic message with real one
  //     final index = messages.indexWhere((m) => m.id == optimisticMessage.id);
  //     if (index != -1) {
  //       messages[index] = sentMessage;
  //       debugPrint('[ChatViewModel] Replaced optimistic message with real message');
  //     } else {
  //       // If optimistic message not found, check if real message already exists (from realtime)
  //       final exists = messages.any((m) => m.id == sentMessage.id);
  //       if (!exists) {
  //         debugPrint('[ChatViewModel] Optimistic message not found, adding real message');
  //         messages.add(sentMessage);
  //       } else {
  //         debugPrint('[ChatViewModel] Real message already exists (from realtime), skipping');
  //       }
  //     }

  //     debugPrint('[ChatViewModel] Message sent successfully. Total messages: ${messages.length}');
  //     errorMessage = null; // Clear any previous errors
  //     notifyListeners();
  //   } catch (e, stackTrace) {
  //     debugPrint('[ChatViewModel] ❌ Error sending message: $e');
  //     debugPrint('Stack trace: $stackTrace');
      
  //     // Remove optimistic message on error
  //     messages.removeWhere((m) => m.id == optimisticMessage.id);
  //     errorMessage = 'Failed to send message: ${e.toString()}';
  //     notifyListeners();
      
  //     // Re-throw so UI can catch it
  //     rethrow;
  //   } finally {
  //     isSendingMessage = false;
  //     notifyListeners();
  //   }
  // }

  /// Mark thread as read
  Future<void> markThreadAsRead({required String userId}) async {
    if (currentThreadId == null) return;

    try {
      await _chatService.markThreadAsRead(
        threadId: currentThreadId!,
        userId: userId,
      );

      // Update local unread count
      threadUnreadCounts[currentThreadId!] = 0;
      
      // Recalculate total unread count
      totalUnreadCount = threadUnreadCounts.values.fold(0, (sum, count) => sum + count);
      
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatViewModel] Error marking thread as read: $e');
    }
  }

    /// Send a message (simplified - no optimistic updates)
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    if (currentThreadId == null || content.trim().isEmpty) {
      debugPrint('[ChatViewModel] Cannot send message: threadId=$currentThreadId, content="${content.trim()}"');
      errorMessage = 'Cannot send message: Invalid data';
      notifyListeners();
      return;
    }

    debugPrint('[ChatViewModel] Sending message in thread: $currentThreadId');
    debugPrint('[ChatViewModel] Sender: $senderId, Receiver: $receiverId');
    debugPrint('[ChatViewModel] Content: "${content.trim()}"');

    isSendingMessage = true;
    notifyListeners();

    try {
      // Send message directly without optimistic update
      debugPrint('[ChatViewModel] Calling chatService.sendMessage...');
      final sentMessage = await _chatService.sendMessage(
        threadId: currentThreadId!,
        senderId: senderId,
        receiverId: receiverId,
        content: content.trim(),
      );

      debugPrint('[ChatViewModel] Message sent successfully, ID: ${sentMessage.id}');

      // Check if message already exists (from realtime subscription)
      final exists = messages.any((m) => m.id == sentMessage.id);
      
      if (!exists) {
        debugPrint('[ChatViewModel] Adding sent message to list');
        messages.add(sentMessage);
        notifyListeners();
      } else {
        debugPrint('[ChatViewModel] Message already added by realtime, skipping');
      }

      debugPrint('[ChatViewModel] Message sent successfully. Total messages: ${messages.length}');
      errorMessage = null;
    } catch (e, stackTrace) {
      debugPrint('[ChatViewModel] ❌ Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      
      errorMessage = 'Failed to send message: ${e.toString()}';
      notifyListeners();
      
      // Re-throw so UI can catch it
      rethrow;
    } finally {
      isSendingMessage = false;
      notifyListeners();
    }
  }
  /// Delete a message
  Future<void> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      await _chatService.deleteMessage(
        messageId: messageId,
        userId: userId,
      );

      // Remove from local list
      messages.removeWhere((m) => m.id == messageId);
      notifyListeners();

      debugPrint('[ChatViewModel] Message deleted');
    } catch (e, stackTrace) {
      debugPrint('[ChatViewModel] Error deleting message: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = 'Failed to delete message: $e';
      notifyListeners();
    }
  }

  // ============================================================
  // REALTIME SUBSCRIPTION
  // ============================================================

  /// Subscribe to realtime updates for current thread
  void _subscribeToThread(String threadId, String userId) {
    debugPrint('[ChatViewModel] Subscribing to thread: $threadId');

    // Unsubscribe from previous thread if any
    _unsubscribeFromThread();

    _activeSubscription = _messageRepository.subscribeToMessages(
      threadId: threadId,
      onMessageReceived: (message) {
        debugPrint('[ChatViewModel] Received realtime message: ${message.id}');

        // Check if message already exists to avoid duplicates
        final exists = messages.any((m) => m.id == message.id);
        
        if (!exists) {
          debugPrint('[ChatViewModel] Adding new message to list');
          messages.add(message);
          notifyListeners();
        } else {
          debugPrint('[ChatViewModel] Message already exists, skipping');
        }

        // Mark as read automatically if chat is open and message is from other user
        if (message.senderId != userId) {
          _chatService.markMessageAsRead(
            messageId: message.id,
            userId: userId,
          );
        }
      },
      onError: (error) {
        debugPrint('[ChatViewModel] Realtime subscription error: $error');
        errorMessage = 'Connection error: $error';
        notifyListeners();
      },
    );
  }

  /// Unsubscribe from current thread
  void _unsubscribeFromThread() {
    if (_activeSubscription != null) {
      debugPrint('[ChatViewModel] Unsubscribing from thread');
      _activeSubscription!.unsubscribe();
      _activeSubscription = null;
    }
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Get unread count for a specific thread (cached)
  int getThreadUnreadCount(String threadId) {
    return threadUnreadCounts[threadId] ?? 0;
  }

  /// Clear current chat
  void clearCurrentChat() {
    debugPrint('[ChatViewModel] Clearing current chat');
    
    _unsubscribeFromThread();
    currentThread = null;
    currentThreadId = null;
    messages = [];
    _currentOffset = 0;
    hasMoreMessages = true;
    errorMessage = null;
    
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    debugPrint('[ChatViewModel] Disposing ChatViewModel');
    
    _unsubscribeFromThread();
    _chatService.dispose();
    
    super.dispose();
  }
}
