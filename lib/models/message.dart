import 'package:intl/intl.dart';

class Message {
  final String id;
  final String threadId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isRead,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thread_id': threadId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory Message.fromMap(Map<String, dynamic> map) => Message.fromJson(map);

  // Helper getters for UI formatting
  String get formattedDate => DateFormat('MMM d, yyyy').format(createdAt);
  
  String get formattedTime => DateFormat('h:mm a').format(createdAt);
  
  String get formattedDateTime => DateFormat('MMM d, h:mm a').format(createdAt);
}