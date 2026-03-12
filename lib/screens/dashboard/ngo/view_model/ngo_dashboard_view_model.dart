import '../../../../models/donation.dart';
import '../../../../services/repositories/donation_repository.dart';
import '../../helpers/analytics_helper.dart';

class NGODashboardViewModel {

  final DonationRepository _donationRepo ;

  NGODashboardViewModel(this._donationRepo);

  bool isLoading = true;

  List<Donation> availableDonations = [];
  List<Donation> claimedDonations = [];
  Map<String, int> monthlyClaimsData = {};

  Map<String, dynamic> analytics = {
    'totalDonationsClaimed': 0,
    'peopleHelped': 0,
    'foodRescued': 0,
    'activeClaims': 0,
    'restaurantsConnected': 0,
  };

  Future<void> loadData(String userId, {bool isDemo = false}) async {
    isLoading = true;

    if(isDemo){
      await Future.delayed(const Duration(milliseconds: 500));
      availableDonations = _getMockAvailableDonations();
      claimedDonations = _getMockClaimedDonations(userId);
      monthlyClaimsData = _getMockMonthlyClaimsData();
    }
    else {
      availableDonations = await _donationRepo.listAvailableDonations();
      claimedDonations = await _donationRepo.listMyClaimedDonations(userId);
      monthlyClaimsData = await _donationRepo.getMonthlyClaimsStatistics(userId);
    }

    analytics = AnalyticsHelper.calculateAnalytics(claimedDonations);
    isLoading = false;
  }

  List<Donation> _getMockAvailableDonations() {
    return [
      Donation(
        id: '1',
        restaurantId: 'restaurant-1',
        title: 'Fresh Vegetables',
        description: 'Assorted fresh vegetables from today\'s delivery',
        quantity: '25 kg',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        status: 'available',
        postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Donation(
        id: '2',
        restaurantId: 'restaurant-2',
        title: 'Bread and Pastries',
        description: 'Fresh bread and pastries from local bakery',
        quantity: '15 kg',
        expiryDate: DateTime.now().add(const Duration(days: 1)),
        status: 'available',
        postedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Donation(
        id: '3',
        restaurantId: 'restaurant-3',
        title: 'Fruits and Dairy',
        description: 'Mixed fruits and dairy products',
        quantity: '20 kg',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        status: 'available',
        postedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  List<Donation> _getMockClaimedDonations(String userId) {
    return [
      Donation(
        id: '4',
        restaurantId: 'restaurant-4',
        title: 'Canned Goods',
        description: 'Various canned food items',
        quantity: '30 kg',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        status: 'claimed',
        postedAt: DateTime.now().subtract(const Duration(days: 1)),
        claimedBy: userId,
        claimedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  Map<String, int> _getMockMonthlyClaimsData() {
    final now = DateTime.now();
    return {
      '${now.year}-${(now.month - 5).toString().padLeft(2, '0')}': 3,
      '${now.year}-${(now.month - 4).toString().padLeft(2, '0')}': 5,
      '${now.year}-${(now.month - 3).toString().padLeft(2, '0')}': 8,
      '${now.year}-${(now.month - 2).toString().padLeft(2, '0')}': 6,
      '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}': 10,
      '${now.year}-${now.month.toString().padLeft(2, '0')}': 7,
    };
  }

  void claimDonation({
    required Donation donation,
    required String userId,
    }) {
      // Check if donation is expired before claiming
      if (donation.expiryDate.isBefore(DateTime.now())) {
        throw Exception('Cannot claim expired donation');
      }
      
      // Check local state as a preliminary check (backend will be source of truth)
      final alreadyClaimed = claimedDonations.any((d) => d.id == donation.id);
      if (alreadyClaimed) 
       {
        throw Exception('Donation already claimed locally');
       }
    // Remove from available list
    availableDonations.removeWhere((d) => d.id == donation.id);

    // Add to claimed list
    claimedDonations.add(
      Donation(
        id: donation.id,
        restaurantId: donation.restaurantId,
        title: donation.title,
        description: donation.description,
        quantity: donation.quantity,
        expiryDate: donation.expiryDate,
        status: 'claimed',
        postedAt: donation.postedAt,
        claimedBy: userId,
        claimedAt: DateTime.now(),
        restaurantProfile: donation.restaurantProfile,
      ),
    );

    // Recalculate analytics
    analytics = AnalyticsHelper.calculateAnalytics(claimedDonations);
  }

  void rollbackClaim({required Donation donation}) {
    // Remove from claimed list if claim failed
    claimedDonations.removeWhere((d) => d.id == donation.id);
    
    // Add back to available list
    availableDonations.add(donation);
    
    // Recalculate analytics
    analytics = AnalyticsHelper.calculateAnalytics(claimedDonations);
  }

  void markClaimComplete(Donation donation) {
    final index = claimedDonations.indexWhere((d) => d.id == donation.id);
    if (index == -1) return;

    claimedDonations[index] = Donation(
      id: donation.id,
      restaurantId: donation.restaurantId,
      title: donation.title,
      description: donation.description,
      quantity: donation.quantity,
      expiryDate: donation.expiryDate,
      status: 'completed',
      postedAt: donation.postedAt,
      claimedBy: donation.claimedBy,
      claimedAt: donation.claimedAt,
      completedAt: DateTime.now(),
      restaurantProfile: donation.restaurantProfile,
    );

    // Keep analytics in sync
    analytics = AnalyticsHelper.calculateAnalytics(claimedDonations);
  }
}