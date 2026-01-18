import 'package:flutter/material.dart';
import '../../../../models/inventory_item.dart';
import '../view_model/restaurant_dashboard_view_model.dart';
import '../dialogs/add_inventory_dialog.dart';
import '../../../../models/user_profile.dart';

Future<void> showAddInventoryDialog({
  required BuildContext context,
  required UserProfile profile,
  required RestaurantDashboardViewModel viewModel,
}) async {
   showDialog(
    context: context,
    builder: (context) => AddInventoryDialog(
      profile: profile,
      onItemAdded: (InventoryItem newItem) async {
        try {
          await viewModel.addInventory(newItem, profile.id);
          Navigator.of(context).pop();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    ),
  );
}
