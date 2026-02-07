class ChatThread {
  final String id;
  final String restaurantId;
  final String ngoId;
  final String? donationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;

  ChatThread({
    required this.id,
    required this.restaurantId,
    required this.ngoId,
    this.donationId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      ngoId: json['ngo_id'] as String,
      donationId: json['donation_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'ngo_id': ngoId,
      'donation_id': donationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory ChatThread.fromMap(Map<String, dynamic> map) => ChatThread.fromJson(map);
}