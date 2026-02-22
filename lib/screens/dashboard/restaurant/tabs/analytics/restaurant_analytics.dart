import 'package:flutter/material.dart';
import '../../view_model/restaurant_dashboard_view_model.dart';
import 'widgets/analytics_header.dart';
import 'widgets/analytics_card.dart';
import 'widgets/waste_reduction_chart.dart';
import 'widgets/category_breakdown.dart';
import '../overview/widgets/overview_recent_activity.dart';
import 'widgets/environmental_impact_card.dart';

class RestaurantAnalyticsTab extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;
  final void Function(int tabIndex) onNavigate;

  const RestaurantAnalyticsTab({
    super.key,
    required this.viewModel,
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
          AnalyticsHeader(),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  title: 'Waste Saved',
                  value: '${((viewModel.analytics['totalWasteSaved'] ?? 0) ~/ 100) * 100}+',
                  icon: Icons.eco,
                  color: Colors.green,
                  subtitle: 'Food waste prevented',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalyticsCard(
                  title: 'Donations',
                  value: '${viewModel.analytics['donationsMade']}',
                  icon: Icons.favorite,
                  color: Colors.red,
                  subtitle: 'Items donated',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: AnalyticsCard(
                  title: "Number of times NGO's claimed donations",
                  value: '${viewModel.analytics['claimedDonationsCount'] ?? 0}',
                  icon: Icons.people,
                  color: Colors.blue,
                  subtitle: 'Items claimed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          WasteReductionChart(viewModel: viewModel),
          const SizedBox(height: 24),

          CategoryBreakdown(viewModel: viewModel),
          const SizedBox(height: 24),

          OverviewRecentActivity(
            recentInventory: viewModel.inventory.take(3).toList(),
            recentDonations: viewModel.donations.take(2).toList(),
            onViewInventory: () => onNavigate(1),
            onViewDonations: () => onNavigate(2),
          ),
          const SizedBox(height: 24),

        ],
      ),
    );
  }
}
