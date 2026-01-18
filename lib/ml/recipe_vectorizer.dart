import 'recipe_vocab.dart';

class RecipeVectorizer {
  /// Converts a list of ingredient names into a binary feature vector
  /// matching the order of recipeVocab
  static List<double> vectorize(List<String> ingredients) {
    final ingredientSet =
        ingredients.map((e) => e.toLowerCase()).toSet();

    return recipeVocab.map((token) {
      return ingredientSet.contains(token) ? 1.0 : 0.0;
    }).toList();
  }
}
