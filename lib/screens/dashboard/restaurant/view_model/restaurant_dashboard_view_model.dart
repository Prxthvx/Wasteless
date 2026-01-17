import 'package:flutter/foundation.dart';
import '../../../../models/inventory_item.dart';
import '../../../../models/donation.dart';
import '../../../../services/repositories/inventory_repository.dart';
import '../../../../services/repositories/donation_repository.dart';

class RestaurantDashboardViewModel extends ChangeNotifier {
  final InventoryRepository _inventoryRepo;
  final DonationRepository _donationRepo;

  RestaurantDashboardViewModel({
    InventoryRepository? inventoryRepository,
    DonationRepository? donationRepository,
  })  : _inventoryRepo = inventoryRepository ?? InventoryRepository(),
        _donationRepo = donationRepository ?? DonationRepository();

  /// State
  bool isLoading = true;
  List<InventoryItem> inventory = [];
  List<Donation> donations = [];

  /// Entry point used by the dashboard
  Future<void> loadData({
    required String restaurantId,
    required bool isDemo,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      if (isDemo) {
        await Future.delayed(const Duration(milliseconds: 500));
        inventory = _getMockInventory(restaurantId);
        donations = _getMockDonations(restaurantId);
      } else {
        inventory = await _inventoryRepo.listInventory(restaurantId);
        donations = await _donationRepo.listMyRestaurantDonations(restaurantId);
      }
      calculateAnalytics();
    } catch (e) {
      debugPrint('[RestaurantDashboardViewModel] loadData error: $e');
      rethrow; // UI decides what to do
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> analytics = {
  'totalWasteSaved': 0,
  'donationsMade': 0,
  'peopleHelped': 0,
  'costSavings': 0,
  'expiringSoon': 0,
  };

  void calculateAnalytics() {
  double totalWasteSaved = 0;
  int donationsMade = donations.length;
  int peopleHelped = 0;
  double costSavings = 0;
  int expiringSoon = 0;

  // Calculate waste saved from donations
  for (final donation in donations) {
    final quantityStr =
        donation.quantity.replaceAll(RegExp(r'[^\d.]'), '');
    final quantity = double.tryParse(quantityStr) ?? 0.0;

    totalWasteSaved += quantity;
    peopleHelped += (quantity / 2).round();
    costSavings += quantity * 2.5;
  }

  // Calculate items expiring soon (within 3 days)
  final now = DateTime.now();
  for (final item in inventory) {
    final daysUntilExpiry = item.expiryDate.difference(now).inDays;
    if (daysUntilExpiry <= 3 && daysUntilExpiry >= 0) {
      expiringSoon++;
    }
  }

  // Estimated savings from recipes
  totalWasteSaved += inventory.length * 0.5;

  analytics = {
    'totalWasteSaved': totalWasteSaved.round(),
    'donationsMade': donationsMade,
    'peopleHelped': peopleHelped,
    'costSavings': costSavings.round(),
    'expiringSoon': expiringSoon,
  };

  notifyListeners();
  }



  /// TEMP mock data (will move later)
  List<InventoryItem> _getMockInventory(String restaurantId) {
    return [
      InventoryItem(
        id: '1',
        restaurantId: restaurantId,
        name: 'Fresh Tomatoes',
        quantity: '15 kg',
        category: 'Vegetables',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        status: 'available',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      InventoryItem(
        id: '2',
        restaurantId: restaurantId,
        name: 'Bread Loaves',
        quantity: '20 units',
        category: 'Bread & Pastries',
        expiryDate: DateTime.now().add(const Duration(days: 1)),
        status: 'available',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  List<Donation> _getMockDonations(String restaurantId) {
    return [
      Donation(
        id: '1',
        restaurantId: restaurantId,
        title: 'Fresh Vegetables',
        description: 'Assorted fresh vegetables',
        quantity: '25 kg',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        status: 'available',
        postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  Future<InventoryItem> addInventoryItem({
    required String restaurantId,
    required String name,
    required String quantity,
    required DateTime expiryDate,
    required String status,
    required String category,
    }) async {
    final savedItem = await _inventoryRepo.addItem(
      restaurantId: restaurantId,
      name: name,
      quantity: quantity,
      expiryDate: expiryDate,
      status: status,
      category: category,
    );

    // Keep local state in sync
    inventory.add(savedItem);
    notifyListeners();

    return savedItem;
  }

  Future<Donation?> addDonation({
    required String restaurantId,
    required String title,
    String? description,
    required String quantity,
    required DateTime expiryDate,
      }) async {
    final savedDonation = await _donationRepo.postDonation(
      restaurantId: restaurantId,
      title: title,
      description: description,
      quantity: quantity,
      expiryDate: expiryDate,
    );

    // Keep local state in sync
    if (savedDonation != null) {
          donations.insert(0, savedDonation);
          notifyListeners();
    }

    return savedDonation;
  }

  Future<void> deleteInventoryItem({
    required String itemId,
    required String restaurantId,
    required bool isDemo,
    }) async {
    if (!isDemo) {
      await _inventoryRepo.deleteItem(itemId);
    }

    // Keep local state in sync regardless of demo/real
    inventory.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  Future<InventoryItem> updateInventoryItem({
  required String itemId,
  required String name,
  required String quantity,
  required String category,
  required DateTime expiryDate,
  required String status,
}) async {
  final updatedItem = await _inventoryRepo.updateItem(
    itemId,
    {
      'name': name,
      'quantity': quantity,
      'category': category,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'status': status,
    },
  );

  // Keep local state in sync
  final index = inventory.indexWhere((item) => item.id == itemId);
  if (index != -1) {
    inventory[index] = updatedItem;
    notifyListeners();
  }

  return updatedItem;
}

}
