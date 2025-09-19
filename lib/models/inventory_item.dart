class InventoryItem {
  final String id;
  final String restaurantId;
  final String name;
  final String quantity;
  final String category;
  final DateTime expiryDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.quantity,
    required this.category,
    required this.expiryDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      category: json['category'] as String,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'quantity': quantity,
      'category': category,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

