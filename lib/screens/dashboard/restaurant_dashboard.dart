import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
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

  final Map<String, dynamic> _analytics = {
    'totalWasteSaved': 1250,
    'donationsMade': 45,
    'peopleHelped': 180,
    'costSavings': 3200,
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
              _buildStatCard('Items Expiring Soon', '$expiringSoon', Icons.warning, Colors.orange),
              _buildStatCard('Active Donations', '$activeDonations', Icons.favorite, Colors.red),
              _buildStatCard('Total Inventory', '$totalInventory', Icons.inventory, Colors.blue),
              _buildStatCard('Total Donations', '$totalDonations', Icons.volunteer_activism, Colors.purple),
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
                  'Recent Inventory Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No inventory items yet. Add your first item!',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...recentItems.map((item) => Padding(
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
                  ],
                ),
              )).toList(),
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
                    subtitle: Text('Quantity: ${donation.quantity}'),
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
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipesTab() {
    return const Center(child: Text('Recipes Tab - Coming Soon'));
  }

  Widget _buildAnalyticsTab() {
    return const Center(child: Text('Analytics Tab - Coming Soon'));
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
            } else {
              print('Using demo mode'); // Debug log
              setState(() {
                _inventory.add(newItem);
              });
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

  void _showPostDonationDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => PostDonationDialog(
        profile: widget.profile,
        item: item,
        onDonationPosted: (donation) async {
          try {
            if (widget.profile.id != 'demo-user-id') {
              final savedDonation = await _donationRepo.postDonation(
                restaurantId: widget.profile.id,
                title: donation.title,
                description: donation.description,
                quantity: donation.quantity,
                expiryDate: donation.expiryDate,
              );
              setState(() {
                _donations.add(savedDonation);
              });
            } else {
              setState(() {
                _donations.add(donation);
              });
            }
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Donation posted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error posting donation: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
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
            if (_formKey.currentState!.validate()) {
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

class NotificationsDialog extends StatelessWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notifications'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('• New donation available nearby'),
          Text('• Claim status updated'),
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size.fromHeight(40),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              // Sign out using Supabase
              try {
                // Import SupabaseService at the top if not already
                // import '../../services/supabase_service.dart';
                await SupabaseService.client.auth.signOut();
                // Navigate to welcome/login screen
                Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sign out failed: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
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
            if (_formKey.currentState!.validate()) {
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
  final Future<void> Function(Donation) onDonationPosted;
  
  const PostDonationDialog({
    super.key,
    required this.profile,
    required this.item,
    required this.onDonationPosted,
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
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
              
              await widget.onDonationPosted(donation);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Post Donation'),
        ),
      ],
    );
  }
}
