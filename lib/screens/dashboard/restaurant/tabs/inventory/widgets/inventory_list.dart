import 'package:flutter/material.dart';
import '../../../../../../models/inventory_item.dart';

class InventoryList extends StatelessWidget {
  final List<InventoryItem> inventory;
  final void Function(String action, InventoryItem item) onAction;

  const InventoryList({
    super.key,
    required this.inventory,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inventory.length,
      itemBuilder: (context, index) {
        final item = inventory[index];
        final daysUntilExpiry =
            item.expiryDate.difference(DateTime.now()).inDays;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  daysUntilExpiry <= 2 ? Colors.orange : Colors.green,
              child: Icon(
                daysUntilExpiry <= 2
                    ? Icons.warning
                    : Icons.inventory,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(item.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantity: ${item.quantity}'),
                Text(
                  'Category: ${item.category}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Expires: ${item.expiryDate.toString().split(' ')[0]} ($daysUntilExpiry days)',
                  style: TextStyle(
                    color: daysUntilExpiry <= 2
                        ? Colors.orange
                        : Colors.grey[600],
                    fontWeight: daysUntilExpiry <= 2
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'donate', child: Text('Post as Donation')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) => onAction(value, item),
            ),
          ),
        );
      },
    );
  }
}
