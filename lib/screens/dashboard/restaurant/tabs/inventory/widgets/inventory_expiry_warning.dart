import 'package:flutter/material.dart';
import '../../../../../../models/inventory_item.dart';

class InventoryExpiryWarning extends StatelessWidget {
  final List<InventoryItem> inventory;

  const InventoryExpiryWarning({
    super.key,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    final expiringSoonCount = inventory
        .where(
          (item) => item.expiryDate.difference(DateTime.now()).inDays <= 2,
        )
        .length;

    if (expiringSoonCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$expiringSoonCount items expiring soon!',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
