import 'user_profile.dart';

class Donation {
  final String id;
  final String? inventoryItemId;
  final String restaurantId;
  final String title;
  final String? description;
  final String quantity;
  final DateTime expiryDate;
  final String status;
  final DateTime postedAt;
  final String? claimedBy; // NGO ID
  final DateTime? claimedAt;
  final String? claimMessage;
  final DateTime? completedAt;
  final UserProfile? restaurantProfile;

  Donation({
    required this.id,
    this.inventoryItemId,
    required this.restaurantId,
    required this.title,
    this.description,
    required this.quantity,
    required this.expiryDate,
    required this.status,
    required this.postedAt,
    this.claimedBy,
    this.claimedAt,
    this.claimMessage,
    this.completedAt,
    this.restaurantProfile,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    try {
      return Donation(
        id: json['id'] as String,
        inventoryItemId: json['inventory_item_id'] as String?,
        restaurantId: json['restaurant_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        quantity: json['quantity'] as String,
        expiryDate: DateTime.parse(json['expiry_date'] as String),
        status: json['status'] as String,
        postedAt: DateTime.parse(json['posted_at'] as String),
        claimedBy: json['claimed_by'] as String?,
        claimedAt: json['claimed_at'] != null
            ? DateTime.parse(json['claimed_at'] as String)
            : null,
        claimMessage: json['claim_message'] as String?,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        restaurantProfile: json['profiles'] != null ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>) : null,
      );
    } catch (e) {
      print('[Donation.fromJson] Error parsing donation: $json\nError: $e');
      throw FormatException('Error parsing Donation: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'restaurant_id': restaurantId,
      'title': title,
      'description': description,
      'quantity': quantity,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'status': status,
      'posted_at': postedAt.toIso8601String(),
      'claimed_by': claimedBy,
      'claimed_at': claimedAt?.toIso8601String(),
      'claim_message': claimMessage,
      'completed_at': completedAt?.toIso8601String(),
      'profiles': restaurantProfile?.toJson(),
    };
  }
}

class DonationClaim {
  final String id;
  final String donationId;
  final String ngoId;
  final String? claimMessage;
  final String status;
  final DateTime claimedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;

  DonationClaim({
    required this.id,
    required this.donationId,
    required this.ngoId,
    this.claimMessage,
    required this.status,
    required this.claimedAt,
    this.approvedAt,
    this.rejectedAt,
  });

  factory DonationClaim.fromJson(Map<String, dynamic> json) {
    return DonationClaim(
      id: json['id'] as String,
      donationId: json['donation_id'] as String,
      ngoId: json['ngo_id'] as String,
      claimMessage: json['claim_message'] as String?,
      status: json['status'] as String,
      claimedAt: DateTime.parse(json['claimed_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donation_id': donationId,
      'ngo_id': ngoId,
      'claim_message': claimMessage,
      'status': status,
      'claimed_at': claimedAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
    };
  }
}

