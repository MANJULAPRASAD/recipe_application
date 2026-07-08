import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  final String _baseUrl = 'api.spoonacular.com';
  // Note: Free Spoonacular API keys have a very strict daily limit of 150 points.
  final String _apiKey = 'e6f987d605c3453ea1efee960d1b64ff';

  Future<List<Recipe>> fetchRandomRecipes({
    int number = 15,
    String? tags,
  }) async {
    final Map<String, String> queryParameters = {
      'number': number.toString(),
      'apiKey': _apiKey,
    };

    if (tags != null && tags.isNotEmpty && tags != 'All') {
      String formattedTag = tags.toLowerCase();
      if (formattedTag == 'fast food') {
        formattedTag = 'snack,fast food';
      }
      queryParameters['tags'] = formattedTag;
    }

    final Uri uri = Uri.https(_baseUrl, '/recipes/random', queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> recipesJson = data['recipes'];

        return recipesJson.map((json) => Recipe.fromJson(json)).toList();
      } else {
        debugPrint(
          'Spoonacular API returned status code: ${response.statusCode}',
        );
        debugPrint(
          'Triggering local fallback mock data for seamless user experience.',
        );
        return _getMockRecipes(tags);
      }
    } catch (e) {
      debugPrint('Error fetching recipes from remote host: $e');
      return _getMockRecipes(tags);
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    if (query.isEmpty) {
      return fetchRandomRecipes();
    }

    final Map<String, String> queryParameters = {
      'query': query,
      'number': '10',
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'apiKey': _apiKey,
    };

    final Uri uri = Uri.https(
      _baseUrl,
      '/recipes/complexSearch',
      queryParameters,
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> resultsJson = data['results'] ?? [];

        return resultsJson.map((json) => Recipe.fromJson(json)).toList();
      } else {
        debugPrint(
          'Search API error: ${response.statusCode}. Searching in local database.',
        );
        return _searchLocalMockRecipes(query);
      }
    } catch (e) {
      debugPrint('Network search error: $e. Returning local search results.');
      return _searchLocalMockRecipes(query);
    }
  }

  List<Recipe> _searchLocalMockRecipes(String query) {
    final cleanQuery = query.toLowerCase().trim();
    final allRecipes = _getMockRecipes('all');

    return allRecipes.where((recipe) {
      final titleMatch = recipe.title.toLowerCase().contains(cleanQuery);
      final ingredientMatch = recipe.ingredients.any(
        (ingredient) => ingredient.toLowerCase().contains(cleanQuery),
      );
      return titleMatch || ingredientMatch;
    }).toList();
  }

  List<Recipe> _getMockRecipes(String? tag) {
    final String category = (tag ?? 'all').toLowerCase();

    // 💡 [UPDATED] Mock data with realistic calorie values (calories: ...)
    final List<Recipe> allMockRecipes = [
      Recipe(
        title: 'Classic Gourmet Cheeseburger',
        imageUrl:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
        readyInMinutes: 20,
        servings: 2,
        likes: 1240,
        calories: 680, // 💡 680 kcal
        ingredients: [
          '80/20 Ground beef patty',
          'Soft Brioche burger buns',
          'Aged Cheddar cheese slices',
          'Fresh lettuce and tomato slices',
          'Gourmet burger sauce (mayo, ketchup, sweet relish)',
        ],
        instructions:
            '1. Toast the brioche buns on a hot dry pan.\n2. Shape seasoned beef into a patty and sear in a hot skillet for 3-4 minutes per side.\n3. Place cheddar cheese on the patty during the last minute of cooking to melt.\n4. Assemble the burger starting with sauce, crisp lettuce, the patty with cheese, tomato, and top bun.',
      ),
      Recipe(
        title: 'Loaded Italian Pepperoni Pizza',
        imageUrl:
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=600&q=80',
        readyInMinutes: 30,
        servings: 4,
        likes: 1850,
        calories: 890, // 💡 890 kcal
        ingredients: [
          'Pre-rolled artisan pizza dough',
          'Herbed tomato pizza sauce',
          'Fresh shredded Mozzarella cheese',
          'Premium pepperoni slices',
          'Dried Italian herbs & garlic powder',
        ],
        instructions:
            '1. Preheat your oven to 450°F (230°C).\n2. Roll out the pizza dough on a floured surface or pizza stone.\n3. Spread a thin layer of tomato sauce, leaving a border around the edges.\n4. Generously sprinkle mozzarella cheese and place pepperoni slices on top.\n5. Bake for 12-15 minutes until the crust is golden brown and cheese is bubbly.',
      ),
      Recipe(
        title: 'Healthy Mediterranean Salad',
        imageUrl:
            'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
        readyInMinutes: 15,
        servings: 2,
        likes: 950,
        calories: 240, // 💡 240 kcal
        ingredients: [
          'Fresh organic avocados (cubed)',
          'Sweet cherry tomatoes (halved)',
          'Crispy garden cucumbers (sliced)',
          'Greek Feta cheese crumbled',
          'Extra virgin olive oil & lemon juice dressing',
        ],
        instructions:
            '1. In a large salad bowl, combine the halved cherry tomatoes, sliced cucumbers, and cubed avocado.\n2. Drizzle with extra virgin olive oil and fresh lemon juice.\n3. Season with salt, pepper, and gently toss to combine.\n4. Top with crumbled feta cheese before serving cold.',
      ),
      Recipe(
        title: 'Fluffy Golden Buttermilk Pancakes',
        imageUrl:
            'https://images.unsplash.com/photo-1528207776546-365bb710ee93?auto=format&fit=crop&w=600&q=80',
        readyInMinutes: 25,
        servings: 3,
        likes: 2100,
        calories: 420, // 💡 420 kcal
        ingredients: [
          'Premium all-purpose flour',
          'Fresh organic buttermilk',
          'Baking powder & baking soda',
          'Unsalted melted butter',
          'Pure organic maple syrup for serving',
        ],
        instructions:
            '1. Whisk together flour, sugar, baking powder, baking soda, and salt in a bowl.\n2. In another bowl, mix buttermilk, melted butter, and egg.\n3. Pour wet ingredients into dry and gently fold (do not overmix).\n4. Heat a greased griddle over medium heat. Pour butter and cook until bubbles form, then flip and cook until golden.',
      ),
      Recipe(
        title: 'Molten Belgian Chocolate Lava Cake',
        imageUrl:
            'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=600&q=80',
        readyInMinutes: 20,
        servings: 2,
        likes: 1420,
        calories: 510, // 💡 510 kcal
        ingredients: [
          'High-quality dark Belgian chocolate',
          'Fresh unsalted cream butter',
          'Whole organic eggs & egg yolks',
          'Fine granulated sugar',
          'All-purpose flour',
        ],
        instructions:
            '1. Preheat oven to 425°F (218°C). Grease two ramekins with butter and cocoa powder.\n2. Melt dark chocolate and butter together until smooth.\n3. Whisk eggs, egg yolks, sugar, and salt together until thick and pale.\n4. Fold in the chocolate mixture and flour gently.\n5. Divide into ramekins and bake for 12-14 minutes until the edges are firm but center is soft.',
      ),
      Recipe(
        title: 'Spicy Thai Red Curry',
        imageUrl:
            'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?auto=format&fit=crop&w=600&q=80',
        readyInMinutes: 35,
        servings: 3,
        likes: 1670,
        calories: 495, // 💡 495 kcal
        ingredients: [
          'Thai Red Curry paste',
          'Coconut milk',
          'Chicken breast or Tofu cubed',
          'Bamboo shoots & bell peppers',
          'Fresh Thai basil leaves',
        ],
        instructions:
            '1. Heat curry paste in a pan with a splash of coconut milk until fragrant.\n2. Add the remaining coconut milk and bring to a simmer.\n3. Stir in chicken/tofu and vegetables, cooking until tender.\n4. Garnish with fresh Thai basil and serve hot with jasmine rice.',
      ),
    ];

    if (category == 'fast food' || category == 'fast_food') {
      return allMockRecipes
          .where(
            (r) =>
                r.title.toLowerCase().contains('burger') ||
                r.title.toLowerCase().contains('pizza'),
          )
          .toList();
    } else if (category == 'healthy') {
      return allMockRecipes
          .where((r) => r.title.toLowerCase().contains('salad'))
          .toList();
    } else if (category == 'breakfast') {
      return allMockRecipes
          .where((r) => r.title.toLowerCase().contains('pancake'))
          .toList();
    } else if (category == 'dessert' || category == 'desserts') {
      return allMockRecipes
          .where((r) => r.title.toLowerCase().contains('cake'))
          .toList();
    }

    return allMockRecipes;
  }
}
