import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/donation.dart';

class DonationRepository {
  final SupabaseClient _client;

  DonationRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<Donation>> listAvailableDonations() async {
    try {
      final data = await _client
          .from('donations')
          .select('*, profiles!donations_restaurant_id_fkey(*)')
          .eq('status', 'available')
          .order('created_at', ascending: false);
      print('[DonationRepository] Fetched donations: $data');
      return (data as List).map((e) {
        try {
          return Donation.fromJson(Map<String, dynamic>.from(e));
        } catch (err) {
          print('[DonationRepository] Error parsing donation: $e\nError: $err');
          return null;
        }
      }).whereType<Donation>().toList();
    } catch (e) {
      print('[DonationRepository] Error fetching donations: $e');
      return [];
    }
  }

  Future<List<Donation>> listMyRestaurantDonations(String restaurantId) async {
    try {
      final data = await _client
          .from('donations')
          .select('*, profiles!donations_restaurant_id_fkey(*)')
          .eq('restaurant_id', restaurantId)
          .order('posted_at', ascending: false);
      return (data as List).map((e) => Donation.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      print('[DonationRepository] Error listing restaurant donations: $e');
      return [];
    }
  }

  Future<DonationClaim?> claimDonation({
    required String donationId,
    required String ngoId,
    String? claimMessage,
  }) async {
    try {
      // Use a transaction to ensure both operations succeed or fail together
      final data = await _client.rpc('claim_donation_and_update_status', params: {
        'p_donation_id': donationId,
        'p_ngo_id': ngoId,
        'p_claim_message': claimMessage,
      });

      if (data != null) {
        // The RPC returns the created claim record as JSON.
        return DonationClaim.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('[DonationRepository] Error claiming donation: $e');
      return null;
    }
  }

  Future<List<DonationClaim>> listClaimsForDonation(String donationId) async {
    final data = await _client
        .from('donation_claims')
        .select()
        .eq('donation_id', donationId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => DonationClaim.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Donation>> listMyClaimedDonations(String ngoId) async {
    // Fetch claimed donations with nested joins for restaurant profile using correct join alias
    final claims = await _client
        .from('donation_claims')
        .select('*, donations(*, profiles!donations_restaurant_id_fkey(*))')
        .eq('ngo_id', ngoId);

    // Parse donations from nested claims
    final List<Donation> claimedDonations = [];
    for (final claim in claims as List) {
      final donationData = (claim as Map<String, dynamic>)['donations'];
      if (donationData != null) {
        try {
          claimedDonations.add(Donation.fromJson(Map<String, dynamic>.from(donationData)));
        } catch (err) {
          print('[DonationRepository] Error parsing claimed donation: $donationData\nError: $err');
        }
      }
    }
    return claimedDonations;
  }

  Future<void> updateDonationStatus({
    required String donationId,
    required String status,
    String? claimedBy,
    DateTime? claimedAt,
    String? claimMessage,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
    };
    if (claimedBy != null) updateData['claimed_by'] = claimedBy;
    if (claimedAt != null) updateData['claimed_at'] = claimedAt.toIso8601String();
    if (claimMessage != null) updateData['claim_message'] = claimMessage;
    await _client
        .from('donations')
        .update(updateData)
        .eq('id', donationId);
  }

  Future<Donation?> postDonation({
    required String restaurantId,
    required String title,
    String? description,
    required String quantity,
    required DateTime expiryDate,
  }) async {
    final payload = {
      'restaurant_id': restaurantId,
      'title': title,
      'description': description,
      'quantity': quantity,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'status': 'available',
    };
    try {
      final data = await _client
          .from('donations')
          .insert(payload)
          .select()
          .single();
      print('[DonationRepository] Donation created: $data');
      try {
        return Donation.fromJson(Map<String, dynamic>.from(data));
      } catch (err) {
        print('[DonationRepository] Error parsing created donation: $data\nError: $err');
        return null;
      }
    } catch (e) {
      print('[DonationRepository] Error creating donation: $e');
      return null;
    }
  }
}

