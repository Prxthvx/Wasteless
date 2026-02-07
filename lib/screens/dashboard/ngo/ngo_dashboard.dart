import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../models/donation.dart';
import '../../../services/repositories/donation_repository.dart';
import '../../../services/supabase_service.dart';
import '../../../services/chat_navigation_helper.dart';
import '../dialogs/notifications_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../helpers/claim_helper.dart';
import 'view_model/ngo_dashboard_view_model.dart';
import 'tabs/ngo_discover_tab.dart';
import 'tabs/ngo_available_donations_tab.dart';
import 'tabs/ngo_my_claims_tab.dart';
import 'tabs/ngo_impact_tab.dart';
import 'tabs/ngo_overview_tab.dart';
import 'widgets/ngo_dashboard_drawer.dart';
import '../../chat/widgets/unread_badge.dart';

class NGODashboard extends StatefulWidget {
  final UserProfile profile;
  
  const NGODashboard({super.key, required this.profile});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  late NGODashboardViewModel _viewModel;
  final DonationRepository _donationRepo = DonationRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _viewModel = NGODashboardViewModel(_donationRepo);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
  setState(() => _viewModel.isLoading = true);

  try {
    await _viewModel.loadData(
      widget.profile.id,
      isDemo: widget.profile.id == 'demo-user-id',
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading data: $e')),
    );
  }

  setState(() {});
}

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.profile.name} Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showDrawer(),
        ),
        actions: [
          IconButtonWithBadge(
            icon: Icons.chat,
            badgeCount: 0, // TODO: Connect to ChatService for real count
            iconColor: Colors.white,
            onPressed: () {
              ChatNavigationHelper.navigateToChatList(
                context: context,
                currentUserId: widget.profile.id,
              );
            },
          ),
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
          NGOOverviewTab(ngoName: widget.profile.name,
           viewModel: _viewModel,
           onNavigate: (index) => _tabController.animateTo(index)),
          NgoDiscoverTab(viewModel: _viewModel,
           onRefresh: _loadData),
          NgoAvailableDonationsTab(
             isLoading: _viewModel.isLoading,
             donations: _viewModel.availableDonations,
             onRefresh: _loadData,
             onClaim: _claimDonation,),
          NgoMyClaimsTab(
            isLoading: _viewModel.isLoading,
            claimedDonations: _viewModel.claimedDonations,
            onAction: _handleClaimAction,
          ),
          NgoImpactTab(analytics: _viewModel.analytics),
        ],
      ),
      drawer: NgoDashboardDrawer(
        profile: widget.profile,
        tabController: _tabController,
        onShowNotifications: _showNotifications,
        onShowSettings: _showSettings,
        onSignOut: _signOut,
      ),
    );
  }



  void _claimDonation(Donation donation) {
    ClaimHelper.showClaimDialog(
      context: context,
      donation: donation,
      profile: widget.profile,
      onClaim: (donation) {
        setState(() {
          _viewModel.claimDonation(
          donation: donation,
          userId: widget.profile.id,
        );
        });
      },
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
    ChatNavigationHelper.navigateToChatFromDonation(
      context: context,
      donation: donation,
      currentUserId: widget.profile.id,
      currentUserRole: 'ngo',
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
                _viewModel.markClaimComplete(donation);
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
}


