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
  bool _loading = false;
  bool _showConfig = true;
  List<Map<String, dynamic>> _recipes = [];
  String? _error;
  
  // Ingredient selection
  final Set<String> _selectedInventoryItems = {};
  final TextEditingController _customIngredientsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-select all inventory items
    _selectedInventoryItems.addAll(widget.inventory.map((i) => i.id));
  }

  @override
  void dispose() {
    _customIngredientsController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    if (_selectedInventoryItems.isEmpty && _customIngredientsController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please select at least one ingredient or add custom ingredients';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _showConfig = false;
    });

    try {
      // Combine selected inventory items with custom ingredients
      final selectedItems = widget.inventory
          .where((item) => _selectedInventoryItems.contains(item.id))
          .map((item) => item.name)
          .toList();
      
      final customIngredients = _customIngredientsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final allIngredients = [...selectedItems, ...customIngredients];
      
      final data = await RecipeApiService.getRecipesByIngredientsString(allIngredients);
      
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

  void _resetConfiguration() {
    setState(() {
      _showConfig = true;
      _recipes = [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        title: Text('Generating AI Recipes...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calling HuggingFace Recipe AI...'),
          ],
        ),
      );
    }

    if (_showConfig) {
      return _buildConfigurationDialog();
    }

    return _buildRecipeResultsDialog();
  }

  Widget _buildConfigurationDialog() {
    return AlertDialog(
      title: const Text('Advanced Recipe Generator'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select ingredients from your inventory and/or add custom ingredients',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Inventory items selection
            Text(
              'Your Inventory (${_selectedInventoryItems.length}/${widget.inventory.length} selected)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Select all / Deselect all buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedInventoryItems.addAll(widget.inventory.map((i) => i.id));
                    });
                  },
                  icon: const Icon(Icons.check_box, size: 18),
                  label: const Text('Select All'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedInventoryItems.clear();
                    });
                  },
                  icon: const Icon(Icons.check_box_outline_blank, size: 18),
                  label: const Text('Deselect All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Inventory list with checkboxes
            Expanded(
              child: widget.inventory.isEmpty
                  ? const Center(
                      child: Text('No inventory items available'),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: widget.inventory.length,
                        itemBuilder: (context, index) {
                          final item = widget.inventory[index];
                          final isSelected = _selectedInventoryItems.contains(item.id);
                          final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
                          final isExpiringSoon = daysUntilExpiry <= 3;
                          
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedInventoryItems.add(item.id);
                                } else {
                                  _selectedInventoryItems.remove(item.id);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Text(item.name),
                                if (isExpiringSoon) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$daysUntilExpiry days',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${item.quantity} • ${item.category}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            dense: true,
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            
            // Custom ingredients input
            const Text(
              'Custom Ingredients (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customIngredientsController,
              decoration: const InputDecoration(
                hintText: 'e.g., garlic, soya sauce, ginger, olive oil',
                border: OutlineInputBorder(),
                helperText: 'Separate ingredients with commas',
                prefixIcon: Icon(Icons.add_circle_outline),
              ),
              maxLines: 2,
            ),
            
            // Error message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _loadRecipes,
          icon: const Icon(Icons.restaurant_menu, size: 18),
          label: const Text('Generate Recipes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeResultsDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('AI-Generated Recipes'),
                const SizedBox(height: 4),
                Text(
                  'Top ${_recipes.length} recipes from HuggingFace',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetConfiguration,
            tooltip: 'New Search',
          ),
        ],
      ),
      content: SizedBox(
        width: 550,
        height: 650,
        child: _recipes.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.no_meals, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No recipes found'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _resetConfiguration,
                      child: const Text('Try Different Ingredients'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onRecipeSelected(recipe);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    recipe['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipe['description'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
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
                              const SizedBox(height: 6),
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
        OutlinedButton.icon(
          onPressed: _resetConfiguration,
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Change Ingredients'),
        ),
      ],
    );
  }
}
