import 'package:flutter/material.dart';
import '../../../../../../models/inventory_item.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRecipes();
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
            Text('Searching real recipe databases...'),
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
      title: Text('Recipes for ${widget.item.name}'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: _recipes.isEmpty
            ? const Center(child: Text('No recipes found'))
            : ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  return ListTile(
                    title: Text(recipe['name']),
                    subtitle: Wrap(
                      spacing: 8,
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
                      ],
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
        ElevatedButton(
          onPressed: widget.onShowAdvanced,
          child: const Text('Generate More'),
        ),
      ],
    );
  }
}
