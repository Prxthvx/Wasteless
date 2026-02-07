import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/chat_thread.dart';
import './repositories/message_repository.dart';
import './notification_service.dart';

/// ChatService orchestrates chat operations and manages realtime subscriptions
class ChatService {
  final MessageRepository _repository;
  
  // Active realtime subscriptions
  final Map<String, RealtimeChannel> _activeSubscriptions = {};
  
  // Unread count cache
  int _totalUnreadCount = 0;
  final Map<String, int> _threadUnreadCounts = {};

  // Callbacks for UI updates
  final List<Function(int)> _unreadCountListeners = [];
  final List<Function(Message)> _messageReceivedListeners = [];

  ChatService({MessageRepository? repository})
      : _repository = repository ?? MessageRepository();

  // ============================================================
  // REALTIME SUBSCRIPTION MANAGEMENT
  // ============================================================

  /// Subscribe to messages in a specific thread
  /// Returns subscription ID for cleanup
  String subscribeToThread({
    required String threadId,
    required void Function(Message message) onMessageReceived,
    void Function(String error)? onError,
  }) {
    debugPrint('[ChatService] Subscribing to thread: $threadId');

    // Unsubscribe existing subscription for this thread if any
    if (_activeSubscriptions.containsKey(threadId)) {
      unsubscribeFromThread(threadId);
    }

    final channel = _repository.subscribeToMessages(
      threadId: threadId,
      onMessageReceived: (message) {
        debugPrint('[ChatService] Message received in thread: $threadId');
        
        // Notify all listeners
        for (final listener in _messageReceivedListeners) {
          listener(message);
        }
        
        // Call thread-specific callback
        onMessageReceived(message);
        
        // Update unread count if message is for current user
        // (This will be refined in UI layer with actual user ID)
        _refreshUnreadCounts();
      },
      onError: onError,
    );

    _activeSubscriptions[threadId] = channel;
    debugPrint('[ChatService] Active subscriptions: ${_activeSubscriptions.length}');
    
    return threadId;
  }

  /// Unsubscribe from a specific thread
  Future<void> unsubscribeFromThread(String threadId) async {
    debugPrint('[ChatService] Unsubscribing from thread: $threadId');
    
    final channel = _activeSubscriptions.remove(threadId);
    if (channel != null) {
      await channel.unsubscribe();
      debugPrint('[ChatService] Unsubscribed from thread: $threadId');
    }
  }

  /// Unsubscribe from all active threads
  Future<void> unsubscribeAll() async {
    debugPrint('[ChatService] Unsubscribing from all threads');
    
    final futures = _activeSubscriptions.values.map((channel) => channel.unsubscribe());
    await Future.wait(futures);
    
    _activeSubscriptions.clear();
    debugPrint('[ChatService] All subscriptions cleared');
  }

  // ============================================================
  // MESSAGE OPERATIONS
  // ============================================================

  /// Send a message in a thread
  Future<Message> sendMessage({
    required String threadId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    debugPrint('[ChatService] Sending message in thread: $threadId');

    final message = await _repository.sendMessage(
      threadId: threadId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
    );

    debugPrint('[ChatService] Message sent successfully');
    return message;
  }

  /// Fetch message history for a thread
  Future<List<Message>> fetchMessageHistory({
    required String threadId,
    int limit = 50,
    int offset = 0,
  }) async {
    return await _repository.fetchMessageHistory(
      threadId: threadId,
      limit: limit,
      offset: offset,
    );
  }

  /// Mark a message as read
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    await _repository.markAsRead(
      messageId: messageId,
      userId: userId,
    );
    
    // Refresh unread counts
    await _refreshUnreadCounts(userId: userId);
  }

  /// Mark all messages in a thread as read
  Future<void> markThreadAsRead({
    required String threadId,
    required String userId,
  }) async {
    debugPrint('[ChatService] Marking thread as read: $threadId');
    
    await _repository.markThreadAsRead(
      threadId: threadId,
      userId: userId,
    );
    
    // Update local cache
    _threadUnreadCounts[threadId] = 0;
    
    // Refresh total unread count
    await _refreshUnreadCounts(userId: userId);
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    await _repository.deleteMessage(
      messageId: messageId,
      userId: userId,
    );
  }

  // ============================================================
  // THREAD OPERATIONS
  // ============================================================

  /// Fetch all chat threads for a user
  Future<List<ChatThread>> fetchChatThreads({
    required String userId,
  }) async {
    return await _repository.fetchChatThreads(userId: userId);
  }

  /// Get a specific thread by ID
  Future<ChatThread?> getThreadById({
    required String threadId,
  }) async {
    return await _repository.getThreadById(threadId: threadId);
  }

  /// Get or create a chat thread
  Future<ChatThread> getChatThread({
    required String restaurantId,
    required String ngoId,
    String? donationId,
  }) async {
    return await _repository.getChatThread(
      restaurantId: restaurantId,
      ngoId: ngoId,
      donationId: donationId,
    );
  }

  // ============================================================
  // UNREAD COUNT TRACKING
  // ============================================================

  /// Get total unread message count for a user
  Future<int> getUnreadCount({required String userId}) async {
    final count = await _repository.getUnreadCount(userId: userId);
    _totalUnreadCount = count;
    
    // Notify listeners
    _notifyUnreadCountListeners();
    
    return count;
  }

  /// Get unread count for a specific thread
  Future<int> getThreadUnreadCount({
    required String threadId,
    required String userId,
  }) async {
    final count = await _repository.getThreadUnreadCount(
      threadId: threadId,
      userId: userId,
    );
    
    // Update cache
    _threadUnreadCounts[threadId] = count;
    
    return count;
  }

  /// Get cached total unread count (no network call)
  int getCachedUnreadCount() => _totalUnreadCount;

  /// Get cached thread unread count (no network call)
  int getCachedThreadUnreadCount(String threadId) {
    return _threadUnreadCounts[threadId] ?? 0;
  }

  /// Refresh unread counts and notify listeners
  Future<void> _refreshUnreadCounts({String? userId}) async {
    if (userId != null) {
      await getUnreadCount(userId: userId);
    }
  }

  // ============================================================
  // NOTIFICATION HANDLING
  // ============================================================

  /// Trigger local notification for new message
  Future<void> triggerMessageNotification({
    required String senderName,
    required String messagePreview,
    String? threadId,
  }) async {
    debugPrint('[ChatService] Triggering message notification');

    try {
      // Use existing NotificationService to show notification
      await NotificationService.showDonationAlert(
        title: 'New Message from $senderName',
        body: messagePreview,
        payload: threadId != null ? 'chat:$threadId' : 'chat',
      );
    } catch (e) {
      debugPrint('[ChatService] Error showing notification: $e');
    }
  }

  /// Hook for future push notification integration
  Future<void> registerPushNotificationToken({
    required String userId,
    required String fcmToken,
  }) async {
    debugPrint('[ChatService] Registering push notification token');
    // TODO: Store FCM token in database for push notifications
    // This would be implemented when push notifications are added
    // Example: await _client.from('user_tokens').insert({
    //   'user_id': userId,
    //   'fcm_token': fcmToken,
    //   'platform': Platform.isAndroid ? 'android' : 'ios',
    // })
  }

  /// Hook for future push notification removal
  Future<void> removePushNotificationToken({
    required String userId,
  }) async {
    debugPrint('[ChatService] Removing push notification token');
    // TODO: Remove FCM token from database
  }

  // ============================================================
  // LISTENER MANAGEMENT
  // ============================================================

  /// Add listener for unread count changes
  void addUnreadCountListener(Function(int) listener) {
    if (!_unreadCountListeners.contains(listener)) {
      _unreadCountListeners.add(listener);
      debugPrint('[ChatService] Added unread count listener. Total: ${_unreadCountListeners.length}');
    }
  }

  /// Remove unread count listener
  void removeUnreadCountListener(Function(int) listener) {
    _unreadCountListeners.remove(listener);
    debugPrint('[ChatService] Removed unread count listener. Total: ${_unreadCountListeners.length}');
  }

  /// Add listener for message received events
  void addMessageReceivedListener(Function(Message) listener) {
    if (!_messageReceivedListeners.contains(listener)) {
      _messageReceivedListeners.add(listener);
      debugPrint('[ChatService] Added message listener. Total: ${_messageReceivedListeners.length}');
    }
  }

  /// Remove message received listener
  void removeMessageReceivedListener(Function(Message) listener) {
    _messageReceivedListeners.remove(listener);
    debugPrint('[ChatService] Removed message listener. Total: ${_messageReceivedListeners.length}');
  }

  /// Notify all unread count listeners
  void _notifyUnreadCountListeners() {
    for (final listener in _unreadCountListeners) {
      listener(_totalUnreadCount);
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /// Dispose service and cleanup resources
  Future<void> dispose() async {
    debugPrint('[ChatService] Disposing service');
    
    await unsubscribeAll();
    _unreadCountListeners.clear();
    _messageReceivedListeners.clear();
    _threadUnreadCounts.clear();
    _totalUnreadCount = 0;
    
    debugPrint('[ChatService] Service disposed');
  }
}
