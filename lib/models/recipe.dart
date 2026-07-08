class Recipe {
  final String title;
  final String imageUrl;
  final int readyInMinutes;
  final int servings;
  final int likes;
  final int calories; // 💡 [NEW] Added calorie count field
  final List<String> ingredients;
  final String instructions;

  Recipe({
    required this.title,
    required this.imageUrl,
    required this.readyInMinutes,
    required this.servings,
    required this.likes,
    required this.calories, // 💡 [NEW] Constructor update
    required this.ingredients,
    required this.instructions,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Parse ingredients safely from 'extendedIngredients' list
    var ingredientsList = json['extendedIngredients'] as List? ?? [];
    List<String> parsedIngredients = ingredientsList
        .map(
          (item) =>
              item['original'] as String? ?? item['name'] as String? ?? '',
        )
        .where((element) => element.isNotEmpty)
        .toList();

    // 💡 [NEW] Safely parse calories from API response if available
    int parsedCalories = 350; // Default fallback
    if (json['calories'] != null) {
      parsedCalories = (json['calories'] as num).toInt();
    } else if (json['nutrition'] != null &&
        json['nutrition']['nutrients'] != null) {
      final nutrients = json['nutrition']['nutrients'] as List;
      final caloriesNutrient = nutrients.firstWhere(
        (n) => n['name'] == 'Calories' || n['name'] == 'calories',
        orElse: () => null,
      );
      if (caloriesNutrient != null) {
        parsedCalories = (caloriesNutrient['amount'] as num).toInt();
      }
    }

    return Recipe(
      title: json['title'] ?? 'No Title',
      imageUrl: json['image'] ?? 'https://via.placeholder.com/150',
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 0,
      likes: json['aggregateLikes'] ?? 0,
      calories: parsedCalories, // 💡 Assigning parsed calories
      ingredients: parsedIngredients,
      instructions: json['instructions'] ?? 'No instructions provided.',
    );
  }
}
