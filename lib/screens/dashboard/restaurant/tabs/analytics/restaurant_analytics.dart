import 'package:flutter/material.dart';
import '../../view_model/restaurant_dashboard_view_model.dart';
import 'widgets/analytics_header.dart';
import 'widgets/analytics_card.dart';
import 'widgets/waste_reduction_chart.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/environmental_impact_card.dart';

class RestaurantAnalyticsTab extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;

  const RestaurantAnalyticsTab({
    super.key,
    required this.viewModel,
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
                  value: '${viewModel.analytics['totalWasteSaved']} kg',
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
                child: AnalyticsCard(
                  title: 'People Helped',
                  value: '${viewModel.analytics['peopleHelped']}',
                  icon: Icons.people,
                  color: Colors.blue,
                  subtitle: 'Community members',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalyticsCard(
                  title: 'Cost Savings',
                  value: '\$${viewModel.analytics['costSavings']}',
                  icon: Icons.attach_money,
                  color: Colors.orange,
                  subtitle: 'Money saved',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          WasteReductionChart(),
          const SizedBox(height: 24),

          CategoryBreakdown(viewModel: viewModel),
          const SizedBox(height: 24),

          RecentActivityCard(),
          const SizedBox(height: 24),

          EnvironmentalImpactCard(viewModel: viewModel),
        ],
      ),
    );
  }
}
