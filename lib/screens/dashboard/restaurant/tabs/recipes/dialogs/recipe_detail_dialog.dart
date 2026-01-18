import 'package:flutter/material.dart';
import '../../../../../../models/inventory_item.dart';
import '../widgets/recipe_tag.dart';

class RecipeDetailDialog extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final void Function(List<InventoryItem> ingredients) onMarkUsed;

  const RecipeDetailDialog({
    super.key,
    required this.recipe,
    required this.onMarkUsed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(recipe['name']),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe['description'],
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Tags
            Wrap(
              spacing: 8,
              children: [
                RecipeTag(
                  text: '${recipe['time']}',
                  icon: Icons.access_time,
                  color: Colors.blue,
                ),
                RecipeTag(
                  text: recipe['difficulty'],
                  icon: Icons.speed,
                  color: Colors.green,
                ),
                RecipeTag(
                  text: '${recipe['wasteReduction']}% waste reduction',
                  icon: Icons.eco,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ingredients
            const Text(
              'Ingredients:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...(recipe['ingredients'] as List<String>).map(
              (ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.restaurant, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(ingredient),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (recipe['instructions'] is List)
              ...(recipe['instructions'] as List<String>).map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(step),
                ),
              )
            else
              Text(recipe['instructions']),

            if (recipe['nutritionalValue'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Nutritional Value:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(recipe['nutritionalValue']),
            ],

            if (recipe['serves'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Serves: ${recipe['serves']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onMarkUsed(
              recipe['ingredients'] as List<InventoryItem>,
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Mark as Used'),
        ),
      ],
    );
  }
}
