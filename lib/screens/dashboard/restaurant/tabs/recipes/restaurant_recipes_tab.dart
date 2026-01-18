import 'package:flutter/material.dart';
import '../../view_model/restaurant_dashboard_view_model.dart';
import 'widgets/recipes_header.dart';
import 'widgets/inventory_recipe_generator.dart';
import 'widgets/multi_ingredient_recipe_generator.dart';
import '../../../../../models/inventory_item.dart';

class RestaurantRecipesTab extends StatelessWidget {
  final RestaurantDashboardViewModel viewModel;
  final void Function(InventoryItem item) onGenerateRecipe;
  final VoidCallback onGenerateAdvancedRecipe;

  const RestaurantRecipesTab({
    super.key,
    required this.viewModel,
    required this.onGenerateRecipe,
    required this.onGenerateAdvancedRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:  [
          RecipesHeader(),
          SizedBox(height: 32),
          InventoryRecipeGenerator(viewModel: viewModel, onGenerateRecipe: onGenerateRecipe),
          SizedBox(height: 32),
          MultiIngredientRecipeGenerator(viewModel: viewModel, onGenerateAdvancedRecipe: onGenerateAdvancedRecipe,),
        ],
      ),
    );
  }
}
