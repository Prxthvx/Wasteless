import 'package:flutter/material.dart';
import '../../../view_model/restaurant_dashboard_view_model.dart';
import '../../../../../../models/inventory_item.dart';

class InventoryRecipeGenerator extends StatelessWidget {
  
  final RestaurantDashboardViewModel viewModel;
  final void Function(InventoryItem item) onSelectIngredients;

  const InventoryRecipeGenerator({
      super.key,
      required this.viewModel,
      required this.onSelectIngredients,
    });

  IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'vegetables':
      return Icons.eco;
    case 'fruits':
      return Icons.apple;
    case 'dairy':
      return Icons.icecream;
    case 'bread & pastries':
      return Icons.bakery_dining;
    case 'canned goods':
      return Icons.inventory;
    case 'meat':
      return Icons.set_meal;
    case 'frozen foods':
      return Icons.ac_unit;
    case 'bakery':
      return Icons.bakery_dining;
    default:
      return Icons.inventory_2;
  }
}


  @override
  Widget build(BuildContext context) {
    // MOVE the entire body of your existing
    // _buildInventoryRecipeGenerator() here
 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Generate Recipe from Inventory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select an item from your inventory to generate a professional recipe:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            viewModel.inventory.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No inventory items available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add some items to your inventory first',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : Flexible(
                    child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: viewModel.inventory.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.inventory[index];
                      final isExpiring = item.expiryDate.difference(DateTime.now()).inDays <= 2;
                      
                      return GestureDetector(
                        onTap: () => onSelectIngredients(item),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isExpiring ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isExpiring ? Colors.orange : Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                             Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(item.category),
                                      color: isExpiring ? Colors.orange : Colors.grey[600],
                                      size: 11,
                                    ),
                                    const SizedBox(width: 3),
                                    if (isExpiring)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'URGENT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 1),
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.quantity} • ${item.category}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 7,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.purple,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                    'Get Recipe',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
