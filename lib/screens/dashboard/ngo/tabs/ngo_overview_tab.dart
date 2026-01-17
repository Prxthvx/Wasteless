import 'package:flutter/material.dart';
import '../../../../models/donation.dart';
import '../view_model/ngo_dashboard_view_model.dart';
import '../../components/clickable_stat_card.dart';
import '../../components/quick_stat.dart';
import '../../components/recent_activity_card.dart';
import '../../components/quick_actions_card.dart';


class NGOOverviewTab extends StatelessWidget {
  final String ngoName;
  final NGODashboardViewModel viewModel;
  final void Function(int tabIndex) onNavigate;

  const NGOOverviewTab({
    super.key,
    required this.ngoName,
    required this.viewModel,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final availableDonations = viewModel.availableDonations.length;
    final claimedDonations = viewModel.claimedDonations;
    final totalClaims = claimedDonations.length;

    final analytics = viewModel.analytics;
    final activeClaims = analytics['activeClaims'] ?? 0;
    final foodRescued = analytics['foodRescued'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeCard(
            ngoName: ngoName,
            availableDonations: availableDonations,
            activeClaims: activeClaims,
          ),
          const SizedBox(height: 20),

          _StatsGrid(
            availableDonations: availableDonations,
            activeClaims: activeClaims,
            totalClaims: totalClaims,
            foodRescued: foodRescued,
            onNavigate: onNavigate,
          ),
          const SizedBox(height: 20),

          _RecentActivitySection(
            claimedDonations: claimedDonations,
            availableDonations: viewModel.availableDonations,
            onNavigate: onNavigate,
          ),
          const SizedBox(height: 20),

          _QuickActionsSection(onNavigate: onNavigate),
        ],
      ), 
    );
  }

}

class _WelcomeCard extends StatelessWidget {
    final String ngoName;
    final int availableDonations;
    final int activeClaims;

    const _WelcomeCard({
      required this.ngoName,
      required this.availableDonations,
      required this.activeClaims,
    });

    @override
     Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $ngoName!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                QuickStat(
                  label: 'Available Donations',
                  value: '$availableDonations',
                  icon: Icons.favorite,
                ),
                const SizedBox(width: 16),
                QuickStat(
                  label: 'Active Claims',
                  value: '$activeClaims',
                  icon: Icons.check_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int availableDonations;
  final int activeClaims;
  final int totalClaims;
  final int foodRescued;
  final void Function(int) onNavigate;

  const _StatsGrid({
    required this.availableDonations,
    required this.activeClaims,
    required this.totalClaims,
    required this.foodRescued,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        ClickableStatCard(
          title: 'Available Donations',
          value: '$availableDonations',
          icon: Icons.favorite,
          color: Colors.red,
          onTap: () => onNavigate(2),
        ),
        ClickableStatCard(
          title: 'Active Claims',
          value: '$activeClaims',
          icon: Icons.check_circle,
          color: Colors.blue,
          onTap: () => onNavigate(3),
        ),
        ClickableStatCard(
          title: 'Total Claims',
          value: '$totalClaims',
          icon: Icons.history,
          color: Colors.purple,
          onTap: () => onNavigate(3),
        ),
        ClickableStatCard(
          title: 'Food Rescued',
          value: '${foodRescued}kg',
          icon: Icons.recycling,
          color: Colors.green,
          onTap: () => onNavigate(4),
        ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final List<Donation> claimedDonations;
  final List<Donation> availableDonations;
  final void Function(int tabIndex) onNavigate;

  const _RecentActivitySection({
    required this.claimedDonations,
    required this.availableDonations,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        RecentActivityCard(
          recentClaims: claimedDonations.take(3).toList(),
          recentAvailable: availableDonations.take(2).toList(),
          onNavigate: (tabIndex) => onNavigate(tabIndex),
        ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final void Function(int tabIndex) onNavigate;

  const _QuickActionsSection({
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        QuickActionsCard(
          onNavigate: (tabIndex) => onNavigate(tabIndex),
        ),
      ],
    );
  }
}

