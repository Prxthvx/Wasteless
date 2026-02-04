import 'recipe_model.dart';
import 'recipe_labels.dart';
import 'recipe_vectorizer.dart';

class RecipePredictor {
  static List<String> predictTopRecipes(
    List<String> ingredients, {
    int topK = 3,
  }) {
    final inputVector = RecipeVectorizer.vectorize(ingredients);

    final scores = score(inputVector);

    final indexedScores = scores.asMap().entries.toList();

    indexedScores.sort((a, b) => b.value.compareTo(a.value));

    return indexedScores
        .take(topK)
        .map((e) => recipeLabels[e.key])
        .toList();
  }
}
