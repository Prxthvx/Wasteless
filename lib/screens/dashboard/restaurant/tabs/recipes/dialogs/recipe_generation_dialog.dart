import 'package:flutter/material.dart';
import '../../../../../../models/inventory_item.dart';
import '../../../../../../services/recipe_api_service.dart';
import '../widgets/recipe_tag.dart';

class RecipeGenerationDialog extends StatefulWidget {
  final InventoryItem item;
  final Future<List<Map<String, dynamic>>> Function(InventoryItem) generateRecipe;
  final VoidCallback onShowAdvanced;

  const RecipeGenerationDialog({
    super.key,
    required this.item,
    required this.generateRecipe,
    required this.onShowAdvanced,
  });

  @override
  State<RecipeGenerationDialog> createState() => _RecipeGenerationDialogState();
}

class _RecipeGenerationDialogState extends State<RecipeGenerationDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _recipes = [];
  String? _error;
  final TextEditingController _customIngredientsController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _customIngredientsController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final data = await widget.generateRecipe(widget.item);
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

  Future<void> _loadRecipesWithCustomIngredients() async {
    if (_customIngredientsController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Combine inventory item with custom ingredients
      final customIngredients = _customIngredientsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final allIngredients = [widget.item.name, ...customIngredients];
      
      final data = await RecipeApiService.getRecipesByIngredientsString(allIngredients);
      
      setState(() {
        _recipes = data;
        _loading = false;
        _showCustomInput = false;
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
      return AlertDialog(
        title: Text('Finding recipes for ${widget.item.name}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching AI recipe databases...'),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Recipes for ${widget.item.name}'),
          const SizedBox(height: 4),
          Text(
            'Top ${_recipes.length} AI-recommended recipes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 550,
        child: Column(
          children: [
            // Custom ingredients input section
            if (_showCustomInput) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Add Custom Ingredients',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _showCustomInput = false;
                                _customIngredientsController.clear();
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customIngredientsController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., garlic, soya sauce, ginger',
                          border: OutlineInputBorder(),
                          isDense: true,
                          helperText: 'Separate ingredients with commas',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadRecipesWithCustomIngredients,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Generate New Recipes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCustomInput = true;
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Custom Ingredients'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Recipes list
            Expanded(
              child: _recipes.isEmpty
                  ? const Center(child: Text('No recipes found'))
                  : ListView.builder(
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _recipes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              recipe['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Wrap(
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
                                      text: '${recipe['wasteReduction']}% waste reduction',
                                      icon: Icons.eco,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                                if (recipe['source'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Source: ${recipe['source']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: widget.onShowAdvanced,
          child: const Text('Advanced Options'),
        ),
      ],
    );
  }
}
