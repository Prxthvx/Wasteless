import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

class _NGODashboardState extends State<NGODashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late NGODashboardViewModel _viewModel;
  final DonationRepository _donationRepo = DonationRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _viewModel = NGODashboardViewModel(_donationRepo);
    // Defer data loading to avoid "too much work on main thread"
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }

    if (!mounted) return;
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                _DashboardTab(
                  icon: Icons.dashboard,
                  label: 'Overview',
                  isSelected: _tabController.index == 0,
                ),
                _DashboardTab(
                  icon: Icons.map,
                  label: 'Discover',
                  isSelected: _tabController.index == 1,
                ),
                _DashboardTab(
                  icon: Icons.favorite,
                  label: 'Available',
                  isSelected: _tabController.index == 2,
                ),
                _DashboardTab(
                  icon: Icons.history,
                  label: 'My Claims',
                  isSelected: _tabController.index == 3,
                ),
                _DashboardTab(
                  icon: Icons.analytics,
                  label: 'Impact',
                  isSelected: _tabController.index == 4,
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NGOOverviewTab(
            ngoName: widget.profile.name,
            viewModel: _viewModel,
            onNavigate: (index) => _tabController.animateTo(index),
          ),
          NgoDiscoverTab(viewModel: _viewModel, onRefresh: _loadData),
          NgoAvailableDonationsTab(
            isLoading: _viewModel.isLoading,
            donations: _viewModel.availableDonations,
            onRefresh: _loadData,
            onClaim: _claimDonation,
          ),
          NgoMyClaimsTab(
            isLoading: _viewModel.isLoading,
            claimedDonations: _viewModel.claimedDonations,
            onAction: _handleClaimAction,
          ),
          NgoImpactTab(
            analytics: _viewModel.analytics,
            monthlyClaimsData: _viewModel.monthlyClaimsData,
          ),
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
      onRefresh: () async {
        // Refresh data from backend after claim
        await _loadData();
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
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
}

class _DashboardTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _DashboardTab({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 72,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
