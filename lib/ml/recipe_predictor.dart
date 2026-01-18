// import 'recipe_model.dart';
// import 'recipe_vocab.dart';
// import 'recipe_labels.dart';

// class RecipePredictor {
//   /// Convert inventory ingredients → model input vector
//   static List<double> vectorize(List<String> ingredients) {
//     final ingredientSet =
//         ingredients.map((e) => e.toLowerCase()).toSet();

//     return recipeVocab
//         .map((vocabItem) =>
//             ingredientSet.contains(vocabItem) ? 1.0 : 0.0)
//         .toList();
//   }

//   /// Predict top N recipes
//   static List<String> predictTopRecipes(
//     List<String> ingredients, {
//     int topK = 5,
//   }) {
//     final input = vectorize(ingredients);
//     final scores = score(input);

//     final indexedScores = scores.asMap().entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return indexedScores
//         .take(topK)
//         .map((e) => recipeLabels[e.key])
//         .toList();
//   }
// }

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
