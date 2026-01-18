import 'package:flutter/material.dart';
import '../../../view_model/restaurant_dashboard_view_model.dart';

class MultiIngredientRecipeGenerator extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;
  final VoidCallback  onGenerateAdvancedRecipe;

  const MultiIngredientRecipeGenerator({
      super.key,
      required this.viewModel,
      required this.onGenerateAdvancedRecipe,
    });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Multi-Ingredient Recipe Generator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Generate complex recipes using multiple ingredients from your inventory:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.inventory.length >= 2 ? () => onGenerateAdvancedRecipe() : null,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Multi-Ingredient Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (viewModel.inventory.length < 2) ...[
              const SizedBox(height: 8),
              Text(
                'Add at least 2 items to your inventory to use this feature',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
