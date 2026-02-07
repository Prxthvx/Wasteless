class MessageReadReceipt {
  final String id;
  final String messageId;
  final String userId;
  final DateTime readAt;

  MessageReadReceipt({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.readAt,
  });

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      readAt: DateTime.parse(json['read_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'read_at': readAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory MessageReadReceipt.fromMap(Map<String, dynamic> map) => 
      MessageReadReceipt.fromJson(map);
}