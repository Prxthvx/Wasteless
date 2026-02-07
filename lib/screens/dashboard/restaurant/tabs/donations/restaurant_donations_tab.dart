import 'package:flutter/material.dart';
import '../../view_model/restaurant_dashboard_view_model.dart';
import 'widgets/donations_summary_card.dart';
import 'widgets/donations_list.dart';
import '../../../../../../models/donation.dart';
import 'dialogs/donation_details_dialog.dart';

class RestaurantDonationsTab extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;
  final Future<void> Function() onRefresh;
  final String currentUserId;

  const RestaurantDonationsTab({
    super.key,
    required this.viewModel,
    required this.onRefresh,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        DonationsSummaryCard(donations: viewModel.donations),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: DonationsList(
              donations: viewModel.donations,
              onAction: (action, donation) => _handleDonationAction(context, action, donation),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDonationAction(
  BuildContext context,
  String action,
  Donation donation,
) {
  switch (action) {
    case 'view':
      showDonationDetailsDialog(
        context: context,
        donation: donation,
        currentUserId: currentUserId,
      );
      break;
  }
}

}
