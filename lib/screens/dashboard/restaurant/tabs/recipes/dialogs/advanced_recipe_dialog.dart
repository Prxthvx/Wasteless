import 'package:flutter/material.dart';
import '../../../../../../models/inventory_item.dart';
import '../../../../../../services/recipe_api_service.dart';
import '../widgets/recipe_tag.dart';

class AdvancedRecipeDialog extends StatefulWidget {
  final List<InventoryItem> inventory;
  final void Function(Map<String, dynamic> recipe) onRecipeSelected;

  const AdvancedRecipeDialog({
    super.key,
    required this.inventory,
    required this.onRecipeSelected,
  });

  @override
  State<AdvancedRecipeDialog> createState() => _AdvancedRecipeDialogState();
}

class _AdvancedRecipeDialogState extends State<AdvancedRecipeDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _recipes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final data = await RecipeApiService.getRecipesByIngredients(widget.inventory);
      setState(() {
        _recipes = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        title: Text('Generating Multi-Ingredient Recipes...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching professional recipe databases...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Multi-Ingredient Recipes'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: _recipes.isEmpty
            ? const Center(child: Text('No recipes found'))
            : ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(recipe['name']),
                      subtitle: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          RecipeTag(
                            text: recipe['time'],
                            icon: Icons.access_time,
                            color: Colors.blue,
                          ),
                          RecipeTag(
                            text: recipe['difficulty'],
                            icon: Icons.speed,
                            color: Colors.green,
                          ),
                          RecipeTag(
                            text: '${recipe['wasteReduction']}% waste',
                            icon: Icons.eco,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onRecipeSelected(recipe);
                      },
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
