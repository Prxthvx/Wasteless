import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/inventory_item.dart';
import '../../models/donation.dart';
import '../../services/repositories/inventory_repository.dart';
import '../../services/repositories/donation_repository.dart';
import '../../services/supabase_service.dart';
import '../../services/recipe_api_service.dart';
import '../scanner_screen.dart';
import '../../services/barcode_lookup_service.dart';

class RestaurantDashboard extends StatefulWidget {
  final UserProfile profile;
  
  const RestaurantDashboard({super.key, required this.profile});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final DonationRepository _donationRepo = DonationRepository();
  
  List<InventoryItem> _inventory = [];
  List<Donation> _donations = [];
  bool _isLoading = true;

  Map<String, dynamic> _analytics = {
    'totalWasteSaved': 0,
    'donationsMade': 0,
    'peopleHelped': 0,
    'costSavings': 0,
    'expiringSoon': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.profile.id == 'demo-user-id') {
        await Future.delayed(const Duration(milliseconds: 500));
        _inventory = _getMockInventory();
        _donations = _getMockDonations();
      } else {
        _inventory = await _inventoryRepo.listInventory(widget.profile.id);
        _donations = await _donationRepo.listMyRestaurantDonations(widget.profile.id);
      }
      
      // Calculate real-time analytics
      _calculateAnalytics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateAnalytics() {
    // Calculate waste saved based on donations and inventory usage
    double totalWasteSaved = 0;
    int donationsMade = _donations.length;
    int peopleHelped = 0;
    double costSavings = 0;
    int expiringSoon = 0;

    // Calculate waste saved from donations
    for (final donation in _donations) {
      // Parse quantity string to double (assuming format like "5 kg" or "10")
      final quantityStr = donation.quantity.replaceAll(RegExp(r'[^\d.]'), ''); // Remove non-numeric chars except decimal
      final quantity = double.tryParse(quantityStr) ?? 0.0;
      
      totalWasteSaved += quantity;
      peopleHelped += (quantity / 2).round(); // Estimate people helped
      costSavings += quantity * 2.5; // Estimate $2.5 per kg saved
    }

    // Calculate items expiring soon (within 3 days)
    final now = DateTime.now();
    for (final item in _inventory) {
      final daysUntilExpiry = item.expiryDate.difference(now).inDays;
      if (daysUntilExpiry <= 3 && daysUntilExpiry >= 0) {
        expiringSoon++;
      }
    }

    // Add some waste saved from recipe generation (estimated)
    totalWasteSaved += _inventory.length * 0.5; // Estimate 0.5kg saved per item through recipes

    setState(() {
      _analytics = {
        'totalWasteSaved': totalWasteSaved.round(),
        'donationsMade': donationsMade,
        'peopleHelped': peopleHelped,
        'costSavings': costSavings.round(),
        'expiringSoon': expiringSoon,
      };
    });
  }

  List<InventoryItem> _getMockInventory() {
    return [
      InventoryItem(
        id: '1',
        restaurantId: widget.profile.id,
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
        restaurantId: widget.profile.id,
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

  List<Donation> _getMockDonations() {
    return [
      Donation(
        id: '1',
        restaurantId: widget.profile.id,
        title: 'Fresh Vegetables',
        description: 'Assorted fresh vegetables',
        quantity: '25 kg',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        status: 'available',
        postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.profile.name} Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.favorite), text: 'Donations'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Recipes'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildInventoryTab(),
          _buildDonationsTab(),
          _buildRecipesTab(),
          _buildAnalyticsTab(),
        ],
      ),
      drawer: _buildDrawer(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final expiringSoon = _inventory.where((item) => item.expiryDate.difference(DateTime.now()).inDays <= 2).length;
    final totalInventory = _inventory.length;
    final activeDonations = _donations.where((d) => d.status == 'available').length;
    final totalDonations = _donations.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.recycling,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, ${widget.profile.name}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'You\'re making a difference in reducing food waste.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildQuickStat('Total Items', '$totalInventory', Icons.inventory),
                        const SizedBox(width: 16),
                        _buildQuickStat('Active Donations', '$activeDonations', Icons.favorite),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildClickableStatCard('Items Expiring Soon', '$expiringSoon', Icons.warning, Colors.orange, () => _tabController.animateTo(1)), // Navigate to Inventory
              _buildClickableStatCard('Active Donations', '$activeDonations', Icons.favorite, Colors.red, () => _tabController.animateTo(2)), // Navigate to Donations
              _buildClickableStatCard('Total Inventory', '$totalInventory', Icons.inventory, Colors.blue, () => _tabController.animateTo(1)), // Navigate to Inventory
              _buildClickableStatCard('Total Donations', '$totalDonations', Icons.volunteer_activism, Colors.purple, () => _tabController.animateTo(2)), // Navigate to Donations
            ],
          ),
          const SizedBox(height: 20),

          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildRecentActivityCard(),
          const SizedBox(height: 20),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final recentItems = _inventory.take(3).toList();
    final recentDonations = _donations.take(2).toList();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _tabController.animateTo(1), // Navigate to Inventory
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentItems.isEmpty && recentDonations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recent activity. Start by adding inventory items!',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              // Show recent inventory items
              if (recentItems.isNotEmpty) ...[
                Text(
                  'Recent Inventory Items',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...recentItems.map((item) => InkWell(
                  onTap: () => _tabController.animateTo(1), // Navigate to Inventory
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.inventory, size: 16, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${item.quantity} • Expires in ${item.expiryDate.difference(DateTime.now()).inDays} days',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                )).toList(),
              ],
              
              // Show recent donations
              if (recentDonations.isNotEmpty) ...[
                if (recentItems.isNotEmpty) const SizedBox(height: 16),
                Text(
                  'Recent Donations',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...recentDonations.map((donation) => InkWell(
                  onTap: () => _tabController.animateTo(2), // Navigate to Donations
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.red.shade100,
                          child: Icon(Icons.favorite, size: 16, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donation.title,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${donation.quantity} • ${donation.status}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                )).toList(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Add Item',
                    Icons.add,
                    Colors.green,
                    () => _showAddItemDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'View Donations',
                    Icons.favorite,
                    Colors.red,
                    () => _tabController.animateTo(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                  'Generate Recipes',
                  Icons.restaurant_menu,
                  Colors.orange,
                  () => _tabController.animateTo(3), // Navigate to Recipes
                ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'View Analytics',
                    Icons.analytics,
                    Colors.purple,
                    () => _tabController.animateTo(4), // Navigate to Analytics
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildInventoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_inventory.any((item) => item.expiryDate.difference(DateTime.now()).inDays <= 2))
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_inventory.where((item) => item.expiryDate.difference(DateTime.now()).inDays <= 2).length} items expiring soon!',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inventory.length,
              itemBuilder: (context, index) {
                final item = _inventory[index];
                final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: daysUntilExpiry <= 2 ? Colors.orange : Colors.green,
                      child: Icon(
                        daysUntilExpiry <= 2 ? Icons.warning : Icons.inventory,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity: ${item.quantity}'),
                        Text(
                          'Category: ${item.category}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Expires: ${item.expiryDate.toString().split(' ')[0]} (${daysUntilExpiry} days)',
                          style: TextStyle(
                            color: daysUntilExpiry <= 2 ? Colors.orange : Colors.grey[600],
                            fontWeight: daysUntilExpiry <= 2 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'donate',
                          child: Text('Post as Donation'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (value) => _handleInventoryAction(value, item),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    try {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Donations: ${_donations.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Active: ${_donations.where((d) => d.status == 'available').length}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _donations.length,
                itemBuilder: (context, index) {
                  try {
                    final donation = _donations[index];
                    // Defensive: handle nulls and log
                    if (donation == null) {
                      debugPrint('Donation at index $index is null');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('Error: Donation data missing', style: TextStyle(color: Colors.red)),
                        ),
                      );
                    }
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getDonationStatusColor(donation.status ?? ''),
                          child: Icon(
                            _getDonationStatusIcon(donation.status ?? ''),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(donation.title ?? 'No Title'),
                        subtitle: Text('Quantity: ${donation.quantity ?? 'N/A'}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                          ],
                          onSelected: (value) => _handleDonationAction(value, donation),
                        ),
                      ),
                    );
                  } catch (e, stack) {
                    debugPrint('Error rendering donation card at index $index: $e\n$stack');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('Error displaying donation', style: TextStyle(color: Colors.red)),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      );
    } catch (e, stack) {
      debugPrint('Error displaying donations tab: $e\n$stack');
      return Center(
        child: Text('Error displaying donations. Please try again later.', style: TextStyle(color: Colors.red)),
      );
    }
  }

  Widget _buildRecipesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean Professional Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.purple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Recipe Generator',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Generate professional recipes from your inventory',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Inventory-based Recipe Generation
          _buildInventoryRecipeGenerator(),
          const SizedBox(height: 32),
          
          // Multi-Ingredient Recipe Generator
          _buildMultiIngredientGenerator(),
        ],
      ),
    );
  }

  Widget _buildInventoryRecipeGenerator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Generate Recipe from Inventory',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select an item from your inventory to generate a professional recipe:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _inventory.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No inventory items available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add some items to your inventory first',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _inventory.length,
                  itemBuilder: (context, index) {
                    final item = _inventory[index];
                    final isExpiring = item.expiryDate.difference(DateTime.now()).inDays <= 2;
                    
                    return GestureDetector(
                      onTap: () => _showRecipeGenerationDialog(item),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isExpiring ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isExpiring ? Colors.orange : Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(item.category),
                                  color: isExpiring ? Colors.orange : Colors.grey[600],
                                  size: 20,
                                ),
                                const Spacer(),
                                if (isExpiring)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'URGENT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity} • ${item.category}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  color: Colors.purple,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Get Recipe',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMultiIngredientGenerator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Multi-Ingredient Recipe Generator',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Generate complex recipes using multiple ingredients from your inventory:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _inventory.length >= 2 ? _showAdvancedRecipeDialog : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Multi-Ingredient Recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_inventory.length < 2) ...[
            const SizedBox(height: 12),
            Text(
              'Add at least 2 items to your inventory to use this feature',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickRecipeGenerator() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'Generate Recipe from Your Inventory',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_inventory.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Add inventory items to get AI recipe suggestions',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Text(
                    'Select items from your inventory to generate a recipe:',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _inventory.take(6).map((item) {
                      return FilterChip(
                        label: Text(item.name),
                        selected: false,
                        onSelected: (selected) {
                          _showRecipeGenerationDialog(item);
                        },
                        avatar: Icon(
                          _getCategoryIcon(item.category),
                          size: 16,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAdvancedRecipeDialog(),
                      icon: Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text('Generate Smart Recipe', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringItemsRecipes() {
    final expiringItems = _inventory.where((item) => 
      item.expiryDate.difference(DateTime.now()).inDays <= 2
    ).toList();

    if (expiringItems.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green[400]),
              const SizedBox(height: 8),
              Text(
                'Great! No items expiring soon.',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: expiringItems.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Icon(Icons.warning, color: Colors.orange),
            ),
            title: Text(item.name),
            subtitle: Text('Expires in ${item.expiryDate.difference(DateTime.now()).inDays} days'),
            trailing: ElevatedButton(
              onPressed: () => _showRecipeForItem(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Get Recipe'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPopularRecipes() {
    final popularRecipes = [
      {
        'name': 'Zero-Waste Vegetable Soup',
        'rating': 4.8,
        'time': '30 min',
        'difficulty': 'Easy',
        'ingredients': ['Any vegetables', 'Onions', 'Garlic', 'Stock'],
        'description': 'Perfect for using up leftover vegetables',
      },
      {
        'name': 'Stale Bread Pudding',
        'rating': 4.6,
        'time': '45 min',
        'difficulty': 'Easy',
        'ingredients': ['Stale bread', 'Eggs', 'Milk', 'Sugar', 'Cinnamon'],
        'description': 'Transform stale bread into a delicious dessert',
      },
      {
        'name': 'Fruit Compote',
        'rating': 4.7,
        'time': '20 min',
        'difficulty': 'Easy',
        'ingredients': ['Overripe fruits', 'Sugar', 'Lemon juice'],
        'description': 'Use overripe fruits to make a sweet compote',
      },
    ];

    return Column(
      children: popularRecipes.map((recipe) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(' ${recipe['rating']}'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recipe['description'] as String,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRecipeTag('${recipe['time']}', Icons.access_time, Colors.blue),
                    const SizedBox(width: 8),
                    _buildRecipeTag('${recipe['difficulty']}', Icons.speed, Colors.green),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showRecipeDetail(recipe),
                      child: Text('View Recipe'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWasteReductionTips() {
    final tips = [
      {
        'title': 'First In, First Out (FIFO)',
        'description': 'Use older inventory items before newer ones to prevent spoilage.',
        'icon': Icons.swap_horiz,
        'color': Colors.blue,
      },
      {
        'title': 'Portion Control',
        'description': 'Prepare smaller portions to reduce leftover waste.',
        'icon': Icons.scale,
        'color': Colors.green,
      },
      {
        'title': 'Creative Leftovers',
        'description': 'Transform yesterday\'s meals into new dishes.',
        'icon': Icons.restaurant,
        'color': Colors.orange,
      },
      {
        'title': 'Smart Storage',
        'description': 'Store items properly to extend their shelf life.',
        'icon': Icons.kitchen,
        'color': Colors.purple,
      },
    ];

    return Column(
      children: tips.map((tip) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (tip['color'] as Color).withOpacity(0.1),
              child: Icon(
                tip['icon'] as IconData,
                color: tip['color'] as Color,
              ),
            ),
            title: Text(
              tip['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(tip['description'] as String),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecipeTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco;
      case 'dairy':
        return Icons.water_drop;
      case 'bread & pastries':
        return Icons.bakery_dining;
      case 'canned goods':
        return Icons.inventory;
      case 'frozen foods':
        return Icons.ac_unit;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waste Reduction Analytics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Track your impact on food waste reduction',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Key Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Waste Saved',
                  '${_analytics['totalWasteSaved']} kg',
                  Icons.eco,
                  Colors.green,
                  'Food waste prevented',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Donations',
                  '${_analytics['donationsMade']}',
                  Icons.favorite,
                  Colors.red,
                  'Items donated',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'People Helped',
                  '${_analytics['peopleHelped']}',
                  Icons.people,
                  Colors.blue,
                  'Community members',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Cost Savings',
                  '\$${_analytics['costSavings']}',
                  Icons.attach_money,
                  Colors.orange,
                  'Money saved',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Waste Reduction Chart
          _buildWasteReductionChart(),
          const SizedBox(height: 24),

          // Category Breakdown
          _buildCategoryBreakdown(),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(),
          const SizedBox(height: 24),

          // Environmental Impact
          _buildEnvironmentalImpact(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: color.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteReductionChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Waste Reduction Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Simple bar chart representation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChartBar('Jan', 0.3, Colors.green),
                _buildChartBar('Feb', 0.5, Colors.green),
                _buildChartBar('Mar', 0.7, Colors.green),
                _buildChartBar('Apr', 0.6, Colors.green),
                _buildChartBar('May', 0.8, Colors.green),
                _buildChartBar('Jun', 0.9, Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'ve reduced waste by 35% this month!',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String label, double height, Color color) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 100 * height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final categories = _inventory.fold<Map<String, int>>({}, (map, item) {
      map[item.category] = (map[item.category] ?? 0) + 1;
      return map;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Inventory by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...categories.entries.map((entry) => _buildCategoryItem(entry.key, entry.value)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, int count) {
    final total = _inventory.length;
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getCategoryColor(category),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count items',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Colors.red;
      case 'vegetables':
        return Colors.green;
      case 'dairy':
        return Colors.blue;
      case 'bread & pastries':
        return Colors.orange;
      case 'canned goods':
        return Colors.purple;
      case 'frozen foods':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Added Chicken to inventory', '2 hours ago', Icons.add_circle, Colors.green),
            _buildActivityItem('Donated 5kg vegetables', '1 day ago', Icons.favorite, Colors.red),
            _buildActivityItem('Generated 3 recipes', '2 days ago', Icons.restaurant_menu, Colors.orange),
            _buildActivityItem('Saved 2kg from waste', '3 days ago', Icons.eco, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalImpact() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: Colors.teal[600]),
                const SizedBox(width: 8),
                const Text(
                  'Environmental Impact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildImpactItem(
                    'CO₂ Saved',
                    '${(_analytics['totalWasteSaved'] * 2.5).round()} kg',
                    Icons.cloud,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImpactItem(
                    'Water Saved',
                    '${(_analytics['totalWasteSaved'] * 1000).round()} L',
                    Icons.water_drop,
                    Colors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade50, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.teal[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You\'re making a difference!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                        Text(
                          'Your waste reduction efforts are helping the environment.',
                          style: TextStyle(
                            color: Colors.teal[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showAddItemDialog(),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddInventoryDialog(
        profile: widget.profile,
        onItemAdded: (newItem) async {
          try {
            print('Adding item: ${newItem.name}'); // Debug log
            print('Profile ID: ${widget.profile.id}'); // Debug log
            
            if (widget.profile.id != 'demo-user-id') {
              print('Using real database'); // Debug log
              print('Profile ID type: ${widget.profile.id.runtimeType}'); // Debug log
              print('Profile ID value: "${widget.profile.id}"'); // Debug log
              
              // Check if the profile ID looks like a valid UUID
              if (widget.profile.id.length != 36 || !widget.profile.id.contains('-')) {
                throw Exception('Invalid restaurant ID format. Expected UUID format.');
              }
              
              final savedItem = await _inventoryRepo.addItem(
                restaurantId: widget.profile.id, // Use profile ID directly
                name: newItem.name,
                quantity: newItem.quantity,
                expiryDate: newItem.expiryDate,
                status: newItem.status,
                category: newItem.category, // Added category parameter
              );
              print('Item saved to database: ${savedItem.id}'); // Debug log
                 setState(() {
                   _inventory.add(savedItem);
                 });
                 // Recalculate analytics after adding item
                 _calculateAnalytics();
               } else {
                 print('Using demo mode'); // Debug log
                 setState(() {
                   _inventory.add(newItem);
                 });
                 // Recalculate analytics after adding item
                 _calculateAnalytics();
               }
            print('Item added successfully to inventory list'); // Debug log
          } catch (e) {
            print('Error adding item: $e'); // Debug log
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving item: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleInventoryAction(String action, InventoryItem item) {
    switch (action) {
      case 'edit':
        _showEditItemDialog(item);
        break;
      case 'donate':
        _showPostDonationDialog(item);
        break;
      case 'delete':
        _deleteInventoryItem(item);
        break;
    }
  }

  void _showEditItemDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => EditInventoryDialog(
        profile: widget.profile,
        item: item,
        onItemUpdated: (updatedItem) async {
          try {
            if (widget.profile.id != 'demo-user-id') {
              final savedItem = await _inventoryRepo.updateItem(
                item.id,
                {
                  'name': updatedItem.name,
                  'quantity': updatedItem.quantity,
                  'category': updatedItem.category,
                  'expiry_date': updatedItem.expiryDate.toIso8601String().split('T')[0],
                  'status': updatedItem.status,
                },
              );
              setState(() {
                final index = _inventory.indexWhere((i) => i.id == item.id);
                if (index != -1) {
                  _inventory[index] = savedItem;
                }
              });
            } else {
              setState(() {
                final index = _inventory.indexWhere((i) => i.id == item.id);
                if (index != -1) {
                  _inventory[index] = updatedItem;
                }
              });
            }
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating item: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showPostDonationDialog(InventoryItem item) async {
    final newDonation = await showDialog<Donation>(
      context: context,
      builder: (dialogContext) => PostDonationDialog(
        profile: widget.profile,
        item: item,
      ),
    );

    if (newDonation != null && mounted) {
      try {
        debugPrint('[PostDonation] Donation posted: ${newDonation.toString()}');
        if (widget.profile.id != 'demo-user-id') {
          final savedDonation = await _donationRepo.postDonation(
            restaurantId: widget.profile.id,
            title: newDonation.title,
            description: newDonation.description,
            quantity: newDonation.quantity,
            expiryDate: newDonation.expiryDate,
          );
          debugPrint('[PostDonation] Saved donation: ${savedDonation?.toString()}');
          if (!mounted) return;
          if (savedDonation != null) {
            setState(() {
              _donations.add(savedDonation);
            });
            _calculateAnalytics();
          }
        } else {
          if (!mounted) return;
          setState(() {
            _donations.add(newDonation);
          });
          _calculateAnalytics();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Ensure donation list is refreshed from backend after posting
        await _loadData();
        if (mounted) setState(() {});
      } catch (e, stack) {
        debugPrint('[PostDonation] Error: $e\n$stack');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDonationAction(String action, Donation donation) {
    switch (action) {
      case 'view':
        // TODO: Implement view details
        break;
    }
  }

  void _deleteInventoryItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                if (widget.profile.id != 'demo-user-id') {
                  await _inventoryRepo.deleteItem(item.id);
                }
                setState(() {
                  _inventory.removeWhere((i) => i.id == item.id);
                });
                // Recalculate analytics after deleting item
                _calculateAnalytics();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => const NotificationsDialog(),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(profile: widget.profile),
    );
  }

  void _showDrawer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Profile: ${widget.profile.name}'),
              subtitle: Text(widget.profile.role.toUpperCase()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.of(context).pop();
                _showNotifications();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                _showSettings();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () => _signOut(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.recycling,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.profile.role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _tabController.index == 0,
            onTap: () {
              _tabController.animateTo(0);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Inventory'),
            selected: _tabController.index == 1,
            onTap: () {
              _tabController.animateTo(1);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Donations'),
            selected: _tabController.index == 2,
            onTap: () {
              _tabController.animateTo(2);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Recipes'),
            selected: _tabController.index == 3,
            onTap: () {
              _tabController.animateTo(3);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            selected: _tabController.index == 4,
            onTap: () {
              _tabController.animateTo(4);
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.of(context).pop();
              _showNotifications();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              _showSettings();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _signOut();
            },
          ),
        ],
      ),
    );
  }

  Color _getDonationStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'claimed':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getDonationStatusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.favorite;
      case 'claimed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  void _showRecipeGenerationDialog(InventoryItem item) async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Finding recipes for ${item.name}...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Searching real recipe databases...'),
          ],
        ),
      ),
    );
    
    try {
      // Generate real API-powered recipes
      final aiRecipes = await _generateAIRecipe(item);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Real Recipes for ${item.name}'),
          content: SizedBox(
            width: 400,
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${aiRecipes.length} real recipes using your ingredients:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: aiRecipes.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No recipes found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adding more ingredients to your inventory',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: aiRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = aiRecipes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showDetailedAIRecipe(recipe);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with icon and title
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _getRecipeColor(recipe['difficulty']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getRecipeIcon(recipe['type']),
                                              color: _getRecipeColor(recipe['difficulty']),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              recipe['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey[400],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Description
                                      Text(
                                        recipe['description'],
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Tags row
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          _buildRecipeTag('${recipe['time']}', Icons.access_time, Colors.blue),
                                          _buildRecipeTag('${recipe['difficulty']}', Icons.speed, Colors.green),
                                          _buildRecipeTag('${recipe['wasteReduction']}% waste', Icons.eco, Colors.orange),
                                                                               ],
                                      ),
                                      
                                      // Source and cuisine
                                      if (recipe['source'] != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'Source: ${recipe['source']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (recipe['cuisine'] != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  recipe['cuisine'],
                                                  style: TextStyle(
                                                    color: Colors.blue[700],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (recipe['diet'] != null) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  recipe['diet'],
                                                  style: TextStyle(
                                                    color: Colors.green[700],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => _showAdvancedRecipeDialog(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Generate More', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching recipes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAdvancedRecipeDialog() async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Generating Multi-Ingredient Recipes...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Searching professional recipe databases...'),
          ],
        ),
      ),
    );
    
    try {
      // Use real API for multi-ingredient recipes
      final multiIngredientRecipes = await RecipeApiService.getRecipesByIngredients(_inventory);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Multi-Ingredient Recipes'),
          content: SizedBox(
            width: 500,
            height: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${multiIngredientRecipes.length} professional recipes using your ingredients:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: multiIngredientRecipes.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recipes found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adding more diverse ingredients to your inventory',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: multiIngredientRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = multiIngredientRecipes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showDetailedAIRecipe(recipe);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with icon and title
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _getRecipeColor(recipe['difficulty']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getRecipeIcon(recipe['type']),
                                              color: _getRecipeColor(recipe['difficulty']),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              recipe['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey[400],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Description
                                      Text(
                                        recipe['description'],
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Ingredients used
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Uses: ${(recipe['ingredients'] as List<String>).join(', ')}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Tags row
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          _buildRecipeTag('${recipe['time']}', Icons.access_time, Colors.blue),
                                          _buildRecipeTag('${recipe['difficulty']}', Icons.speed, Colors.green),
                                          _buildRecipeTag('${recipe['wasteReduction']}% waste', Icons.eco, Colors.orange),
                                        ],
                                      ),
                                      
                                      // Source and cuisine
                                      if (recipe['source'] != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'Source: ${recipe['source']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (recipe['cuisine'] != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  recipe['cuisine'],
                                                  style: TextStyle(
                                                    color: Colors.blue[700],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching multi-ingredient recipes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Real API-based Recipe Generation
  Future<List<Map<String, dynamic>>> _generateAIRecipe(InventoryItem primaryItem) async {
    final availableItems = _inventory.where((item) => item.id != primaryItem.id).toList();
    final expiringItems = availableItems.where((item) => 
      item.expiryDate.difference(DateTime.now()).inDays <= 3
    ).toList();
    
    // Use real recipe API
    final allIngredients = [primaryItem, ...availableItems];
    final recipes = await RecipeApiService.getRecipesByIngredients(allIngredients);
    
    // Sort by waste reduction potential and expiry urgency
    recipes.sort((a, b) {
      final aUrgency = _calculateUrgencyFromNames(a['ingredients'] as List<String>);
      final bUrgency = _calculateUrgencyFromNames(b['ingredients'] as List<String>);
      return bUrgency.compareTo(aUrgency);
    });
    
    return recipes.take(5).toList(); // Return top 5 recipes
  }

  // Find ingredients that work well together
  List<InventoryItem> _findCompatibleIngredients(InventoryItem primary, List<InventoryItem> available) {
    final compatible = <InventoryItem>[];
    
    for (final item in available) {
      if (_areIngredientsCompatible(primary, item)) {
        compatible.add(item);
      }
    }
    
    return compatible;
  }

  // Check if two ingredients are compatible for cooking
  bool _areIngredientsCompatible(InventoryItem item1, InventoryItem item2) {
    final name1 = item1.name.toLowerCase();
    final name2 = item2.name.toLowerCase();
    final cat1 = item1.category.toLowerCase();
    final cat2 = item2.category.toLowerCase();
    
    // Bread + protein combinations
    if ((name1.contains('bread') || name1.contains('toast') || name1.contains('bun')) && 
        (name2.contains('egg') || name2.contains('cheese') || name2.contains('meat') || name2.contains('chicken'))) {
      return true;
    }
    if ((name2.contains('bread') || name2.contains('toast') || name2.contains('bun')) && 
        (name1.contains('egg') || name1.contains('cheese') || name1.contains('meat') || name1.contains('chicken'))) {
      return true;
    }
    
    // Dairy + other ingredients
    if ((cat1 == 'dairy' && cat2 != 'dairy') || (cat2 == 'dairy' && cat1 != 'dairy')) {
      return true;
    }
    
    // Vegetables + other vegetables
    if (cat1 == 'vegetables' && cat2 == 'vegetables') {
      return true;
    }
    
    // Fruits + dairy (smoothies, desserts)
    if ((cat1 == 'fruits' && cat2 == 'dairy') || (cat2 == 'fruits' && cat1 == 'dairy')) {
      return true;
    }
    
    // Fruits + other fruits
    if (cat1 == 'fruits' && cat2 == 'fruits') {
      return true;
    }
    
    // Any ingredient with herbs/spices
    if (name1.contains('herb') || name1.contains('spice') || name1.contains('garlic') || name1.contains('onion') ||
        name2.contains('herb') || name2.contains('spice') || name2.contains('garlic') || name2.contains('onion')) {
      return true;
    }
    
    return false;
  }

  // Generate real recipes based on actual ingredients
  List<Map<String, dynamic>> _generateRealRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Analyze primary ingredient and find real recipes
    final primaryName = primary.name.toLowerCase();
    final primaryCategory = primary.category.toLowerCase();
    
    // Bread-based recipes
    if (primaryName.contains('bread') || primaryName.contains('toast') || primaryName.contains('bun')) {
      recipes.addAll(_generateBreadBasedRecipes(primary, compatible, expiring));
    }
    
    // Egg-based recipes
    if (primaryName.contains('egg')) {
      recipes.addAll(_generateEggBasedRecipes(primary, compatible, expiring));
    }
    
    // Cheese-based recipes
    if (primaryName.contains('cheese')) {
      recipes.addAll(_generateCheeseBasedRecipes(primary, compatible, expiring));
    }
    
    // Vegetable-based recipes
    if (primaryCategory == 'vegetables') {
      recipes.addAll(_generateVegetableBasedRecipes(primary, compatible, expiring));
    }
    
    // Fruit-based recipes
    if (primaryCategory == 'fruits') {
      recipes.addAll(_generateFruitBasedRecipes(primary, compatible, expiring));
    }
    
    // Generic combinations
    if (recipes.isEmpty) {
      recipes.addAll(_generateGenericCombinations(primary, compatible, expiring));
    }
    
    return recipes;
  }

  void _showRecipeForItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recipe for ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Here are some recipe ideas for your ${item.name}:'),
            const SizedBox(height: 16),
            _buildRecipeSuggestion(item),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSuggestion(InventoryItem item) {
    final suggestions = _getRecipeSuggestions(item.category);
    
    return Column(
      children: suggestions.map((suggestion) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(suggestion['name']),
            subtitle: Text(suggestion['description']),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).pop();
              _showRecipeDetail(suggestion);
            },
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getRecipeSuggestions(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return [
          {
            'name': 'Fruit Smoothie',
            'description': 'Blend with yogurt and honey',
            'time': '5 min',
            'difficulty': 'Easy',
            'ingredients': ['Any fruits', 'Yogurt', 'Honey'],
            'instructions': '1. Blend all ingredients\n2. Serve chilled',
          },
          {
            'name': 'Fruit Salad',
            'description': 'Fresh fruit combination',
            'time': '10 min',
            'difficulty': 'Easy',
            'ingredients': ['Mixed fruits', 'Lemon juice', 'Mint'],
            'instructions': '1. Cut fruits into pieces\n2. Add lemon juice\n3. Garnish with mint',
          },
        ];
      case 'vegetables':
        return [
          {
            'name': 'Vegetable Stir-fry',
            'description': 'Quick and healthy stir-fry',
            'time': '15 min',
            'difficulty': 'Easy',
            'ingredients': ['Any vegetables', 'Garlic', 'Soy sauce', 'Oil'],
            'instructions': '1. Heat oil in pan\n2. Add garlic\n3. Add vegetables\n4. Season with soy sauce',
          },
          {
            'name': 'Roasted Vegetables',
            'description': 'Oven-roasted vegetable medley',
            'time': '30 min',
            'difficulty': 'Easy',
            'ingredients': ['Any vegetables', 'Olive oil', 'Salt', 'Herbs'],
            'instructions': '1. Preheat oven\n2. Toss vegetables with oil\n3. Roast for 25-30 min',
          },
        ];
      case 'dairy':
        return [
          {
            'name': 'Cheese Sauce',
            'description': 'Versatile cheese sauce',
            'time': '10 min',
            'difficulty': 'Easy',
            'ingredients': ['Cheese', 'Milk', 'Butter', 'Flour'],
            'instructions': '1. Melt butter\n2. Add flour\n3. Add milk gradually\n4. Add cheese',
          },
        ];
      default:
        return [
          {
            'name': 'Creative Leftover Dish',
            'description': 'Transform your ${category.toLowerCase()} into something new',
            'time': '20 min',
            'difficulty': 'Easy',
            'ingredients': ['Your item', 'Basic seasonings'],
            'instructions': '1. Assess the item\n2. Add seasonings\n3. Cook creatively',
          },
        ];
    }
  }

  void _showRecipeDetail(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipe['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                'Ingredients:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(recipe['ingredients'] as List).map((ingredient) => 
                Text('• $ingredient')).toList(),
              const SizedBox(height: 16),
              Text(
                'Instructions:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(recipe['instructions']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Real recipe generators based on actual ingredients
  List<Map<String, dynamic>> _generateBreadBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final eggs = compatible.where((item) => item.name.toLowerCase().contains('egg')).toList();
    final cheese = compatible.where((item) => item.name.toLowerCase().contains('cheese')).toList();
    final meat = compatible.where((item) => 
      item.name.toLowerCase().contains('chicken') || 
      item.name.toLowerCase().contains('meat') || 
      item.name.toLowerCase().contains('ham')
    ).toList();
    
    // Egg Sandwich
    if (eggs.isNotEmpty) {
      final ingredients = [primary, eggs.first];
      if (cheese.isNotEmpty) ingredients.add(cheese.first);
      
      recipes.add({
        'name': 'Classic Egg Sandwich',
        'description': 'Perfect breakfast sandwich with ${eggs.first.name} and ${primary.name}',
        'time': '10 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': ingredients,
        'instructions': '1. Toast the ${primary.name} until golden\n2. Scramble the ${eggs.first.name} with salt and pepper\n3. ${cheese.isNotEmpty ? 'Add ${cheese.first.name} to the egg while cooking' : ''}\n4. Assemble sandwich and serve hot',
        'nutritionalValue': 'High protein breakfast with carbs for energy',
        'serves': '1-2 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateEggBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final bread = compatible.where((item) => 
      item.name.toLowerCase().contains('bread') || 
      item.name.toLowerCase().contains('toast')
    ).toList();
    final cheese = compatible.where((item) => item.name.toLowerCase().contains('cheese')).toList();
    final vegetables = compatible.where((item) => item.category.toLowerCase() == 'vegetables').toList();
    
    // Scrambled Eggs
    final scrambledIngredients = [primary];
    if (cheese.isNotEmpty) scrambledIngredients.add(cheese.first);
    if (vegetables.isNotEmpty) scrambledIngredients.add(vegetables.first);
    
    recipes.add({
      'name': 'Scrambled Eggs',
      'description': 'Creamy scrambled ${primary.name}${cheese.isNotEmpty ? ' with ${cheese.first.name}' : ''}${vegetables.isNotEmpty ? ' and ${vegetables.first.name}' : ''}',
      'time': '8 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 95,
      'ingredients': scrambledIngredients,
      'instructions': '1. Beat the ${primary.name} in a bowl\n2. ${cheese.isNotEmpty ? 'Add grated ${cheese.first.name}' : ''}\n3. ${vegetables.isNotEmpty ? 'Sauté ${vegetables.first.name} first, then add eggs' : 'Heat butter in a pan'}\n4. Cook eggs slowly, stirring constantly\n5. Season with salt and pepper, serve hot',
      'nutritionalValue': 'High protein breakfast with essential amino acids',
      'serves': '1-2 people',
    });
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateCheeseBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final vegetables = compatible.where((item) => item.category.toLowerCase() == 'vegetables').toList();
    final bread = compatible.where((item) => 
      item.name.toLowerCase().contains('bread') || 
      item.name.toLowerCase().contains('toast')
    ).toList();
    
    // Cheese Sauce
    recipes.add({
      'name': 'Homemade Cheese Sauce',
      'description': 'Versatile ${primary.name} sauce perfect for pasta, vegetables, or nachos',
      'time': '15 min',
      'difficulty': 'Easy',
      'type': 'sauce',
      'wasteReduction': 95,
      'ingredients': [primary],
      'instructions': '1. Melt butter in a saucepan\n2. Add flour and cook for 1 minute\n3. Gradually whisk in milk\n4. Add ${primary.name} and stir until smooth\n5. Season with salt, pepper, and mustard\n6. Serve over pasta or vegetables',
      'nutritionalValue': 'High in protein and calcium',
      'serves': '4-6 people',
    });
    
    // Cheese and Vegetable Casserole
    if (vegetables.isNotEmpty) {
      final ingredients = [primary, ...vegetables.take(2)];
      
      recipes.add({
        'name': 'Cheese and Vegetable Casserole',
        'description': 'Baked casserole with ${primary.name} and ${vegetables.map((e) => e.name).join(', ')}',
        'time': '45 min',
        'difficulty': 'Medium',
        'type': 'main',
        'wasteReduction': 90,
        'ingredients': ingredients,
        'instructions': '1. Preheat oven to 375°F\n2. ${vegetables.map((e) => 'Slice ${e.name}').join(' and ')}\n3. Layer vegetables in a baking dish\n4. Sprinkle with ${primary.name}\n5. Bake for 30-35 minutes until golden\n6. Let rest 5 minutes before serving',
        'nutritionalValue': 'Complete meal with vegetables and dairy',
        'serves': '4-6 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateVegetableBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final otherVegetables = compatible.where((item) => item.category.toLowerCase() == 'vegetables').toList();
    final cheese = compatible.where((item) => item.name.toLowerCase().contains('cheese')).toList();
    
    // Vegetable Stir-fry
    if (otherVegetables.isNotEmpty) {
      final ingredients = [primary, ...otherVegetables.take(3)];
      
      recipes.add({
        'name': 'Mixed Vegetable Stir-fry',
        'description': 'Quick stir-fry with ${primary.name} and ${otherVegetables.map((e) => e.name).join(', ')}',
        'time': '15 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': ingredients,
        'instructions': '1. Heat oil in a large wok or pan\n2. Add garlic and ginger, cook 30 seconds\n3. Add ${primary.name} and cook 2-3 minutes\n4. Add ${otherVegetables.map((e) => e.name).join(', ')} in order of cooking time\n5. Season with soy sauce and sesame oil\n6. Serve immediately over rice',
        'nutritionalValue': 'High in vitamins, fiber, and antioxidants',
        'serves': '3-4 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateFruitBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final otherFruits = compatible.where((item) => item.category.toLowerCase() == 'fruits').toList();
    final dairy = compatible.where((item) => item.category.toLowerCase() == 'dairy').toList();
    
    // Fruit Smoothie
    if (dairy.isNotEmpty) {
      final ingredients = [primary];
      if (otherFruits.isNotEmpty) ingredients.add(otherFruits.first);
      ingredients.add(dairy.first);
      
      recipes.add({
        'name': 'Fresh Fruit Smoothie',
        'description': 'Nutritious smoothie with ${primary.name}${otherFruits.isNotEmpty ? ', ${otherFruits.first.name}' : ''} and ${dairy.first.name}',
        'time': '5 min',
        'difficulty': 'Easy',
        'type': 'beverage',
        'wasteReduction': 95,
        'ingredients': ingredients,
        'instructions': '1. Peel and chop ${primary.name}${otherFruits.isNotEmpty ? ' and ${otherFruits.first.name}' : ''}\n2. Add to blender with ${dairy.first.name}\n3. Add honey or sugar to taste\n4. Blend until smooth and creamy\n5. Serve immediately over ice',
        'nutritionalValue': 'High in vitamins and antioxidants',
        'serves': '2-3 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateGenericCombinations(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Create a simple combination recipe
    final ingredients = [primary];
    if (compatible.isNotEmpty) ingredients.add(compatible.first);
    
    recipes.add({
      'name': 'Creative ${primary.name} Dish',
      'description': 'Simple and delicious way to use ${primary.name}${compatible.isNotEmpty ? ' with ${compatible.first.name}' : ''}',
      'time': '20 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 85,
      'ingredients': ingredients,
      'instructions': '1. Prepare ${primary.name} as desired\n2. ${compatible.isNotEmpty ? 'Add ${compatible.first.name} for extra flavor' : 'Season with salt and pepper'}\n3. Cook using your preferred method\n4. Taste and adjust seasoning\n5. Serve hot and enjoy',
      'nutritionalValue': 'Nutritious meal using available ingredients',
      'serves': '2-3 people',
    });
    
    return recipes;
  }

  // Legacy method - keeping for compatibility
  List<Map<String, dynamic>> _generateFruitRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Fruit Smoothie with expiring items
    final smoothieIngredients = [primary];
    final expiringFruits = expiring.where((item) => item.category.toLowerCase() == 'fruits').take(2).toList();
    smoothieIngredients.addAll(expiringFruits);
    
    if (smoothieIngredients.length > 1) {
      recipes.add({
        'name': 'Zero-Waste Fruit Smoothie',
        'description': 'Blend ${smoothieIngredients.map((e) => e.name).join(', ')} with yogurt and honey',
        'time': '5 min',
        'difficulty': 'Easy',
        'type': 'beverage',
        'wasteReduction': 95,
        'ingredients': smoothieIngredients,
        'instructions': '1. Peel and chop all fruits\n2. Add to blender with yogurt and honey\n3. Blend until smooth\n4. Serve immediately',
        'nutritionalValue': 'High in vitamins and antioxidants',
        'serves': '2-3 people',
      });
    }
    
    // Fruit Salad with multiple items
    final saladIngredients = [primary];
    final otherFruits = available.where((item) => 
      item.category.toLowerCase() == 'fruits' && item.id != primary.id
    ).take(3).toList();
    saladIngredients.addAll(otherFruits);
    
    if (saladIngredients.length > 1) {
      recipes.add({
        'name': 'Rainbow Fruit Salad',
        'description': 'Fresh combination of ${saladIngredients.map((e) => e.name).join(', ')}',
        'time': '10 min',
        'difficulty': 'Easy',
        'type': 'salad',
        'wasteReduction': 90,
        'ingredients': saladIngredients,
        'instructions': '1. Wash and cut all fruits into bite-sized pieces\n2. Mix gently in a bowl\n3. Add lemon juice and mint\n4. Chill before serving',
        'nutritionalValue': 'Rich in fiber and natural sugars',
        'serves': '4-6 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateVegetableRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Vegetable Stir-fry with expiring items
    final stirFryIngredients = [primary];
    final expiringVeggies = expiring.where((item) => item.category.toLowerCase() == 'vegetables').take(3).toList();
    stirFryIngredients.addAll(expiringVeggies);
    
    if (stirFryIngredients.length > 1) {
      recipes.add({
        'name': 'Emergency Vegetable Stir-fry',
        'description': 'Quick stir-fry using ${stirFryIngredients.map((e) => e.name).join(', ')}',
        'time': '15 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': stirFryIngredients,
        'instructions': '1. Heat oil in a large pan\n2. Add garlic and ginger\n3. Add vegetables in order of cooking time\n4. Season with soy sauce and sesame oil\n5. Serve immediately',
        'nutritionalValue': 'High in fiber and vitamins',
        'serves': '2-4 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateDairyRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Cheese-based recipes
    if (primary.name.toLowerCase().contains('cheese')) {
      recipes.add({
        'name': 'Quick Cheese Sauce',
        'description': 'Versatile sauce using ${primary.name}',
        'time': '10 min',
        'difficulty': 'Easy',
        'type': 'sauce',
        'wasteReduction': 95,
        'ingredients': [primary],
        'instructions': '1. Melt butter in a pan\n2. Add flour and cook for 1 minute\n3. Gradually add milk\n4. Add cheese and stir until smooth\n5. Season to taste',
        'nutritionalValue': 'High in protein and calcium',
        'serves': '4-6 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateBreadRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Stale bread recipes
    if (primary.expiryDate.difference(DateTime.now()).inDays <= 1) {
      recipes.add({
        'name': 'Bread Pudding Delight',
        'description': 'Transform stale ${primary.name} into a delicious dessert',
        'time': '45 min',
        'difficulty': 'Medium',
        'type': 'dessert',
        'wasteReduction': 100,
        'ingredients': [primary],
        'instructions': '1. Cut bread into cubes\n2. Mix with eggs, milk, and sugar\n3. Add vanilla and cinnamon\n4. Bake at 350°F for 30 minutes\n5. Serve warm',
        'nutritionalValue': 'Comfort food with protein and carbs',
        'serves': '6-8 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateGenericRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    recipes.add({
      'name': 'Creative Leftover Transformation',
      'description': 'Transform ${primary.name} into something new',
      'time': '20 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 85,
      'ingredients': [primary],
      'instructions': '1. Assess the condition of ${primary.name}\n2. Remove any bad parts\n3. Season creatively\n4. Cook with complementary ingredients\n5. Serve with confidence',
      'nutritionalValue': 'Maximizes nutrition from available ingredients',
      'serves': '2-4 people',
    });
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateMultiIngredientRecipes() {
    final recipes = <Map<String, dynamic>>[];
    final expiringItems = _inventory.where((item) => 
      item.expiryDate.difference(DateTime.now()).inDays <= 2
    ).toList();
    
    // If no expiring items, use all available items
    final availableItems = expiringItems.isNotEmpty ? expiringItems : _inventory;
    
    if (availableItems.length >= 2) {
      recipes.add({
        'name': 'Zero-Waste Feast',
        'description': 'Complete meal using ${availableItems.map((e) => e.name).join(', ')}',
        'time': '45 min',
        'difficulty': 'Medium',
        'type': 'main',
        'wasteReduction': 100,
        'ingredients': availableItems,
        'instructions': '1. Sort ingredients by cooking time\n2. Start with longest-cooking items\n3. Add shorter-cooking items progressively\n4. Season and serve as a complete meal',
        'nutritionalValue': 'Complete nutrition from diverse ingredients',
        'serves': '4-6 people',
      });
    }
    
    // Add category-specific multi-ingredient recipes
    if (availableItems.length >= 3) {
      final fruits = availableItems.where((item) => item.category.toLowerCase() == 'fruits').toList();
      final vegetables = availableItems.where((item) => item.category.toLowerCase() == 'vegetables').toList();
      
      if (fruits.length >= 2) {
        recipes.add({
          'name': 'Tropical Fruit Medley',
          'description': 'Fresh combination of ${fruits.map((e) => e.name).join(', ')}',
          'time': '15 min',
          'difficulty': 'Easy',
          'type': 'salad',
          'wasteReduction': 95,
          'ingredients': fruits,
          'instructions': '1. Wash and prepare all fruits\n2. Cut into bite-sized pieces\n3. Mix with lemon juice and honey\n4. Chill and serve',
          'nutritionalValue': 'High in vitamins and natural sugars',
          'serves': '4-6 people',
        });
      }
      
      if (vegetables.length >= 3) {
        recipes.add({
          'name': 'Garden Vegetable Stir-fry',
          'description': 'Quick stir-fry using ${vegetables.map((e) => e.name).join(', ')}',
          'time': '20 min',
          'difficulty': 'Easy',
          'type': 'main',
          'wasteReduction': 90,
          'ingredients': vegetables,
          'instructions': '1. Heat oil in a large wok\n2. Add vegetables in order of cooking time\n3. Season with soy sauce and garlic\n4. Serve over rice or noodles',
          'nutritionalValue': 'High in fiber and vitamins',
          'serves': '3-4 people',
        });
      }
    }
    
    // If still no recipes, add a generic one
    if (recipes.isEmpty && availableItems.isNotEmpty) {
      recipes.add({
        'name': 'Creative Leftover Transformation',
        'description': 'Transform your available ingredients into something delicious',
        'time': '25 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 85,
        'ingredients': availableItems.take(3).toList(),
        'instructions': '1. Assess all available ingredients\n2. Remove any bad parts\n3. Season creatively with herbs and spices\n4. Cook using your preferred method\n5. Serve with confidence',
        'nutritionalValue': 'Maximizes nutrition from available ingredients',
        'serves': '2-4 people',
      });
    }
    
    return recipes;
  }

  int _calculateUrgency(List<InventoryItem> ingredients) {
    int urgency = 0;
    for (final item in ingredients) {
      final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 1) urgency += 100;
      else if (daysUntilExpiry <= 2) urgency += 80;
      else if (daysUntilExpiry <= 3) urgency += 60;
    }
    return urgency;
  }

  int _calculateUrgencyFromNames(List<String> ingredientNames) {
    int urgency = 0;
    for (final name in ingredientNames) {
      // Find matching inventory item
      final item = _inventory.firstWhere(
        (item) => item.name.toLowerCase().contains(name.toLowerCase()) || 
                  name.toLowerCase().contains(item.name.toLowerCase()),
        orElse: () => _inventory.first, // fallback
      );
      
      final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 1) urgency += 100;
      else if (daysUntilExpiry <= 2) urgency += 80;
      else if (daysUntilExpiry <= 3) urgency += 60;
    }
    return urgency;
  }

  Color _getRecipeColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getRecipeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'beverage':
        return Icons.local_drink;
      case 'salad':
        return Icons.eco;
      case 'dessert':
        return Icons.cake;
      case 'main':
        return Icons.restaurant;
      case 'side':
        return Icons.dining;
      case 'soup':
        return Icons.soup_kitchen;
      case 'sauce':
        return Icons.water_drop;
      case 'ingredient':
        return Icons.inventory;
      default:
        return Icons.restaurant_menu;
    }
  }

  void _showDetailedAIRecipe(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipe['description'],
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              // Recipe stats
              Row(
                children: [
                  _buildRecipeTag('${recipe['time']}', Icons.access_time, Colors.blue),
                  const SizedBox(width: 8),
                  _buildRecipeTag('${recipe['difficulty']}', Icons.speed, Colors.green),
                  const SizedBox(width: 8),
                  _buildRecipeTag('${recipe['wasteReduction']}% waste reduction', Icons.eco, Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              
              // Ingredients
              Text(
                'Ingredients:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...(recipe['ingredients'] as List<String>).map((ingredient) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(ingredient),
                    ],
                  ),
                )
              ).toList(),
              const SizedBox(height: 16),
              
              // Instructions
              Text(
                'Instructions:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (recipe['instructions'] is List)
                ...(recipe['instructions'] as List<String>).map((instruction) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(instruction),
                  )
                ).toList()
              else
                Text(recipe['instructions']),
              const SizedBox(height: 16),
              
              // Nutritional info
              if (recipe['nutritionalValue'] != null) ...[
                Text(
                  'Nutritional Value:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(recipe['nutritionalValue']),
                const SizedBox(height: 8),
              ],
              
              // Serves
              if (recipe['serves'] != null) ...[
                Text(
                  'Serves: ${recipe['serves']}',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _markIngredientsAsUsed(recipe['ingredients'] as List<InventoryItem>);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark as Used', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markIngredientsAsUsed(List<InventoryItem> ingredients) {
    // This would mark ingredients as used in a real implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked ${ingredients.length} ingredients as used!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class AddInventoryDialog extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(InventoryItem) onItemAdded;
  
  const AddInventoryDialog({
    super.key,
    required this.profile,
    required this.onItemAdded,
  });

  @override
  State<AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<AddInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  String _category = 'Fruits';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Inventory Item'),
      content: SingleChildScrollView( // ✅ prevents overflow
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity (e.g., 5 kg, 10 units)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                  DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                  DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                  DropdownMenuItem(value: 'Bread & Pastries', child: Text('Bread & Pastries')),
                  DropdownMenuItem(value: 'Canned Goods', child: Text('Canned Goods')),
                  DropdownMenuItem(value: 'Frozen Foods', child: Text('Frozen Foods')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? 'Fruits'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Expiry Date: ${_expiryDate.toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 👇 Scan Barcode button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScannerScreen(
                        onScanned: (code) async {
                          final product = await BarcodeLookupService.fetchProductFromBarcode(code);

                          setState(() {
                            _nameCtrl.text = product['name'] ?? "Unknown Product";
                            _quantityCtrl.text = product['quantity'] ?? "1";

                            // ✅ Only allow known categories
                            final apiCategory = product['category'] ?? "Other";
                            const allowedCategories = [
                              'Fruits',
                              'Vegetables',
                              'Dairy',
                              'Bread & Pastries',
                              'Canned Goods',
                              'Frozen Foods',
                              'Other',
                            ];

                            if (allowedCategories.contains(apiCategory)) {
                              _category = apiCategory;
                            } else {
                              _category = "Other";
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Scan Barcode"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final newItem = InventoryItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                restaurantId: widget.profile.id,
                name: _nameCtrl.text.trim(),
                quantity: _quantityCtrl.text.trim(),
                category: _category,
                expiryDate: _expiryDate,
                status: 'available',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                await widget.onItemAdded(newItem);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}

class NotificationsDialog extends StatefulWidget {
  const NotificationsDialog({super.key});

  @override
  State<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<NotificationsDialog> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Items Expiring Soon',
      'message': '3 items in your inventory are expiring within 2 days',
      'time': '2 hours ago',
      'type': 'warning',
      'read': false,
    },
    {
      'title': 'Recipe Suggestion',
      'message': 'New recipe available: Chicken Chapati Roll using your expiring items',
      'time': '4 hours ago',
      'type': 'recipe',
      'read': false,
    },
    {
      'title': 'Donation Claimed',
      'message': 'Your "Fresh Vegetables" donation has been claimed by Green NGO',
      'time': '1 day ago',
      'type': 'donation',
      'read': true,
    },
    {
      'title': 'Weekly Impact Report',
      'message': 'You saved 15kg of food waste this week! View your analytics.',
      'time': '2 days ago',
      'type': 'analytics',
      'read': true,
    },
    {
      'title': 'New Feature Available',
      'message': 'Smart recipe generation is now available! Try it out.',
      'time': '3 days ago',
      'type': 'feature',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          '${_notifications.where((n) => !n['read']).length} unread notifications',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Notifications List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationCard(notification, index);
                },
              ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark All Read'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final Color typeColor = _getNotificationTypeColor(notification['type']);
    final IconData typeIcon = _getNotificationTypeIcon(notification['type']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification['read'] ? 1 : 3,
      child: InkWell(
        onTap: () => _markAsRead(index),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification['read'] ? Colors.white : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: typeColor.withOpacity(0.1),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: notification['read'] ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification['read'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['time'],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'recipe':
        return Colors.green;
      case 'donation':
        return Colors.red;
      case 'analytics':
        return Colors.purple;
      case 'feature':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'recipe':
        return Icons.restaurant_menu;
      case 'donation':
        return Icons.favorite;
      case 'analytics':
        return Icons.analytics;
      case 'feature':
        return Icons.new_releases;
      default:
        return Icons.notifications;
    }
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['read'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }
}

class SettingsDialog extends StatefulWidget {
  final UserProfile profile;
  
  const SettingsDialog({super.key, required this.profile});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _expiryNotifications = true;
  bool _donationNotifications = true;
  bool _recipeNotifications = true;
  bool _analyticsNotifications = true;
  double _expiryWarningDays = 3.0;
  bool _autoGenerateRecipes = true;
  bool _darkMode = false;
  String _selectedLanguage = 'English';
  bool _emailReminders = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.green.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restaurant Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          '${widget.profile.name} • ${widget.profile.location}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notifications Section
                    _buildSettingsSection(
                      'Notifications',
                      Icons.notifications,
                      Colors.blue,
                      [
                        _buildSwitchTile(
                          'Expiry Warnings',
                          'Get notified when items are about to expire',
                          _expiryNotifications,
                          (value) => setState(() => _expiryNotifications = value),
                        ),
                        _buildSwitchTile(
                          'Donation Updates',
                          'Notifications for donation status changes',
                          _donationNotifications,
                          (value) => setState(() => _donationNotifications = value),
                        ),
                        _buildSwitchTile(
                          'Recipe Suggestions',
                          'Get notified about new recipe opportunities',
                          _recipeNotifications,
                          (value) => setState(() => _recipeNotifications = value),
                        ),
                        _buildSwitchTile(
                          'Analytics Reports',
                          'Weekly and monthly impact reports',
                          _analyticsNotifications,
                          (value) => setState(() => _analyticsNotifications = value),
                        ),
                        _buildSwitchTile(
                          'Email Reminders',
                          'Receive email notifications',
                          _emailReminders,
                          (value) => setState(() => _emailReminders = value),
                        ),
                        _buildSwitchTile(
                          'Push Notifications',
                          'Mobile push notifications',
                          _pushNotifications,
                          (value) => setState(() => _pushNotifications = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Inventory Management Section
                    _buildSettingsSection(
                      'Inventory Management',
                      Icons.inventory,
                      Colors.orange,
                      [
                        _buildSliderTile(
                          'Expiry Warning Days',
                          'Days before expiry to show warnings',
                          _expiryWarningDays,
                          1,
                          7,
                          (value) => setState(() => _expiryWarningDays = value),
                        ),
                        _buildSwitchTile(
                          'Auto Recipe Generation',
                          'Automatically suggest recipes for expiring items',
                          _autoGenerateRecipes,
                          (value) => setState(() => _autoGenerateRecipes = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // App Preferences Section
                    _buildSettingsSection(
                      'App Preferences',
                      Icons.palette,
                      Colors.purple,
                      [
                        _buildSwitchTile(
                          'Dark Mode',
                          'Use dark theme throughout the app',
                          _darkMode,
                          (value) => setState(() => _darkMode = value),
                        ),
                        _buildDropdownTile(
                          'Language',
                          'Select your preferred language',
                          _selectedLanguage,
                          ['English', 'Spanish', 'French', 'German', 'Hindi'],
                          (value) {
                            if (value != null) setState(() => _selectedLanguage = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Account Section
                    _buildSettingsSection(
                      'Account',
                      Icons.account_circle,
                      Colors.grey,
                      [
                        _buildInfoTile('Restaurant Name', widget.profile.name),
                        _buildInfoTile('Location', widget.profile.location),
                        _buildInfoTile('Role', widget.profile.role.toUpperCase()),
                        _buildActionTile(
                          'Change Password',
                          'Update your account password',
                          Icons.lock,
                          () => _showChangePasswordDialog(context),
                        ),
                        _buildActionTile(
                          'Export Data',
                          'Download your inventory and analytics data',
                          Icons.download,
                          () => _showExportDataDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveSettings(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ...existing code...
  }

  Widget _buildSettingsSection(String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, ValueChanged<double> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              label: '${value.round()} days',
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.info_outline, color: Colors.grey),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Data export functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _saveSettings(BuildContext context) {
    // Here you would save the settings to SharedPreferences or database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

class EditInventoryDialog extends StatefulWidget {
  final UserProfile profile;
  final InventoryItem item;
  final Future<void> Function(InventoryItem) onItemUpdated;
  
  const EditInventoryDialog({
    super.key,
    required this.profile,
    required this.item,
    required this.onItemUpdated,
  });

  @override
  State<EditInventoryDialog> createState() => _EditInventoryDialogState();
}

class _EditInventoryDialogState extends State<EditInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _quantityCtrl;
  late String _category;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _quantityCtrl = TextEditingController(text: widget.item.quantity);
    _category = widget.item.category;
    _expiryDate = widget.item.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Inventory Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantity (e.g., 5 kg, 10 units)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                DropdownMenuItem(value: 'Bread & Pastries', child: Text('Bread & Pastries')),
                DropdownMenuItem(value: 'Canned Goods', child: Text('Canned Goods')),
                DropdownMenuItem(value: 'Frozen Foods', child: Text('Frozen Foods')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _category = value ?? 'Fruits'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Expiry Date: ${_expiryDate.toString().split(' ')[0]}'),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _expiryDate = picked);
                    }
                  },
                  child: const Text('Pick Date'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final updatedItem = InventoryItem(
                id: widget.item.id,
                restaurantId: widget.item.restaurantId,
                name: _nameCtrl.text.trim(),
                quantity: _quantityCtrl.text.trim(),
                category: _category,
                expiryDate: _expiryDate,
                status: widget.item.status,
                createdAt: widget.item.createdAt,
                updatedAt: DateTime.now(),
              );
              
              await widget.onItemUpdated(updatedItem);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Update Item'),
        ),
      ],
    );
  }
}

class PostDonationDialog extends StatefulWidget {
  final UserProfile profile;
  final InventoryItem item;
  
  const PostDonationDialog({
    super.key,
    required this.profile,
    required this.item,
  });

  @override
  State<PostDonationDialog> createState() => _PostDonationDialogState();
}

class _PostDonationDialogState extends State<PostDonationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.item.name;
    _descriptionCtrl.text = 'Fresh ${widget.item.name} available for donation';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post as Donation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Donation Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Item Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  Text('Quantity: ${widget.item.quantity}'),
                  Text('Category: ${widget.item.category}'),
                  Text('Expires: ${widget.item.expiryDate.toString().split(' ')[0]}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final donation = Donation(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                restaurantId: widget.profile.id,
                title: _titleCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                quantity: widget.item.quantity,
                expiryDate: widget.item.expiryDate,
                status: 'available',
                postedAt: DateTime.now(),
              );
              Navigator.of(context).pop(donation);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Post Donation'),
        ),
      ],
    );
  }
}
