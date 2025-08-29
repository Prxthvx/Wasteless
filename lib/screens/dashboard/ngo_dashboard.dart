import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../models/donation.dart';
import '../../services/supabase_service.dart';
import '../../services/repositories/donation_repository.dart';

class NGODashboard extends StatefulWidget {
  final UserProfile profile;

  const NGODashboard({super.key, required this.profile});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _donationRepo = DonationRepository();

  List<Donation> _available = [];
  List<Donation> _history = [];
  bool _loadingAvailable = true;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDonations();
    _loadHistory();
  }

  Future<void> _loadDonations() async {
    setState(() => _loadingAvailable = true);
    try {
      final list = await _donationRepo.listAvailableDonations();
      setState(() => _available = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load donations: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAvailable = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final ngoId = SupabaseService.client.auth.currentUser?.id ?? widget.profile.id;
      final list = await _donationRepo.listMyClaimedDonations(ngoId);
      setState(() => _history = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Nearby Restaurants'),
            Tab(icon: Icon(Icons.food_bank), text: 'Donations Available'),
            Tab(icon: Icon(Icons.history), text: 'Donations Received'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Welcome section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${widget.profile.name}!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: ${widget.profile.location}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect with local restaurants and receive food donations to help those in need.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNearbyRestaurantsTab(),
                _buildDonationsAvailableTab(),
                _buildDonationsReceivedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyRestaurantsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nearby Restaurants',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Restaurant Discovery Coming Soon',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find restaurants in your area that are willing to donate surplus food.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsAvailableTab() {
    if (_loadingAvailable) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)));
    }
    if (_available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.food_bank, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('No donations available right now', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loadDonations,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _loadDonations,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _available.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final d = _available[index];
          final bestBefore = d.bestBefore != null ? _formatDateTime(d.bestBefore!) : 'Not specified';
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              title: Text(d.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Qty: ${d.quantity} ${d.unit}\nPickup: ${d.pickupLocation}\nBest before: $bestBefore'),
              isThreeLine: true,
              leading: const Icon(Icons.fastfood, color: Colors.green),
              trailing: ElevatedButton(
                onPressed: () => _claimDonation(d),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Claim'),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _claimDonation(Donation donation) async {
    final messageCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Donation'),
        content: TextField(
          controller: messageCtrl,
          decoration: const InputDecoration(labelText: 'Message (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final ngoId = SupabaseService.client.auth.currentUser?.id ?? widget.profile.id;
                await _donationRepo.claimDonation(
                  donationId: donation.id,
                  ngoId: ngoId,
                  message: messageCtrl.text.trim().isEmpty ? null : messageCtrl.text.trim(),
                );
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to claim: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim submitted'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Widget _buildDonationsReceivedTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)));
    }
    if (_history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('No claimed donations yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final d = _history[index];
          final bestBefore = d.bestBefore != null ? _formatDateTime(d.bestBefore!) : 'Not specified';
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              title: Text(d.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Qty: ${d.quantity} ${d.unit}\nPickup: ${d.pickupLocation}\nBest before: $bestBefore'),
              isThreeLine: true,
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime d) {
    final date = _formatDate(d);
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
