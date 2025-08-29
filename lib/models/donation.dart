class Donation {
  final String id;
  final String restaurantId;
  final String itemName;
  final double quantity;
  final String unit;
  final String pickupLocation;
  final DateTime? bestBefore;
  final String? notes;
  final String status; // available, claimed, completed, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  Donation({
    required this.id,
    required this.restaurantId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.pickupLocation,
    required this.bestBefore,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      itemName: json['item_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      pickupLocation: json['pickup_location'] as String,
      bestBefore: json['best_before'] != null ? DateTime.parse(json['best_before'] as String) : null,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'restaurant_id': restaurantId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'pickup_location': pickupLocation,
      'best_before': bestBefore?.toIso8601String(),
      'notes': notes,
    };
  }
}

class DonationClaim {
  final String id;
  final String donationId;
  final String ngoId;
  final String claimStatus; // pending, approved, rejected, picked_up, cancelled
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  DonationClaim({
    required this.id,
    required this.donationId,
    required this.ngoId,
    required this.claimStatus,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DonationClaim.fromJson(Map<String, dynamic> json) {
    return DonationClaim(
      id: json['id'] as String,
      donationId: json['donation_id'] as String,
      ngoId: json['ngo_id'] as String,
      claimStatus: json['claim_status'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'donation_id': donationId,
      'ngo_id': ngoId,
      'claim_status': claimStatus,
      'message': message,
    };
  }
}
