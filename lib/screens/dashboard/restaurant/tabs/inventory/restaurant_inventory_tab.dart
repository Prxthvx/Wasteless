import 'package:flutter/material.dart';
import 'package:wasteless/models/inventory_item.dart';
import '../../view_model/restaurant_dashboard_view_model.dart';
import 'widgets/inventory_expiry_warning.dart';
import 'widgets/inventory_list.dart';

class RestaurantInventoryTab extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;
  final Future<void> Function() onRefresh;
  final void Function(String action, InventoryItem item) onItemAction;

  const RestaurantInventoryTab({
    super.key,
    required this.viewModel,
    required this.onRefresh,
    required this.onItemAction,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        InventoryExpiryWarning(inventory: viewModel.inventory),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: InventoryList(
              inventory: viewModel.inventory,
              onAction: onItemAction,
            ),
          ),
        ),
      ],
    );
  }
}
