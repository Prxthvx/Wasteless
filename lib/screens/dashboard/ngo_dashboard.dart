import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/user_profile.dart';
import '../../models/donation.dart';
import '../../services/repositories/donation_repository.dart';

class NGODashboard extends StatefulWidget {
  final UserProfile profile;
  
  const NGODashboard({super.key, required this.profile});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final DonationRepository _donationRepo = DonationRepository();
  
  List<Donation> _availableDonations = [];
  List<Donation> _claimedDonations = [];
  bool _isLoading = true;

  // Analytics data
  final Map<String, dynamic> _analytics = {
    'totalDonationsClaimed': 67,
    'peopleHelped': 234,
    'foodRescued': 890, // kg
    'activeClaims': 3,
    'restaurantsConnected': 12,
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
        _availableDonations = _getMockAvailableDonations();
        _claimedDonations = _getMockClaimedDonations();
      } else {
        _availableDonations = await _donationRepo.listAvailableDonations();
        _claimedDonations = await _donationRepo.listMyClaimedDonations(widget.profile.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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

  List<Donation> _getMockClaimedDonations() {
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
        claimedBy: widget.profile.id,
        claimedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.profile.name} Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
            Tab(icon: Icon(Icons.map), text: 'Discover'),
            Tab(icon: Icon(Icons.favorite), text: 'Available'),
            Tab(icon: Icon(Icons.history), text: 'My Claims'),
            Tab(icon: Icon(Icons.analytics), text: 'Impact'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDiscoverTab(),
          _buildAvailableDonationsTab(),
          _buildMyClaimsTab(),
          _buildImpactTab(),
        ],
      ),
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
                   'NGO Dashboard',
                   style: Theme.of(context).textTheme.headlineSmall,
                 ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re helping reduce food waste and feed those in need.',
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
              Expanded(child: _buildStatCard('Available Donations', '${_availableDonations.length}', Icons.favorite, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Active Claims', '${_analytics['activeClaims']}', Icons.check_circle, Colors.blue)),
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
                      Expanded(child: _buildImpactMetric('Food Rescued', '${_analytics['foodRescued']} kg', Icons.recycling)),
                      Expanded(child: _buildImpactMetric('People Helped', '${_analytics['peopleHelped']}', Icons.people)),
                      Expanded(child: _buildImpactMetric('Restaurants', '${_analytics['restaurantsConnected']}', Icons.restaurant)),
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
                  if (_claimedDonations.isNotEmpty) ...[
                    _buildActivityItem('Donation claimed', 'Canned Goods claimed from Restaurant 4', DateTime.now().subtract(const Duration(hours: 6))),
                    _buildActivityItem('New donation available', 'Fresh Vegetables available nearby', DateTime.now().subtract(const Duration(hours: 2))),
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
        Icon(icon, color: Colors.blue, size: 24),
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
              color: Colors.blue,
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

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map View Placeholder
          Card(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Interactive Map View',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Shows nearby restaurants and available donations',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search and Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search & Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search donations...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Categories')),
                            DropdownMenuItem(value: 'vegetables', child: Text('Vegetables')),
                            DropdownMenuItem(value: 'fruits', child: Text('Fruits')),
                            DropdownMenuItem(value: 'dairy', child: Text('Dairy')),
                            DropdownMenuItem(value: 'bread', child: Text('Bread & Pastries')),
                          ],
                          onChanged: (value) {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Distance',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '5', child: Text('5 km')),
                            DropdownMenuItem(value: '10', child: Text('10 km')),
                            DropdownMenuItem(value: '20', child: Text('20 km')),
                          ],
                          onChanged: (value) {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nearby Restaurants
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearby Restaurants',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildRestaurantCard('Green Garden Restaurant', '2.3 km away', '3 donations available'),
                  _buildRestaurantCard('Fresh Market Cafe', '1.8 km away', '1 donation available'),
                  _buildRestaurantCard('Local Bakery', '4.1 km away', '2 donations available'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(String name, String distance, String donations) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(distance),
            Text(donations, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showRestaurantDetails(name),
      ),
    );
  }

  Widget _buildAvailableDonationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Quick Actions
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_availableDonations.length} donations available',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tap on any donation to claim it',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _availableDonations.length,
            itemBuilder: (context, index) {
              final donation = _availableDonations[index];
              final daysUntilExpiry = donation.expiryDate.difference(DateTime.now()).inDays;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: daysUntilExpiry <= 2 ? Colors.orange : Colors.green,
                    child: Icon(
                      daysUntilExpiry <= 2 ? Icons.warning : Icons.favorite,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(donation.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: ${donation.quantity}'),
                      Text(
                        'Expires: ${donation.expiryDate.toString().split(' ')[0]} (${daysUntilExpiry} days)',
                        style: TextStyle(
                          color: daysUntilExpiry <= 2 ? Colors.orange : Colors.grey[600],
                          fontWeight: daysUntilExpiry <= 2 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (donation.description != null)
                        Text(donation.description!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _claimDonation(donation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Claim'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyClaimsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Claims Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Claims: ${_claimedDonations.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Active: ${_claimedDonations.where((d) => d.status == 'claimed').length}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _claimedDonations.length,
            itemBuilder: (context, index) {
              final donation = _claimedDonations[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getClaimStatusColor(donation.status),
                    child: Icon(
                      _getClaimStatusIcon(donation.status),
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
                        value: 'details',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem(
                        value: 'contact',
                        child: Text('Contact Restaurant'),
                      ),
                      if (donation.status == 'claimed')
                        const PopupMenuItem(
                          value: 'complete',
                          child: Text('Mark Complete'),
                        ),
                    ],
                    onSelected: (value) => _handleClaimAction(value, donation),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImpactTab() {
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
                      Expanded(child: _buildAnalyticCard('Donations Claimed', '${_analytics['totalDonationsClaimed']}', Icons.favorite, Colors.red)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAnalyticCard('People Helped', '${_analytics['peopleHelped']}', Icons.people, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildAnalyticCard('Food Rescued', '${_analytics['foodRescued']} kg', Icons.recycling, Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAnalyticCard('Restaurants', '${_analytics['restaurantsConnected']}', Icons.restaurant, Colors.orange)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Impact Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Impact Trend',
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
                        '📊 Impact chart would go here\n(Integration with charts library)',
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

          // Top Categories
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most Claimed Categories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildTopCategory('Vegetables', 25, 'kg'),
                  _buildTopCategory('Bread & Pastries', 18, 'kg'),
                  _buildTopCategory('Fruits', 15, 'kg'),
                  _buildTopCategory('Dairy', 12, 'kg'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Achievements
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildAchievement('First Donation', 'Claimed your first donation', Icons.star, Colors.amber),
                  _buildAchievement('Helping Hand', 'Helped 50+ people', Icons.people, Colors.blue),
                  _buildAchievement('Waste Warrior', 'Rescued 100kg of food', Icons.recycling, Colors.green),
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

  Widget _buildTopCategory(String name, int amount, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text('$amount $unit'),
        ],
      ),
    );
  }

  Widget _buildAchievement(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
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
        ],
      ),
    );
  }

  Color _getClaimStatusColor(String status) {
    switch (status) {
      case 'claimed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getClaimStatusIcon(String status) {
    switch (status) {
      case 'claimed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  void _claimDonation(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Donation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claim "${donation.title}"?'),
            const SizedBox(height: 16),
            const Text('This will notify the restaurant of your interest.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In demo mode, move to claimed list
              setState(() {
                _availableDonations.removeWhere((d) => d.id == donation.id);
                _claimedDonations.add(Donation(
                  id: donation.id,
                  restaurantId: donation.restaurantId,
                  title: donation.title,
                  description: donation.description,
                  quantity: donation.quantity,
                  expiryDate: donation.expiryDate,
                  status: 'claimed',
                  postedAt: donation.postedAt,
                  claimedBy: widget.profile.id,
                  claimedAt: DateTime.now(),
                ));
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Donation claimed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }

  void _handleClaimAction(String action, Donation donation) {
    switch (action) {
      case 'details':
        _showClaimDetails(donation);
        break;
      case 'contact':
        _showContactRestaurant(donation);
        break;
      case 'complete':
        _markClaimComplete(donation);
        break;
    }
  }

  void _showRestaurantDetails(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restaurant Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $name'),
            Text('Distance: 2.3 km'),
            Text('Rating: ⭐⭐⭐⭐⭐'),
            Text('Donations available: 3'),
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

  void _showClaimDetails(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${donation.title}'),
            Text('Quantity: ${donation.quantity}'),
            Text('Status: ${donation.status}'),
            if (donation.claimedAt != null)
              Text('Claimed: ${donation.claimedAt.toString().split(' ')[0]}'),
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

  void _showContactRestaurant(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Restaurant'),
        content: const Text('Contact information and messaging would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markClaimComplete(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Complete'),
        content: const Text('Mark this claim as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In demo mode, update status
              setState(() {
                final index = _claimedDonations.indexWhere((d) => d.id == donation.id);
                if (index != -1) {
                  _claimedDonations[index] = Donation(
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
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
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
}

// Dialog classes
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
          Text('NGO: ${profile.name}'),
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
              try {
                await SupabaseService.client.auth.signOut();
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
