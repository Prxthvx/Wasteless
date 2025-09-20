import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/inventory_item.dart';

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class RecipeApiService {
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';
  static const String _apiKey = '8c30ebaf959b44af876941c677053c80';
  
  // Alternative free API
  static const String _freeBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
  
  // Get recipes based on ingredients
  static Future<List<Map<String, dynamic>>> getRecipesByIngredients(List<InventoryItem> ingredients) async {
    try {
      // ALWAYS use local generator first - it's working great!
      final localRecipes = _getSmartLocalRecipes(ingredients);
      if (localRecipes.isNotEmpty) {
        print('Using local generator - found ${localRecipes.length} recipes');
        return localRecipes;
      }
      
      // Only use APIs if local generator finds nothing (rare case)
      print('Local generator found no recipes, trying APIs...');
      final apiRecipes = await _getRecipesFromMealDB(ingredients);
      if (apiRecipes.isNotEmpty) return apiRecipes;
      
      // Final fallback
      return _getFallbackRecipes(ingredients);
    } catch (e) {
      print('Error fetching recipes: $e');
      return _getFallbackRecipes(ingredients);
    }
  }
  
  // Get recipes from TheMealDB (free API)
  static Future<List<Map<String, dynamic>>> _getRecipesFromMealDB(List<InventoryItem> ingredients) async {
    final recipes = <Map<String, dynamic>>[];
    
    for (final ingredient in ingredients) {
      try {
        final response = await http.get(
          Uri.parse('$_freeBaseUrl/filter.php?i=${ingredient.name}'),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null) {
            for (final meal in data['meals']) {
              final recipe = await _getMealDetails(meal['idMeal']);
              if (recipe != null) {
                recipes.add(recipe);
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching from MealDB: $e');
      }
    }
    
    return recipes.take(5).toList();
  }
  
  // Get detailed meal information
  static Future<Map<String, dynamic>?> _getMealDetails(String mealId) async {
    try {
      final response = await http.get(
        Uri.parse('$_freeBaseUrl/lookup.php?i=$mealId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          final meal = data['meals'][0];
          return _formatMealDBRecipe(meal);
        }
      }
    } catch (e) {
      print('Error fetching meal details: $e');
    }
    return null;
  }
  
  // Format MealDB recipe to our format
  static Map<String, dynamic> _formatMealDBRecipe(Map<String, dynamic> meal) {
    final ingredients = <String>[];
    final instructions = <String>[];
    
    // Extract ingredients
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.isNotEmpty) {
        ingredients.add('${measure ?? ''} $ingredient'.trim());
      }
    }
    
    // Extract instructions
    final instructionText = meal['strInstructions'] ?? '';
    if (instructionText.isNotEmpty) {
      instructions.addAll(instructionText.split('\n').where((s) => s.trim().isNotEmpty));
    }
    
    return {
      'name': meal['strMeal'] ?? 'Unknown Recipe',
      'description': meal['strCategory'] ?? 'Delicious meal',
      'time': '30 min', // Default time
      'difficulty': 'Medium',
      'type': 'main',
      'wasteReduction': 90,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutritionalValue': 'Balanced nutrition from fresh ingredients',
      'serves': '4-6 people',
      'image': meal['strMealThumb'],
      'source': 'TheMealDB',
    };
  }
  
  // Get recipes from Spoonacular (requires API key)
  static Future<List<Map<String, dynamic>>> _getRecipesFromSpoonacular(List<InventoryItem> ingredients) async {
    final ingredientNames = ingredients.map((i) => i.name).join(',');
    
    // Add Indian cuisine preference and limit to recipes with mostly available ingredients
    final url = '$_baseUrl/findByIngredients?ingredients=$ingredientNames&number=10&ranking=2&apiKey=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipes = <Map<String, dynamic>>[];
        
        // Get detailed information for each recipe
        for (final recipe in data) {
          final detailedRecipe = await _getSpoonacularRecipeDetails(recipe['id']);
          if (detailedRecipe != null) {
            recipes.add(detailedRecipe);
          }
        }
        
        return recipes.take(5).toList();
      }
    } catch (e) {
      print('Error fetching from Spoonacular: $e');
    }
    return [];
  }
  
  // Get detailed recipe information from Spoonacular
  static Future<Map<String, dynamic>?> _getSpoonacularRecipeDetails(int recipeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$recipeId/information?apiKey=$_apiKey'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatSpoonacularDetailedRecipe(data);
      }
    } catch (e) {
      print('Error fetching recipe details: $e');
    }
    return null;
  }
  
  // Format detailed Spoonacular recipe
  static Map<String, dynamic> _formatSpoonacularDetailedRecipe(Map<String, dynamic> recipe) {
    final ingredients = <String>[];
    final instructions = <String>[];
    
    // Extract ingredients
    if (recipe['extendedIngredients'] != null) {
      for (final ingredient in recipe['extendedIngredients']) {
        final amount = ingredient['amount']?.toString() ?? '';
        final unit = ingredient['unit'] ?? '';
        final name = ingredient['name'] ?? '';
        ingredients.add('$amount $unit $name'.trim());
      }
    }
    
    // Extract instructions
    if (recipe['analyzedInstructions'] != null && recipe['analyzedInstructions'].isNotEmpty) {
      final steps = recipe['analyzedInstructions'][0]['steps'] as List;
      for (final step in steps) {
        instructions.add('${step['number']}. ${step['step']}');
      }
    }
    
    return {
      'name': recipe['title'] ?? 'Unknown Recipe',
      'description': recipe['summary']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? 'Delicious recipe using your ingredients',
      'time': '${recipe['readyInMinutes'] ?? 30} min',
      'difficulty': _getDifficulty(recipe['readyInMinutes']),
      'type': _getRecipeType(recipe['dishTypes']),
      'wasteReduction': 95,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutritionalValue': 'Professional recipe with balanced nutrition',
      'serves': '${recipe['servings'] ?? 4} people',
      'image': recipe['image'],
      'source': 'Spoonacular',
      'cuisine': recipe['cuisines']?.isNotEmpty == true ? recipe['cuisines'][0] : null,
      'diet': recipe['diets']?.isNotEmpty == true ? recipe['diets'][0] : null,
    };
  }
  
  // Get difficulty based on cooking time
  static String _getDifficulty(int? readyInMinutes) {
    if (readyInMinutes == null) return 'Medium';
    if (readyInMinutes <= 15) return 'Easy';
    if (readyInMinutes <= 45) return 'Medium';
    return 'Hard';
  }
  
  // Get recipe type from dish types
  static String _getRecipeType(List<dynamic>? dishTypes) {
    if (dishTypes == null || dishTypes.isEmpty) return 'main';
    
    final type = dishTypes.first.toString().toLowerCase();
    if (type.contains('dessert')) return 'dessert';
    if (type.contains('appetizer') || type.contains('starter')) return 'appetizer';
    if (type.contains('side')) return 'side';
    if (type.contains('salad')) return 'salad';
    if (type.contains('soup')) return 'soup';
    return 'main';
  }
  
  
  // Smart local recipe generator for common ingredient combinations
  static List<Map<String, dynamic>> _getSmartLocalRecipes(List<InventoryItem> ingredients) {
    final recipes = <Map<String, dynamic>>[];
    final ingredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
    
    // Dynamic AI-powered recipe generation based on current inventory
    recipes.addAll(_generateDynamicRecipes(ingredients));
    
    // Chapati + Chicken = Chicken Chapati Roll
    if (ingredientNames.any((name) => name.contains('chapati')) &&
        ingredientNames.any((name) => name.contains('chicken'))) {
      recipes.add({
        'name': 'Chicken Chapati Roll',
        'description': 'Traditional Indian chicken roll - perfect for lunch or dinner',
        'time': '15 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Season chicken with salt, pepper, and garam masala',
          '2. Cook chicken in a pan until golden brown',
          '3. Warm chapati on a pan for 30 seconds',
          '4. Slice chicken into strips',
          '5. Add chicken to chapati',
          '6. Add any available vegetables',
          '7. Roll up tightly and serve hot'
        ],
        'nutritionalValue': 'High protein Indian roll',
        'serves': '1-2 people',
        'source': 'Smart Local Generator',
        'cuisine': 'Indian',
      });
    }
    
    // Bread + Egg + Cheese = Grilled Cheese Sandwich
    if (ingredientNames.any((name) => name.contains('bread')) &&
        ingredientNames.any((name) => name.contains('egg')) &&
        ingredientNames.any((name) => name.contains('cheese'))) {
      recipes.add({
        'name': 'Grilled Cheese & Egg Sandwich',
        'description': 'Classic grilled cheese with fried egg - perfect for breakfast or lunch',
        'time': '10 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Heat a pan over medium heat',
          '2. Crack egg into pan and cook sunny-side up',
          '3. Butter one side of each bread slice',
          '4. Place cheese on unbuttered side of one bread slice',
          '5. Add the fried egg on top of cheese',
          '6. Cover with second bread slice (buttered side out)',
          '7. Grill sandwich until golden brown on both sides',
          '8. Cut in half and serve hot'
        ],
        'nutritionalValue': 'High protein with cheese and egg',
        'serves': '1 person',
        'source': 'Smart Local Generator',
        'cuisine': 'International',
      });
    }
    
    // Bread + Cheese = Grilled Cheese
    if (ingredientNames.any((name) => name.contains('bread')) &&
        ingredientNames.any((name) => name.contains('cheese'))) {
      recipes.add({
        'name': 'Classic Grilled Cheese',
        'description': 'Simple and delicious grilled cheese sandwich',
        'time': '8 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 90,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Heat a pan over medium-low heat',
          '2. Butter one side of each bread slice',
          '3. Place cheese between bread slices (buttered sides out)',
          '4. Grill sandwich for 3-4 minutes per side until golden',
          '5. Serve hot and crispy'
        ],
        'nutritionalValue': 'Comfort food with cheese',
        'serves': '1 person',
        'source': 'Smart Local Generator',
        'cuisine': 'International',
      });
    }
    
    // Bread + Egg = Egg Sandwich
    if (ingredientNames.any((name) => name.contains('bread')) &&
        ingredientNames.any((name) => name.contains('egg'))) {
      recipes.add({
        'name': 'Simple Egg Sandwich',
        'description': 'Quick and nutritious egg sandwich',
        'time': '8 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 90,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Heat a pan over medium heat',
          '2. Crack egg into pan and scramble or fry as preferred',
          '3. Toast bread slices lightly',
          '4. Place cooked egg between bread slices',
          '5. Add salt and pepper to taste',
          '6. Serve immediately'
        ],
        'nutritionalValue': 'High protein breakfast',
        'serves': '1 person',
        'source': 'Smart Local Generator',
        'cuisine': 'International',
      });
    }
    
    // Onion + Egg = Onion Omelette
    if (ingredientNames.any((name) => name.contains('onion')) &&
        ingredientNames.any((name) => name.contains('egg'))) {
      recipes.add({
        'name': 'Onion Omelette',
        'description': 'Flavorful omelette with caramelized onions',
        'time': '12 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Heat oil in a pan over medium heat',
          '2. Add sliced onions and cook until golden brown',
          '3. Beat eggs with salt and pepper',
          '4. Pour eggs over onions in the pan',
          '5. Cook until eggs are set, folding in half',
          '6. Serve hot with bread or rice'
        ],
        'nutritionalValue': 'Protein-rich with vegetables',
        'serves': '1-2 people',
        'source': 'Smart Local Generator',
        'cuisine': 'International',
      });
    }
    
    // Bread + Onion = Onion Toast
    if (ingredientNames.any((name) => name.contains('bread')) &&
        ingredientNames.any((name) => name.contains('onion'))) {
      recipes.add({
        'name': 'Caramelized Onion Toast',
        'description': 'Sweet and savory onion toast',
        'time': '15 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 85,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Heat oil in a pan over low heat',
          '2. Add thinly sliced onions and cook slowly for 10-12 minutes',
          '3. Add salt and a pinch of sugar to help caramelization',
          '4. Toast bread slices until golden',
          '5. Spread caramelized onions on toast',
          '6. Season with salt and pepper',
          '7. Serve warm'
        ],
        'nutritionalValue': 'Sweet and savory comfort food',
        'serves': '1-2 people',
        'source': 'Smart Local Generator',
        'cuisine': 'International',
      });
    }
    
    // Cheese + Onion = Cheese & Onion Mix
    if (ingredientNames.any((name) => name.contains('cheese')) &&
        ingredientNames.any((name) => name.contains('onion'))) {
      recipes.add({
        'name': 'Cheese & Onion Spread',
        'description': 'Creamy cheese spread with fresh onions',
        'time': '5 min',
        'difficulty': 'Easy',
        'type': 'appetizer',
        'wasteReduction': 90,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Grate or slice cheese into small pieces',
          '2. Finely chop onions',
          '3. Mix cheese and onions together',
          '4. Add a pinch of salt and pepper',
          '5. Serve as a spread or topping',
          '6. Great with crackers or bread'
        ],
        'nutritionalValue': 'Rich and flavorful spread',
        'serves': '2-3 people',
        'source': 'Smart Local Generator',
        'cuisine': 'International',
      });
    }
    
    return recipes;
  }
  
  // Dynamic AI-powered recipe generation based on current inventory
  static List<Map<String, dynamic>> _generateDynamicRecipes(List<InventoryItem> ingredients) {
    final recipes = <Map<String, dynamic>>[];
    final ingredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
    
    // Analyze ingredients and generate smart combinations
    final proteinSources = ingredients.where((i) => 
      i.name.toLowerCase().contains('chicken') ||
      i.name.toLowerCase().contains('egg') ||
      i.name.toLowerCase().contains('cheese') ||
      i.name.toLowerCase().contains('meat') ||
      i.name.toLowerCase().contains('fish')
    ).toList();
    
    final vegetables = ingredients.where((i) => 
      i.name.toLowerCase().contains('onion') ||
      i.name.toLowerCase().contains('tomato') ||
      i.name.toLowerCase().contains('potato') ||
      i.name.toLowerCase().contains('carrot') ||
      i.name.toLowerCase().contains('pepper') ||
      i.name.toLowerCase().contains('vegetable')
    ).toList();
    
    final carbs = ingredients.where((i) => 
      i.name.toLowerCase().contains('bread') ||
      i.name.toLowerCase().contains('rice') ||
      i.name.toLowerCase().contains('pasta') ||
      i.name.toLowerCase().contains('noodle')
    ).toList();
    
    final flatbreads = ingredients.where((i) => 
      i.name.toLowerCase().contains('chapati') ||
      i.name.toLowerCase().contains('roti') ||
      i.name.toLowerCase().contains('naan') ||
      i.name.toLowerCase().contains('paratha') ||
      i.name.toLowerCase().contains('tortilla') ||
      i.name.toLowerCase().contains('wrap')
    ).toList();
    
    // Generate recipes based on what's actually in inventory
    if (proteinSources.isNotEmpty && vegetables.isNotEmpty) {
      recipes.add(_createProteinVegetableRecipe(proteinSources, vegetables));
    }
    
    if (proteinSources.isNotEmpty && carbs.isNotEmpty) {
      recipes.add(_createProteinCarbRecipe(proteinSources, carbs));
    }
    
    if (vegetables.isNotEmpty && carbs.isNotEmpty) {
      recipes.add(_createVegetableCarbRecipe(vegetables, carbs));
    }
    
    // Flatbread combinations
    if (proteinSources.isNotEmpty && flatbreads.isNotEmpty) {
      recipes.add(_createProteinFlatbreadRecipe(proteinSources, flatbreads));
    }
    
    if (vegetables.isNotEmpty && flatbreads.isNotEmpty) {
      recipes.add(_createVegetableFlatbreadRecipe(vegetables, flatbreads));
    }
    
    // Special combinations for specific ingredients
    if (ingredientNames.any((name) => name.contains('chicken'))) {
      recipes.addAll(_generateChickenRecipes(ingredients));
    }
    
    if (flatbreads.isNotEmpty) {
      recipes.addAll(_generateFlatbreadRecipes(ingredients));
    }
    
    if (ingredientNames.any((name) => name.contains('rice'))) {
      recipes.addAll(_generateRiceRecipes(ingredients));
    }
    
    if (ingredientNames.any((name) => name.contains('pasta'))) {
      recipes.addAll(_generatePastaRecipes(ingredients));
    }
    
    return recipes;
  }
  
  // Create protein + vegetable recipe
  static Map<String, dynamic> _createProteinVegetableRecipe(List<InventoryItem> proteins, List<InventoryItem> vegetables) {
    final protein = proteins.first.name;
    final vegetable = vegetables.first.name;
    
    return {
      'name': '${protein.capitalize()} & ${vegetable.capitalize()} Stir Fry',
      'description': 'Quick and healthy stir fry using your available ingredients',
      'time': '15 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 95,
      'ingredients': [...proteins, ...vegetables].map((i) => i.name).toList(),
      'instructions': [
        '1. Heat oil in a large pan over high heat',
        '2. Cut ${protein} into bite-sized pieces',
        '3. Add ${protein} to pan and cook for 3-4 minutes',
        '4. Add ${vegetable} and continue cooking for 5-6 minutes',
        '5. Season with salt, pepper, and your favorite spices',
        '6. Serve hot over rice or bread'
      ],
      'nutritionalValue': 'High protein with fresh vegetables',
      'serves': '2-3 people',
      'source': 'Dynamic AI Generator',
      'cuisine': 'International',
    };
  }
  
  // Create protein + carb recipe
  static Map<String, dynamic> _createProteinCarbRecipe(List<InventoryItem> proteins, List<InventoryItem> carbs) {
    final protein = proteins.first.name;
    final carb = carbs.first.name;
    
    return {
      'name': '${protein.capitalize()} with ${carb.capitalize()}',
      'description': 'Satisfying meal combining protein and carbohydrates',
      'time': '20 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 90,
      'ingredients': [...proteins, ...carbs].map((i) => i.name).toList(),
      'instructions': [
        '1. Prepare ${carb} according to package instructions',
        '2. Season ${protein} with salt and pepper',
        '3. Cook ${protein} in a pan until done',
        '4. Serve ${protein} over or alongside ${carb}',
        '5. Add your favorite seasonings and enjoy'
      ],
      'nutritionalValue': 'Balanced protein and carbohydrate meal',
      'serves': '2-3 people',
      'source': 'Dynamic AI Generator',
      'cuisine': 'International',
    };
  }
  
  // Create vegetable + carb recipe
  static Map<String, dynamic> _createVegetableCarbRecipe(List<InventoryItem> vegetables, List<InventoryItem> carbs) {
    final vegetable = vegetables.first.name;
    final carb = carbs.first.name;
    
    return {
      'name': '${vegetable.capitalize()} ${carb.capitalize()} Bowl',
      'description': 'Healthy and filling vegetarian meal',
      'time': '18 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 85,
      'ingredients': [...vegetables, ...carbs].map((i) => i.name).toList(),
      'instructions': [
        '1. Cook ${carb} according to package instructions',
        '2. Sauté ${vegetable} in oil until tender',
        '3. Season with salt, pepper, and herbs',
        '4. Combine ${vegetable} with ${carb}',
        '5. Serve warm and enjoy'
      ],
      'nutritionalValue': 'Nutritious vegetarian meal',
      'serves': '2-3 people',
      'source': 'Dynamic AI Generator',
      'cuisine': 'International',
    };
  }
  
  // Create protein + flatbread recipe
  static Map<String, dynamic> _createProteinFlatbreadRecipe(List<InventoryItem> proteins, List<InventoryItem> flatbreads) {
    final protein = proteins.first.name;
    final flatbread = flatbreads.first.name;
    
    return {
      'name': '${protein.capitalize()} ${flatbread.capitalize()} Roll',
      'description': 'Delicious protein roll using your flatbread',
      'time': '12 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 95,
      'ingredients': [...proteins, ...flatbreads].map((i) => i.name).toList(),
      'instructions': [
        '1. Season ${protein} with salt and pepper',
        '2. Cook ${protein} in a pan until done',
        '3. Warm ${flatbread} on a pan or microwave',
        '4. Slice ${protein} into strips',
        '5. Place ${protein} on ${flatbread}',
        '6. Roll up tightly and serve hot'
      ],
      'nutritionalValue': 'High protein roll',
      'serves': '1-2 people',
      'source': 'Dynamic AI Generator',
      'cuisine': 'International',
    };
  }
  
  // Create vegetable + flatbread recipe
  static Map<String, dynamic> _createVegetableFlatbreadRecipe(List<InventoryItem> vegetables, List<InventoryItem> flatbreads) {
    final vegetable = vegetables.first.name;
    final flatbread = flatbreads.first.name;
    
    return {
      'name': '${vegetable.capitalize()} ${flatbread.capitalize()} Wrap',
      'description': 'Fresh vegetable wrap using your flatbread',
      'time': '10 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 90,
      'ingredients': [...vegetables, ...flatbreads].map((i) => i.name).toList(),
      'instructions': [
        '1. Slice ${vegetable} into thin strips',
        '2. Warm ${flatbread} on a pan',
        '3. Sauté ${vegetable} with oil and spices',
        '4. Place ${vegetable} on ${flatbread}',
        '5. Roll up and serve fresh'
      ],
      'nutritionalValue': 'Fresh vegetable wrap',
      'serves': '1-2 people',
      'source': 'Dynamic AI Generator',
      'cuisine': 'International',
    };
  }
  
  // Generate chicken-specific recipes
  static List<Map<String, dynamic>> _generateChickenRecipes(List<InventoryItem> ingredients) {
    final recipes = <Map<String, dynamic>>[];
    final ingredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
    
    if (ingredientNames.any((name) => name.contains('chicken'))) {
      // Chicken + Rice
      if (ingredientNames.any((name) => name.contains('rice'))) {
        recipes.add({
          'name': 'Chicken Fried Rice',
          'description': 'Quick and delicious chicken fried rice using your ingredients',
          'time': '25 min',
          'difficulty': 'Medium',
          'type': 'main',
          'wasteReduction': 95,
          'ingredients': ingredients.map((i) => i.name).toList(),
          'instructions': [
            '1. Cook rice and let it cool',
            '2. Cut chicken into small pieces',
            '3. Heat oil in a large pan or wok',
            '4. Cook chicken until golden brown',
            '5. Add vegetables and cook for 2-3 minutes',
            '6. Add rice and stir-fry everything together',
            '7. Season with soy sauce, salt, and pepper',
            '8. Serve hot'
          ],
          'nutritionalValue': 'Complete meal with protein and carbs',
          'serves': '3-4 people',
          'source': 'Dynamic AI Generator',
          'cuisine': 'Asian',
        });
      }
      
      // Chicken + Bread
      if (ingredientNames.any((name) => name.contains('bread'))) {
        recipes.add({
          'name': 'Chicken Sandwich',
          'description': 'Simple and satisfying chicken sandwich',
          'time': '15 min',
          'difficulty': 'Easy',
          'type': 'main',
          'wasteReduction': 90,
          'ingredients': ingredients.map((i) => i.name).toList(),
          'instructions': [
            '1. Season chicken with salt and pepper',
            '2. Cook chicken in a pan until done',
            '3. Slice chicken into strips',
            '4. Toast bread slices',
            '5. Layer chicken between bread slices',
            '6. Add any available vegetables',
            '7. Serve immediately'
          ],
          'nutritionalValue': 'High protein sandwich',
          'serves': '1-2 people',
          'source': 'Dynamic AI Generator',
          'cuisine': 'International',
        });
      }
    }
    
    return recipes;
  }
  
  // Generate rice-specific recipes
  static List<Map<String, dynamic>> _generateRiceRecipes(List<InventoryItem> ingredients) {
    final recipes = <Map<String, dynamic>>[];
    final ingredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
    
    if (ingredientNames.any((name) => name.contains('rice'))) {
      recipes.add({
        'name': 'Vegetable Rice Pilaf',
        'description': 'Flavorful rice dish with your available vegetables',
        'time': '30 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 90,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Rinse rice until water runs clear',
          '2. Heat oil in a pot, add onions and cook until soft',
          '3. Add rice and stir for 2 minutes',
          '4. Add water (1:2 ratio) and bring to boil',
          '5. Add vegetables and seasonings',
          '6. Cover and simmer for 15-20 minutes',
          '7. Fluff rice and serve hot'
        ],
        'nutritionalValue': 'Nutritious rice with vegetables',
        'serves': '3-4 people',
        'source': 'Dynamic AI Generator',
        'cuisine': 'International',
      });
    }
    
    return recipes;
  }
  
  // Generate pasta-specific recipes
  static List<Map<String, dynamic>> _generatePastaRecipes(List<InventoryItem> ingredients) {
    final recipes = <Map<String, dynamic>>[];
    final ingredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
    
    if (ingredientNames.any((name) => name.contains('pasta'))) {
      recipes.add({
        'name': 'Simple Pasta with Vegetables',
        'description': 'Quick pasta dish using your available ingredients',
        'time': '20 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 85,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Boil pasta according to package instructions',
          '2. Heat oil in a pan, add vegetables',
          '3. Cook vegetables until tender',
          '4. Drain pasta and add to vegetables',
          '5. Season with salt, pepper, and herbs',
          '6. Toss everything together and serve'
        ],
        'nutritionalValue': 'Comforting pasta with vegetables',
        'serves': '2-3 people',
        'source': 'Dynamic AI Generator',
        'cuisine': 'Italian',
      });
    }
    
    return recipes;
  }
  
  // Generate flatbread-specific recipes
  static List<Map<String, dynamic>> _generateFlatbreadRecipes(List<InventoryItem> ingredients) {
    final recipes = <Map<String, dynamic>>[];
    final ingredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
    
    if (ingredientNames.any((name) => name.contains('chapati') || name.contains('roti'))) {
      // Chapati/Roti + Chicken
      if (ingredientNames.any((name) => name.contains('chicken'))) {
        recipes.add({
          'name': 'Chicken Chapati Roll',
          'description': 'Traditional Indian chicken roll with chapati',
          'time': '15 min',
          'difficulty': 'Easy',
          'type': 'main',
          'wasteReduction': 95,
          'ingredients': ingredients.map((i) => i.name).toList(),
          'instructions': [
            '1. Season chicken with salt, pepper, and spices',
            '2. Cook chicken in a pan until done',
            '3. Warm chapati on a pan',
            '4. Slice chicken into strips',
            '5. Add chicken to chapati',
            '6. Add any available vegetables',
            '7. Roll up and serve hot'
          ],
          'nutritionalValue': 'Traditional Indian protein roll',
          'serves': '1-2 people',
          'source': 'Dynamic AI Generator',
          'cuisine': 'Indian',
        });
      }
      
      // Chapati/Roti + Vegetables
      if (ingredientNames.any((name) => name.contains('onion') || name.contains('tomato'))) {
        recipes.add({
          'name': 'Vegetable Chapati Roll',
          'description': 'Fresh vegetable roll with chapati',
          'time': '12 min',
          'difficulty': 'Easy',
          'type': 'main',
          'wasteReduction': 90,
          'ingredients': ingredients.map((i) => i.name).toList(),
          'instructions': [
            '1. Slice vegetables into thin strips',
            '2. Sauté vegetables with oil and spices',
            '3. Warm chapati on a pan',
            '4. Add vegetables to chapati',
            '5. Roll up tightly and serve'
          ],
          'nutritionalValue': 'Fresh vegetable roll',
          'serves': '1-2 people',
          'source': 'Dynamic AI Generator',
          'cuisine': 'Indian',
        });
      }
    }
    
    if (ingredientNames.any((name) => name.contains('naan'))) {
      // Naan + Chicken
      if (ingredientNames.any((name) => name.contains('chicken'))) {
        recipes.add({
          'name': 'Chicken Naan Wrap',
          'description': 'Delicious chicken wrap with naan bread',
          'time': '18 min',
          'difficulty': 'Easy',
          'type': 'main',
          'wasteReduction': 95,
          'ingredients': ingredients.map((i) => i.name).toList(),
          'instructions': [
            '1. Season chicken with spices',
            '2. Cook chicken until done',
            '3. Warm naan bread',
            '4. Slice chicken into strips',
            '5. Add chicken to naan',
            '6. Add vegetables if available',
            '7. Fold naan and serve'
          ],
          'nutritionalValue': 'Protein-rich naan wrap',
          'serves': '1-2 people',
          'source': 'Dynamic AI Generator',
          'cuisine': 'Indian',
        });
      }
    }
    
    return recipes;
  }
  
  // Fallback recipes when API fails
  static List<Map<String, dynamic>> _getFallbackRecipes(List<InventoryItem> ingredients) {
    final recipes = <Map<String, dynamic>>[];
    
    // Create simple fallback recipes based on ingredients
    if (ingredients.any((i) => i.name.toLowerCase().contains('rice'))) {
      recipes.add({
        'name': 'Simple Rice Pilaf',
        'description': 'Flavorful rice dish with your available ingredients',
        'time': '25 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Wash rice and soak for 15 minutes',
          '2. Heat oil in a pan, add onions and cook until soft',
          '3. Add your vegetables and sauté for 2-3 minutes',
          '4. Add rice, salt, and water (1:2 ratio)',
          '5. Cover and cook until rice is done',
          '6. Garnish with fresh herbs and serve hot'
        ],
        'nutritionalValue': 'Complete meal with rice and vegetables',
        'serves': '3-4 people',
        'source': 'Fallback Generator',
        'cuisine': 'International',
      });
    }
    
    if (ingredients.any((i) => i.name.toLowerCase().contains('chicken'))) {
      recipes.add({
        'name': 'Simple Chicken Stir Fry',
        'description': 'Quick chicken dish with your ingredients',
        'time': '20 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 90,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Cut chicken into pieces and season with salt and pepper',
          '2. Heat oil in a pan, add chicken and cook until done',
          '3. Add your vegetables and cook for 5 minutes',
          '4. Season with salt, pepper, and herbs',
          '5. Serve hot with rice or bread'
        ],
        'nutritionalValue': 'High protein meal',
        'serves': '2-3 people',
        'source': 'Fallback Generator',
        'cuisine': 'International',
      });
    }
    
    // Generic recipe if no specific ingredients match
    if (recipes.isEmpty) {
      recipes.add({
        'name': 'Simple Vegetable Stir Fry',
        'description': 'Quick vegetable dish using your ingredients',
        'time': '15 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 85,
        'ingredients': ingredients.map((i) => i.name).toList(),
        'instructions': [
          '1. Heat oil in a pan',
          '2. Add your vegetables and cook for 5-7 minutes',
          '3. Season with salt, pepper, and herbs',
          '4. Serve hot'
        ],
        'nutritionalValue': 'Nutritious vegetable dish',
        'serves': '2-3 people',
        'source': 'Fallback Generator',
        'cuisine': 'International',
      });
    }
    
    return recipes;
  }
}
