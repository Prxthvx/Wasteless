import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/inventory_item.dart';

/// AI-powered recipe generation service using TensorFlow Lite
/// 
/// This service uses a locally-trained model to suggest complementary ingredients
/// and generate recipe recommendations based on available inventory.
class AIRecipeService {
  static Interpreter? _interpreter;
  static Map<String, int>? _vocab;
  static Map<int, String>? _reverseVocab;
  static bool _isInitialized = false;
  static Map<String, dynamic>? _metadata;
  
  /// Initialize the AI model and vocabulary
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🤖 Initializing AI Recipe Model...');
      
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/models/recipe_model.tflite');
      
      // Load vocabulary
      final vocabJson = await rootBundle.loadString('assets/models/vocab.json');
      _vocab = Map<String, int>.from(json.decode(vocabJson));
      
      // Create reverse vocabulary for looking up ingredient names
      _reverseVocab = {};
      _vocab!.forEach((key, value) {
        _reverseVocab![value] = key;
      });
      
      // Load metadata (optional)
      try {
        final metadataJson = await rootBundle.loadString('assets/models/model_metadata.json');
        _metadata = json.decode(metadataJson);
        print('📊 Model version: ${_metadata!['model_version']}');
        print('📊 Training date: ${_metadata!['training_date']}');
      } catch (e) {
        print('⚠️  Model metadata not found (optional)');
      }
      
      _isInitialized = true;
      print('✅ AI Recipe Model initialized');
      print('📚 Vocabulary size: ${_vocab!.length} ingredients');
    } catch (e) {
      print('❌ Error initializing AI model: $e');
      print('⚠️  Falling back to rule-based recipe generation');
      rethrow;
    }
  }
  
  /// Generate ingredient suggestions based on available items
  /// 
  /// Takes a list of [InventoryItem]s and returns suggested complementary
  /// ingredients that could be used to create recipes.
  static Future<List<String>> suggestIngredients(List<InventoryItem> items) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_interpreter == null || _vocab == null) {
      throw Exception('AI Model not initialized');
    }
    
    // Encode input ingredients
    final input = List<double>.filled(_vocab!.length, 0.0);
    
    for (final item in items) {
      final cleanName = _cleanIngredientName(item.name);
      if (_vocab!.containsKey(cleanName)) {
        input[_vocab![cleanName]!] = 1.0;
      }
    }
    
    // Run inference
    final output = List<double>.filled(_vocab!.length, 0.0);
    _interpreter!.run([input], [output]);
    
    // Get top suggestions (excluding already present ingredients)
    final suggestions = <String>[];
    final existingNames = items.map((i) => _cleanIngredientName(i.name)).toSet();
    
    // Sort by confidence score
    final indexed = output.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in indexed) {
      if (suggestions.length >= 10) break;
      
      // Confidence threshold
      if (entry.value > 0.3) {
        final ingredient = _reverseVocab![entry.key];
        if (ingredient != null && !existingNames.contains(ingredient)) {
          suggestions.add(ingredient);
        }
      }
    }
    
    return suggestions;
  }
  
  /// Generate recipe recommendations with AI-suggested ingredients
  static Future<List<Map<String, dynamic>>> generateRecipes(List<InventoryItem> items) async {
    final recipes = <Map<String, dynamic>>[];
    
    try {
      // Get AI suggestions
      final aiSuggestions = await suggestIngredients(items);
      
      if (aiSuggestions.isEmpty) {
        print('ℹ️  No AI suggestions available');
        return recipes;
      }
      
      // Group items by expiry urgency
      final expiringItems = items.where((item) => 
        item.expiryDate.difference(DateTime.now()).inDays <= 3
      ).toList();
      
      // Create AI-enhanced recipe with expiring items prioritized
      final primaryIngredients = expiringItems.isNotEmpty 
          ? expiringItems 
          : items.take(5).toList();
      
      recipes.add({
        'name': 'AI-Suggested Indian Recipe',
        'description': 'Smart recipe combining your ingredients with AI recommendations',
        'time': '30-40 min',
        'difficulty': 'Medium',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': [
          ...primaryIngredients.map((i) => i.name),
          ...aiSuggestions.take(3),
        ],
        'instructions': _generateInstructions(primaryIngredients, aiSuggestions),
        'nutritionalValue': 'Balanced Indian meal with fresh ingredients',
        'serves': '4-6 people',
        'source': 'AI Recipe Model',
        'cuisine': 'Indian',
        'aiConfidence': 'High',
      });
      
      // Create variations with different combinations
      if (aiSuggestions.length >= 5) {
        recipes.add({
          'name': 'Alternative AI Recipe',
          'description': 'Different combination using AI-suggested complements',
          'time': '25-35 min',
          'difficulty': 'Easy',
          'type': 'main',
          'wasteReduction': 90,
          'ingredients': [
            ...items.take(3).map((i) => i.name),
            ...aiSuggestions.skip(2).take(3),
          ],
          'instructions': _generateInstructions(items.take(3).toList(), aiSuggestions.skip(2).take(3).toList()),
          'nutritionalValue': 'Light and healthy Indian dish',
          'serves': '3-4 people',
          'source': 'AI Recipe Model',
          'cuisine': 'Indian',
          'aiConfidence': 'Medium',
        });
      }
      
    } catch (e) {
      print('❌ Error generating AI recipes: $e');
    }
    
    return recipes;
  }
  
  /// Clean ingredient name for matching with vocabulary
  static String _cleanIngredientName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'\d+'), '') // Remove numbers
        .replaceAll(RegExp(r'\b(kg|g|lb|oz|cup|tbsp|tsp|ml|l|gm|gram|grams)\b'), '') // Remove units
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
  }
  
  /// Generate cooking instructions based on ingredients
  static List<String> _generateInstructions(List<InventoryItem> primary, List<String> suggested) {
    return [
      'Wash and prepare all ingredients',
      'Heat oil/ghee in a pan',
      'Add cumin seeds and let them splutter',
      'Add ${primary.take(2).map((i) => i.name).join(', ')} and sauté',
      'Add the AI-suggested ingredients: ${suggested.take(3).join(', ')}',
      'Add spices (turmeric, red chilli, coriander powder) to taste',
      'Cook on medium heat until done',
      'Garnish with fresh coriander leaves',
      'Serve hot with rice or roti'
    ];
  }
  
  /// Check if model is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Get model metadata
  static Map<String, dynamic>? get metadata => _metadata;
  
  /// Get vocabulary size
  static int get vocabularySize => _vocab?.length ?? 0;
  
  /// Dispose resources
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _vocab = null;
    _reverseVocab = null;
    _metadata = null;
    _isInitialized = false;
    print('🗑️  AI Recipe Model disposed');
  }
}
