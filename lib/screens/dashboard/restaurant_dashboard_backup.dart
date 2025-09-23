import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/inventory_item.dart';
import '../../models/donation.dart';
import '../../services/repositories/inventory_repository.dart';
import '../../services/repositories/donation_repository.dart';
import '../../services/supabase_service.dart';

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

  // Analytics data
  final Map<String, dynamic> _analytics = {
    'totalWasteSaved': 1250, // kg
    'donationsMade': 45,
    'peopleHelped': 180,
    'costSavings': 3200, // dollars
    'expiringSoon': 8,
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
      // In demo mode, use mock data
      if (widget.profile.id == 'demo-user-id') {
        await Future.delayed(const Duration(milliseconds: 500));
        _inventory = _getMockInventory();
        _donations = _getMockDonations();
      } else {
        _inventory = await _inventoryRepo.listInventory(widget.profile.id);
        _donations = await _donationRepo.listMyRestaurantDonations(widget.profile.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      InventoryItem(
        id: '3',
        restaurantId: widget.profile.id,
        name: 'Milk',
        quantity: '10 liters',
        category: 'Dairy',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        status: 'available',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      InventoryItem(
        id: '4',
        restaurantId: widget.profile.id,
        name: 'Apples',
        quantity: '8 kg',
        category: 'Fruits',
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        status: 'available',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      InventoryItem(
        id: '5',
        restaurantId: widget.profile.id,
        name: 'Canned Beans',
        quantity: '12 cans',
        category: 'Canned Goods',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        status: 'available',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
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
        description: 'Assorted fresh vegetables from today\'s delivery',
        quantity: '25 kg',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        status: 'claimed',
        postedAt: DateTime.now().subtract(const Duration(hours: 2)),
        claimedBy: 'demo-ngo-1',
        claimedAt: DateTime.now().subtract(const Duration(hours: 1)),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                   Text(
                   'Restaurant Dashboard',
                   style: Theme.of(context).textTheme.headlineSmall,
                 ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re making a difference in reducing food waste.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Stats
          Row(
            children: [
              Expanded(child: _buildStatCard('Items Expiring Soon', '${_analytics['expiringSoon']}', Icons.warning, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Active Donations', '${_donations.where((d) => d.status == 'available').length}', Icons.favorite, Colors.red)),
            ],
          ),
          const SizedBox(height: 16),

          // Impact Metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Impact This Month',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildImpactMetric('Waste Saved', '${_analytics['totalWasteSaved']} kg', Icons.recycling)),
                      Expanded(child: _buildImpactMetric('People Helped', '${_analytics['peopleHelped']}', Icons.people)),
                      Expanded(child: _buildImpactMetric('Cost Saved', '\$${_analytics['costSavings']}', Icons.attach_money)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_donations.isNotEmpty) ...[
                    _buildActivityItem('Donation claimed', 'Fresh Vegetables claimed by Local NGO', DateTime.now().subtract(const Duration(hours: 1))),
                    _buildActivityItem('New donation posted', 'Bread loaves available for donation', DateTime.now().subtract(const Duration(hours: 3))),
                  ] else ...[
                    const Text('No recent activity'),
                  ],
                ],
              ),
            ),
          ),
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
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(time),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildInventoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Group inventory by category
    final Map<String, List<InventoryItem>> categorizedInventory = {};
    for (final item in _inventory) {
      categorizedInventory.putIfAbsent(item.category, () => []).add(item);
    }

    return Column(
      children: [
        // Smart Alerts
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
              itemCount: categorizedInventory.length,
              itemBuilder: (context, index) {
                final category = categorizedInventory.keys.elementAt(index);
                final items = categorizedInventory[category]??[];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: _getCategoryIcon(category),
                    title: Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('${items.length} items'),
                    children: items.map((item) {
                      final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
                      
                      return ListTile(
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
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Fruits':
        return const Icon(Icons.apple, color: Colors.red);
      case 'Vegetables':
        return const Icon(Icons.eco, color: Colors.green);
      case 'Dairy':
        return const Icon(Icons.local_drink, color: Colors.blue);
      case 'Bread & Pastries':
        return const Icon(Icons.breakfast_dining, color: Colors.orange);
      case 'Canned Goods':
        return const Icon(Icons.inventory_2, color: Colors.grey);
      case 'Frozen Foods':
        return const Icon(Icons.ac_unit, color: Colors.cyan);
      default:
        return const Icon(Icons.category, color: Colors.purple);
    }
  }

  Widget _buildDonationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Donation Stats
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
                final donation = _donations[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getDonationStatusColor(donation.status),
                      child: Icon(
                        _getDonationStatusIcon(donation.status),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(donation.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity: ${donation.quantity}'),
                        Text('Status: ${donation.status.toUpperCase()}'),
                        if (donation.claimedAt != null)
                          Text('Claimed: ${donation.claimedAt.toString().split(' ')[0]}'),
                      ],
                    ),
                    trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View Details'),
                      ),
                      if (donation.status == 'available')
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                      if (donation.status == 'available')
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancel'),
                        ),
                    ],
                    onSelected: (value) => _handleDonationAction(value, donation),
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

  Widget _buildRecipesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Recipe Suggestions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-powered recipes using your available ingredients',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recipe suggestions based on inventory
          if (_inventory.isNotEmpty) ...[
            Text(
              'Based on your inventory:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._inventory.take(3).map((item) => _buildRecipeSuggestion(item)),
          ] else ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add inventory items to get recipe suggestions'),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Popular recipes
          Text(
            'Popular Waste-Reducing Recipes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildRecipeCard(
            'Leftover Bread Pudding',
            'Transform stale bread into a delicious dessert',
            'Bread, Milk, Eggs, Sugar',
            '30 min',
            Icons.cake,
          ),
          _buildRecipeCard(
            'Vegetable Soup',
            'Use leftover vegetables for a hearty soup',
            'Any vegetables, Broth, Herbs',
            '45 min',
            Icons.soup_kitchen,
          ),
          _buildRecipeCard(
            'Fruit Smoothie',
            'Blend overripe fruits into a healthy drink',
            'Any fruits, Yogurt, Honey',
            '10 min',
            Icons.local_drink,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSuggestion(InventoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.restaurant_menu, color: Colors.white),
        ),
        title: Text('Recipe with ${item.name}'),
        subtitle: Text('Quick and easy recipe using ${item.name.toLowerCase()}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showRecipeDetails(item),
      ),
    );
  }

  Widget _buildRecipeCard(String title, String description, String ingredients, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              'Ingredients: $ingredients',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Time: $time',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showRecipeDetails(null),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month\'s Impact',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildAnalyticCard('Waste Saved', '${_analytics['totalWasteSaved']} kg', Icons.recycling, Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAnalyticCard('Donations', '${_analytics['donationsMade']}', Icons.favorite, Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildAnalyticCard('People Helped', '${_analytics['peopleHelped']}', Icons.people, Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAnalyticCard('Cost Saved', '\$${_analytics['costSavings']}', Icons.attach_money, Colors.orange)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Trends Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waste Reduction Trend',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        '📊 Chart visualization would go here\n(Integration with charts library)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top Items Donated
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most Donated Items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildTopItem('Bread', 15, 'times'),
                  _buildTopItem('Vegetables', 12, 'times'),
                  _buildTopItem('Fruits', 8, 'times'),
                  _buildTopItem('Dairy', 6, 'times'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopItem(String name, int count, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text('$count $unit'),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddItemDialog(),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add Item'),
    );
  }

  Color _getDonationStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'claimed':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.orange;
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
        return Icons.pending;
    }
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

  void _handleDonationAction(String action, Donation donation) {
    switch (action) {
      case 'view':
        _showDonationDetails(donation);
        break;
      case 'edit':
        _showEditDonationDialog(donation);
        break;
      case 'cancel':
        _cancelDonation(donation);
        break;
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddInventoryDialog(
        profile: widget.profile,
        onItemAdded: (newItem) async {
          try {
            // Save to database first
            if (widget.profile.id != 'demo-user-id') {
              final savedItem = await _inventoryRepo.addItem(
                restaurantId: newItem.restaurantId,
                name: newItem.name,
                quantity: newItem.quantity,
                expiryDate: newItem.expiryDate,
                status: newItem.status,
              );
              // Use the saved item with proper ID from database
              setState(() {
                _inventory.add(savedItem);
              });
            } else {
              // Demo mode - just add to local state
              setState(() {
                _inventory.add(newItem);
              });
            }
          } catch (e) {
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

  void _showEditItemDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => EditInventoryDialog(item: item),
    ).then((_) => _loadData());
  }

  void _showPostDonationDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => PostDonationDialog(item: item),
    ).then((_) => _loadData());
  }

  void _showDonationDetails(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => DonationDetailsDialog(donation: donation),
    );
  }

  void _showEditDonationDialog(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => EditDonationDialog(donation: donation),
    ).then((_) => _loadData());
  }

  void _showRecipeDetails(InventoryItem? item) {
    showDialog(
      context: context,
      builder: (context) => RecipeDetailsDialog(item: item),
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
        Navigator.of(context).pushReplacementNamed('/welcome');
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
                // Delete from database first
                if (widget.profile.id != 'demo-user-id') {
                  await _inventoryRepo.deleteItem(item.id);
                }
                // Then update local state
                setState(() {
                  _inventory.removeWhere((i) => i.id == item.id);
                });
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

  void _cancelDonation(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Donation'),
        content: Text('Are you sure you want to cancel the donation "${donation.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In demo mode, just update status
              setState(() {
                final index = _donations.indexWhere((d) => d.id == donation.id);
                if (index != -1) {
                  _donations[index] = Donation(
                    id: donation.id,
                    restaurantId: donation.restaurantId,
                    title: donation.title,
                    description: donation.description,
                    quantity: donation.quantity,
                    expiryDate: donation.expiryDate,
                    status: 'cancelled',
                    postedAt: donation.postedAt,
                  );
                }
              });
            },
            child: const Text('Cancel Donation'),
          ),
        ],
      ),
    );
  }
}

// Dialog classes (simplified for demo)
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
              // Create the new item
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
                // Save to database and update UI
                await widget.onItemAdded(newItem);
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Error is handled by the parent
                Navigator.of(context).pop();
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

class EditInventoryDialog extends StatelessWidget {
  final InventoryItem item;
  
  const EditInventoryDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Inventory Item'),
      content: Text('Edit dialog for ${item.name}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class PostDonationDialog extends StatelessWidget {
  final InventoryItem item;
  
  const PostDonationDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post as Donation'),
      content: Text('Post ${item.name} as donation?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Post'),
        ),
      ],
    );
  }
}

class DonationDetailsDialog extends StatelessWidget {
  final Donation donation;
  
  const DonationDetailsDialog({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Donation Details'),
      content: Text('Details for ${donation.title}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class EditDonationDialog extends StatelessWidget {
  final Donation donation;
  
  const EditDonationDialog({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Donation'),
      content: Text('Edit dialog for ${donation.title}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class RecipeDetailsDialog extends StatelessWidget {
  final InventoryItem? item;
  
  const RecipeDetailsDialog({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recipe Details'),
  content: Text('Recipe details${item?.name != null ? ' for ${item?.name}' : ''}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class NotificationsDialog extends StatelessWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notifications'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('• Tomatoes expiring in 2 days'),
          Text('• New donation request received'),
          Text('• Monthly impact report ready'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class SettingsDialog extends StatelessWidget {
  final UserProfile profile;
  
  const SettingsDialog({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Restaurant: ${profile.name}'),
          Text('Location: ${profile.location}'),
          const SizedBox(height: 16),
          const Text('Settings options would go here'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
