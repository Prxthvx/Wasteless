import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/inventory_item.dart';
import '../../models/donation.dart';

class InventoryRepository {
  final SupabaseClient _client;

  InventoryRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<InventoryItem>> listMyItems(String userId) async {
    final data = await _client
        .from('inventory_items')
        .select()
        .eq('owner_id', userId)
        .order('expiry_date', ascending: true, nullsFirst: true);
    return (data as List).map((e) => InventoryItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<InventoryItem> addItem({
    required String ownerId,
    required String name,
    required double quantity,
    required String unit,
    DateTime? expiryDate,
    String? notes,
  }) async {
    final insert = {
      'owner_id': ownerId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
    };
    final data = await _client
        .from('inventory_items')
        .insert(insert)
        .select()
        .single();
    return InventoryItem.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteItem(String itemId) async {
    await _client.from('inventory_items').delete().eq('id', itemId);
  }

  Future<InventoryItem> updateQuantity(String itemId, double newQuantity) async {
    final data = await _client
        .from('inventory_items')
        .update({'quantity': newQuantity})
        .eq('id', itemId)
        .select()
        .single();
    return InventoryItem.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Donation> postDonation({
    required String restaurantId,
    required String itemName,
    required double quantity,
    required String unit,
    required String pickupLocation,
    DateTime? bestBefore,
    String? notes,
  }) async {
    final payload = {
      'restaurant_id': restaurantId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'pickup_location': pickupLocation,
      'best_before': bestBefore?.toIso8601String(),
      'notes': notes,
    };
    final data = await _client.from('donations').insert(payload).select().single();
    return Donation.fromJson(Map<String, dynamic>.from(data));
  }
}
