import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
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
        .neq('status', 'donated') // Filter out donated items
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
    String category = 'Other', // Added category parameter
  }) async {
    try {
      debugPrint('Adding item to database with restaurantId: $restaurantId');
      
      final insert = {
        'restaurant_id': restaurantId,
        'name': name,
        'quantity': quantity,
        'expiry_date': expiryDate.toIso8601String().split('T')[0],
        'status': status,
        'category': category, // Re-enabled now that database will have this column
      };
      
      debugPrint('Insert data: $insert');
      
      final data = await _client
          .from('inventory_items')
          .insert(insert)
          .select()
          .single();
      
      debugPrint('Database response: $data');
      
      return InventoryItem.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('Error in addItem: $e');
      rethrow;
    }
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
    final data = await _client
        .from('donations')
        .insert(payload)
        .select('*, profiles!donations_restaurant_id_fkey(*)')
        .single();
    return Donation.fromJson(Map<String, dynamic>.from(data));
  }
}

