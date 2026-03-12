import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import '../../models/donation.dart';

class DonationRepository {
  final SupabaseClient _client;

  DonationRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<Donation>> listAvailableDonations() async {
    try {
      // Fetch all donation IDs that have active claims in donation_claims
      final activeClaims = await _client
          .from('donation_claims')
          .select('donation_id')
          .neq('status', 'cancelled')
          .neq('status', 'rejected');

      final claimedDonationIds = (activeClaims as List)
          .map((e) => (e as Map<String, dynamic>)['donation_id'] as String)
          .toSet();

      debugPrint('[DonationRepository] Found ${claimedDonationIds.length} actively claimed donations to exclude');

      // Fetch available, non-expired donations
      final data = await _client
          .from('donations')
          .select('*, profiles!donations_restaurant_id_fkey(*)')
          .eq('status', 'available')
          .gte('expiry_date', DateTime.now().toIso8601String().split('T')[0])
          .order('created_at', ascending: false);

      // Exclude donations that have active claims
      final availableDonations = (data as List)
          .where((e) => !claimedDonationIds.contains((e as Map<String, dynamic>)['id']))
          .map((e) {
            try {
              return Donation.fromJson(Map<String, dynamic>.from(e));
            } catch (err, stackTrace) {
              debugPrint('[DonationRepository] Error parsing donation: $e');
              debugPrint('Error: $err');
              debugPrint('Stack trace: $stackTrace');
              return null;
            }
          })
          .whereType<Donation>()
          .toList();

      debugPrint('[DonationRepository] Fetched ${availableDonations.length} available donations');
      return availableDonations;
    } catch (e, stackTrace) {
      debugPrint('[DonationRepository] Error fetching donations: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Donation>> listMyRestaurantDonations(String restaurantId) async {
    final data = await _client
        .from('donations')
        .select('*, profiles!donations_restaurant_id_fkey(*)')
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Donation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<DonationClaim> claimDonation({
    required String donationId,
    required String ngoId,
    String? claimMessage,
  }) async {
    debugPrint('[DonationRepository] Attempting to claim donation $donationId for NGO $ngoId');

    // Step 1: Verify the donation exists, is available and not expired
    final donation = await _client
        .from('donations')
        .select()
        .eq('id', donationId)
        .single();

    final status = donation['status'] as String;
    final expiryDateStr = donation['expiry_date'] as String;
    final expiryDate = DateTime.parse(expiryDateStr);

    debugPrint('[DonationRepository] Donation status: $status, expiry: $expiryDateStr');

    if (status == 'completed' || status == 'cancelled') {
      throw Exception('Donation is no longer available. Status: $status');
    }

    if (expiryDate.isBefore(DateTime.now())) {
      throw Exception('Donation has expired');
    }

    // Step 2: Check if this NGO already has an active claim on this donation
    final existingClaims = await _client
        .from('donation_claims')
        .select()
        .eq('donation_id', donationId)
        .eq('ngo_id', ngoId)
        .neq('status', 'cancelled')
        .neq('status', 'rejected');

    if ((existingClaims as List).isNotEmpty) {
      debugPrint('[DonationRepository] NGO already has a claim on this donation');
      throw Exception('You have already claimed this donation');
    }

    // Step 3: Check if the donation is already claimed by another NGO
    final otherClaims = await _client
        .from('donation_claims')
        .select()
        .eq('donation_id', donationId)
        .neq('ngo_id', ngoId)
        .neq('status', 'cancelled')
        .neq('status', 'rejected');

    if ((otherClaims as List).isNotEmpty) {
      debugPrint('[DonationRepository] Donation already claimed by another NGO');
      throw Exception('Donation has already been claimed');
    }

    // Step 4: Insert claim record into donation_claims
    // Note: NGOs do not have UPDATE permission on the donations table (RLS policy).
    // The donations table status is managed by the restaurant side.
    try {
      final payload = {
        'donation_id': donationId,
        'ngo_id': ngoId,
        if (claimMessage != null) 'claim_message': claimMessage,
        'status': 'claimed',
      };

      debugPrint('[DonationRepository] Inserting claim record');
      final data = await _client
          .from('donation_claims')
          .insert(payload)
          .select()
          .single();

      debugPrint('[DonationRepository] Claim successful: $data');
      return DonationClaim.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('[DonationRepository] Error inserting claim: $e');
      rethrow;
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
          debugPrint('[DonationRepository] Error parsing claimed donation: $donationData\nError: $err');
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

  Future<Donation> postDonation({
    required String restaurantId,
    required String inventoryItemId,
    required String title,
    String? description,
    required String quantity,
    required DateTime expiryDate,
  }) async {
    // Step 1: Update inventory item status to 'donated'
    await _client
        .from('inventory_items')
        .update({
          'status': 'donated',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', inventoryItemId);

    // Step 2: Create donation (without inventory_item_id since the database doesn't have this column)
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
          .select('*, profiles!donations_restaurant_id_fkey(*)')
          .single();
      debugPrint('[DonationRepository] Donation created: $data');
      try {
        return Donation.fromJson(Map<String, dynamic>.from(data));
      } catch (err) {
        debugPrint('[DonationRepository] Error parsing created donation: $data\nError: $err');
        throw Exception('Failed to parse created donation: $err');
      }
    } catch (e) {
      debugPrint('[DonationRepository] Error creating donation: $e');
      throw Exception('Failed to create donation: $e');
    }
  }

  /// Verify if a donation is still available and not expired
  Future<bool> isDonationAvailable(String donationId) async {
    try {
      final donation = await _client
          .from('donations')
          .select('status, expiry_date')
          .eq('id', donationId)
          .single();
      
      final status = donation['status'] as String;
      final expiryDateStr = donation['expiry_date'] as String;
      final expiryDate = DateTime.parse(expiryDateStr);
      
      return status == 'available' && expiryDate.isAfter(DateTime.now());
    } catch (e) {
      debugPrint('[DonationRepository] Error checking donation availability: $e');
      return false;
    }
  }

  /// Get monthly donation claims statistics for an NGO
  /// Returns a map with month-year keys and claim counts
  Future<Map<String, int>> getMonthlyClaimsStatistics(String ngoId, {int monthsBack = 6}) async {
    try {
      // Calculate date range
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - monthsBack, 1);
      
      debugPrint('[DonationRepository] Fetching monthly claims from $startDate for NGO $ngoId');

      // Fetch all claims for this NGO within the date range
      final claims = await _client
          .from('donation_claims')
          .select('claimed_at')
          .eq('ngo_id', ngoId)
          .gte('claimed_at', startDate.toIso8601String())
          .order('claimed_at', ascending: true);

      debugPrint('[DonationRepository] Fetched ${(claims as List).length} claims');

      // Group claims by month
      final Map<String, int> monthlyStats = {};
      
      // Initialize all months with 0
      for (int i = 0; i <= monthsBack; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyStats[key] = 0;
      }

      // Count claims per month
      for (final claim in claims) {
        final claimedAtStr = claim['claimed_at'] as String;
        final claimedAt = DateTime.parse(claimedAtStr);
        final key = '${claimedAt.year}-${claimedAt.month.toString().padLeft(2, '0')}';
        monthlyStats[key] = (monthlyStats[key] ?? 0) + 1;
      }

      debugPrint('[DonationRepository] Monthly stats: $monthlyStats');
      return monthlyStats;
    } catch (e, stackTrace) {
      debugPrint('[DonationRepository] Error fetching monthly statistics: $e');
      debugPrint('Stack trace: $stackTrace');
      return {};
    }
  }
}