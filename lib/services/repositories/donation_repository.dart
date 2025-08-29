import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/donation.dart';

class DonationRepository {
  final SupabaseClient _client;

  DonationRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<Donation>> listAvailableDonations() async {
    final data = await _client
        .from('donations')
        .select()
        .eq('status', 'available')
        .order('created_at', ascending: false);
    return (data as List).map((e) => Donation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Donation>> listMyRestaurantDonations(String restaurantId) async {
    final data = await _client
        .from('donations')
        .select()
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Donation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<DonationClaim> claimDonation({
    required String donationId,
    required String ngoId,
    String? message,
  }) async {
    final payload = {
      'donation_id': donationId,
      'ngo_id': ngoId,
      'message': message,
    };
    final data = await _client
        .from('donation_claims')
        .insert(payload)
        .select()
        .single();
    return DonationClaim.fromJson(Map<String, dynamic>.from(data));
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
    // Fetch donation_ids claimed by this NGO
    final claims = await _client
        .from('donation_claims')
        .select('donation_id')
        .eq('ngo_id', ngoId);

    final ids = (claims as List)
        .map((e) => (e as Map<String, dynamic>)['donation_id'])
        .whereType<String>()
        .toList();

    if (ids.isEmpty) return [];

    final data = await _client
        .from('donations')
        .select()
        .inFilter('id', ids)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Donation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Donation> updateDonationStatus(String donationId, String status) async {
    final data = await _client
        .from('donations')
        .update({'status': status})
        .eq('id', donationId)
        .select()
        .single();
    return Donation.fromJson(Map<String, dynamic>.from(data));
  }
}
