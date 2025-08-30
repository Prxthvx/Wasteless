import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/inventory_item.dart';
import '../../models/donation.dart';

class InventoryRepository {
  final SupabaseClient _client;

  InventoryRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<InventoryItem>> listInventory(String restaurantId) async {
    final data = await _client
        .from('inventory_items')
        .select()
        .eq('restaurant_id', restaurantId)
        .order('expiry_date', ascending: true);
    return (data as List).map((e) => InventoryItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<InventoryItem>> listMyItems(String userId) async {
    return listInventory(userId);
  }

  Future<InventoryItem> addItem({
    required String restaurantId,
    required String name,
    required String quantity,
    required DateTime expiryDate,
    String status = 'available',
  }) async {
    final insert = {
      'restaurant_id': restaurantId,
      'name': name,
      'quantity': quantity,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'status': status,
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

  Future<InventoryItem> updateItem(String itemId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('inventory_items')
        .update(updates)
        .eq('id', itemId)
        .select()
        .single();
    return InventoryItem.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Donation> postDonation({
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
    final data = await _client.from('donations').insert(payload).select().single();
    return Donation.fromJson(Map<String, dynamic>.from(data));
  }
}

