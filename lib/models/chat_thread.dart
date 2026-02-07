import 'package:flutter/foundation.dart';
import 'user_profile.dart';

class ChatThread {
  final String id;
  final String restaurantId;
  final String ngoId;
  final String? donationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;
  final UserProfile? restaurantProfile;
  final UserProfile? ngoProfile;

  ChatThread({
    required this.id,
    required this.restaurantId,
    required this.ngoId,
    this.donationId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    this.restaurantProfile,
    this.ngoProfile,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    debugPrint('[ChatThread] fromJson called with: ${json.keys}');
    debugPrint('[ChatThread] restaurant field: ${json['restaurant']}');
    debugPrint('[ChatThread] ngo field: ${json['ngo']}');

    // Parse restaurant profile if available
    UserProfile? restaurantProfile;
    if (json['restaurant'] != null) {
      try {
        restaurantProfile = UserProfile.fromJson(
          Map<String, dynamic>.from(json['restaurant']),
        );
        debugPrint(
          '[ChatThread] Successfully parsed restaurant profile: ${restaurantProfile.name}',
        );
      } catch (e, stackTrace) {
        debugPrint('[ChatThread] Error parsing restaurant profile: $e');
        debugPrint('[ChatThread] Stack trace: $stackTrace');
      }
    } else {
      debugPrint('[ChatThread] No restaurant field in JSON');
    }

    // Parse NGO profile if available
    UserProfile? ngoProfile;
    if (json['ngo'] != null) {
      try {
        ngoProfile = UserProfile.fromJson(
          Map<String, dynamic>.from(json['ngo']),
        );
        debugPrint(
          '[ChatThread] Successfully parsed NGO profile: ${ngoProfile.name}',
        );
      } catch (e, stackTrace) {
        debugPrint('[ChatThread] Error parsing NGO profile: $e');
        debugPrint('[ChatThread] Stack trace: $stackTrace');
      }
    } else {
      debugPrint('[ChatThread] No ngo field in JSON');
    }

    return ChatThread(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      ngoId: json['ngo_id'] as String,
      donationId: json['donation_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      restaurantProfile: restaurantProfile,
      ngoProfile: ngoProfile,
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
      if (restaurantProfile != null) 'restaurant': restaurantProfile!.toJson(),
      if (ngoProfile != null) 'ngo': ngoProfile!.toJson(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory ChatThread.fromMap(Map<String, dynamic> map) =>
      ChatThread.fromJson(map);

  // Helper methods to get display names
  String getRestaurantName() {
    return restaurantProfile?.orgName ??
        restaurantProfile?.name ??
        'Restaurant';
  }

  String getNgoName() {
    return ngoProfile?.orgName ?? ngoProfile?.name ?? 'NGO';
  }

  String getOtherUserName(String currentUserId) {
    if (currentUserId == restaurantId) {
      return getNgoName();
    } else {
      return getRestaurantName();
    }
  }
}
