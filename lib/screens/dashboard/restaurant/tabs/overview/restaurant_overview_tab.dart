import 'package:flutter/material.dart';
import '../../view_model/restaurant_dashboard_view_model.dart';
import 'widgets/overview_quick_actions.dart';
import 'widgets/overview_recent_activity.dart';
import 'widgets/overview_stats_grid.dart';
import 'widgets/overview_welcome_card.dart';

class RestaurantOverviewTab extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;
  final String restaurantName;
  final void Function(int tabIndex) onNavigate;

  const RestaurantOverviewTab({
    super.key,
    required this.viewModel,
    required this.restaurantName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverviewWelcomeCard(
            restaurantName: restaurantName,
            totalInventory: viewModel.inventory.length,
            activeDonations:
                viewModel.donations.where((d) => d.status == 'available').length,
          ),
          const SizedBox(height: 20),

          OverviewStatsGrid(
            inventory: viewModel.inventory,
            donations: viewModel.donations,
            onNavigate: onNavigate,
          ),
          const SizedBox(height: 20),

          const OverviewRecentActivity(),
          const SizedBox(height: 20),

          const OverviewQuickActions(),
        ],
      ),
    );
  }
}
