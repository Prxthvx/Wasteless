import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import '../../models/message.dart';
import '../../models/chat_thread.dart';

class MessageRepository {
  final SupabaseClient _client;

  MessageRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  /// Send a new message in a chat thread
  Future<Message> sendMessage({
    required String threadId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      debugPrint('[MessageRepository] Sending message in thread: $threadId');
      debugPrint(
        '[MessageRepository] Sender: $senderId, Receiver: $receiverId',
      );
      debugPrint('[MessageRepository] Content length: ${content.length} chars');

      final payload = {
        'thread_id': threadId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
      };

      debugPrint('[MessageRepository] Payload: $payload');

      final data = await _client
          .from('messages')
          .insert(payload)
          .select()
          .single();

      debugPrint('[MessageRepository] Message sent successfully');
      debugPrint('[MessageRepository] Response: $data');

      // Update thread's last_message_at
      await _updateThreadLastMessage(threadId);

      return Message.fromJson(Map<String, dynamic>.from(data));
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetch message history for a thread with pagination
  Future<List<Message>> fetchMessageHistory({
    required String threadId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint(
        '[MessageRepository] Fetching messages for thread: $threadId (limit: $limit, offset: $offset)',
      );

      final data = await _client
          .from('messages')
          .select()
          .eq('thread_id', threadId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint(
        '[MessageRepository] Fetched ${(data as List).length} messages',
      );
      debugPrint('[MessageRepository] Raw data: $data');

      final messages = (data as List)
          .map((e) {
            try {
              return Message.fromJson(Map<String, dynamic>.from(e));
            } catch (err, stackTrace) {
              debugPrint('[MessageRepository] Error parsing message: $e');
              debugPrint('Error: $err');
              debugPrint('Stack trace: $stackTrace');
              return null;
            }
          })
          .whereType<Message>()
          .toList();

      debugPrint(
        '[MessageRepository] Successfully parsed ${messages.length} messages',
      );
      return messages;
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error fetching message history: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Subscribe to real-time messages in a thread
  RealtimeChannel subscribeToMessages({
    required String threadId,
    required void Function(Message message) onMessageReceived,
    void Function(String error)? onError,
  }) {
    debugPrint(
      '[MessageRepository] Subscribing to messages in thread: $threadId',
    );

    final channel = _client
        .channel('messages:thread_id=eq.$threadId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: threadId,
          ),
          callback: (payload) {
            try {
              debugPrint('[MessageRepository] Real-time message received');
              final message = Message.fromJson(payload.newRecord);
              onMessageReceived(message);
            } catch (e, stackTrace) {
              debugPrint(
                '[MessageRepository] Error parsing real-time message: $e',
              );
              debugPrint('Stack trace: $stackTrace');
              if (onError != null) {
                onError(e.toString());
              }
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Mark a message as read
  Future<void> markAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      debugPrint('[MessageRepository] Marking message as read: $messageId');

      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('receiver_id', userId); // Only receiver can mark as read

      debugPrint('[MessageRepository] Message marked as read');
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error marking message as read: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Mark all messages in a thread as read
  Future<void> markThreadAsRead({
    required String threadId,
    required String userId,
  }) async {
    try {
      debugPrint('[MessageRepository] Marking thread as read: $threadId');

      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('thread_id', threadId)
          .eq('receiver_id', userId)
          .eq('is_read', false);

      debugPrint('[MessageRepository] Thread marked as read');
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error marking thread as read: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetch all chat threads for a user
  Future<List<ChatThread>> fetchChatThreads({required String userId}) async {
    try {
      debugPrint('[MessageRepository] Fetching chat threads for user: $userId');

      final data = await _client
          .from('chat_threads')
          .select('''
            *,
            restaurant:profiles!chat_threads_restaurant_id_fkey(*),
            ngo:profiles!chat_threads_ngo_id_fkey(*)
          ''')
          .or('restaurant_id.eq.$userId,ngo_id.eq.$userId')
          .order('last_message_at', ascending: false);

      debugPrint(
        '[MessageRepository] Fetched ${(data as List).length} chat threads',
      );

      return (data as List)
          .map((e) {
            try {
              debugPrint('[MessageRepository] Raw thread data: $e');
              return ChatThread.fromJson(Map<String, dynamic>.from(e));
            } catch (err, stackTrace) {
              debugPrint('[MessageRepository] Error parsing chat thread: $e');
              debugPrint('Error: $err');
              debugPrint('Stack trace: $stackTrace');
              return null;
            }
          })
          .whereType<ChatThread>()
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error fetching chat threads: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get a specific thread by ID
  Future<ChatThread?> getThreadById({required String threadId}) async {
    try {
      debugPrint('[MessageRepository] Fetching thread by ID: $threadId');

      final data = await _client
          .from('chat_threads')
          .select('''
            *,
            restaurant:profiles!chat_threads_restaurant_id_fkey(*),
            ngo:profiles!chat_threads_ngo_id_fkey(*)
          ''')
          .eq('id', threadId)
          .maybeSingle();

      if (data != null) {
        debugPrint('[MessageRepository] Thread found: $data');
        return ChatThread.fromJson(Map<String, dynamic>.from(data));
      } else {
        debugPrint('[MessageRepository] Thread not found: $threadId');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error fetching thread by ID: $e');
      debugPrint('Stack trace: $stackTrace');
      return null; // Don't crash, just return null
    }
  }

  /// Get or create a chat thread between two users
  Future<ChatThread> getChatThread({
    required String restaurantId,
    required String ngoId,
    String? donationId,
  }) async {
    try {
      debugPrint(
        '[MessageRepository] Getting chat thread: restaurant=$restaurantId, ngo=$ngoId, donation=$donationId',
      );

      if (restaurantId.isEmpty || ngoId.isEmpty) {
        throw Exception('Restaurant ID and NGO ID cannot be empty');
      }

      // Try to find ANY existing thread between these two users
      // (regardless of donation_id - we want one chat per restaurant-NGO pair)
      debugPrint(
        '[MessageRepository] Searching for existing thread between restaurant and NGO...',
      );

      final existingThreads = await _client
          .from('chat_threads')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('ngo_id', ngoId)
          .order('created_at', ascending: true) // Get oldest thread first
          .limit(1);

      if ((existingThreads as List).isNotEmpty) {
        final data = existingThreads.first;
        debugPrint('[MessageRepository] Found existing chat thread: $data');
        final thread = ChatThread.fromJson(Map<String, dynamic>.from(data));
        debugPrint(
          '[MessageRepository] Reusing existing thread, ID: ${thread.id}',
        );
        return thread;
      }

      // Create new thread if not found
      debugPrint(
        '[MessageRepository] No existing thread found, creating new one',
      );
      final payload = {
        'restaurant_id': restaurantId,
        'ngo_id': ngoId,
        if (donationId != null) 'donation_id': donationId,
      };

      debugPrint('[MessageRepository] Thread payload: $payload');

      final newData = await _client
          .from('chat_threads')
          .insert(payload)
          .select()
          .single();

      debugPrint(
        '[MessageRepository] Chat thread created successfully: $newData',
      );
      final newThread = ChatThread.fromJson(Map<String, dynamic>.from(newData));
      debugPrint('[MessageRepository] New thread created, ID: ${newThread.id}');
      return newThread;
    } catch (e, stackTrace) {
      debugPrint(
        '[MessageRepository] ❌ Error getting/creating chat thread: $e',
      );
      debugPrint('[MessageRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get unread message count for a user
  Future<int> getUnreadCount({required String userId}) async {
    try {
      debugPrint('[MessageRepository] Getting unread count for user: $userId');

      final data = await _client
          .from('messages')
          .select('id')
          .eq('receiver_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);

      final count = data.count;
      debugPrint('[MessageRepository] Unread messages: $count');
      return count;
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error getting unread count: $e');
      debugPrint('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Get unread message count for a specific thread
  Future<int> getThreadUnreadCount({
    required String threadId,
    required String userId,
  }) async {
    try {
      debugPrint(
        '[MessageRepository] Getting unread count for thread: $threadId',
      );

      final data = await _client
          .from('messages')
          .select('id')
          .eq('thread_id', threadId)
          .eq('receiver_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);

      final count = data.count;
      debugPrint('[MessageRepository] Thread unread messages: $count');
      return count;
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error getting thread unread count: $e');
      debugPrint('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Helper: Update thread's last_message_at timestamp
  Future<void> _updateThreadLastMessage(String threadId) async {
    try {
      await _client
          .from('chat_threads')
          .update({
            'last_message_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', threadId);
    } catch (e) {
      debugPrint('[MessageRepository] Error updating thread timestamp: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  /// Delete a message (soft delete by updating status if needed, or hard delete)
  Future<void> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      debugPrint('[MessageRepository] Deleting message: $messageId');

      await _client
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', userId); // Only sender can delete

      debugPrint('[MessageRepository] Message deleted');
    } catch (e, stackTrace) {
      debugPrint('[MessageRepository] Error deleting message: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
