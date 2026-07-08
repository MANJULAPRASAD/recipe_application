import 'package:flutter/material.dart';
import '../models/recipe.dart';

class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  final ValueNotifier<List<Recipe>> favoritesNotifier =
      ValueNotifier<List<Recipe>>([]);

  List<Recipe> get favorites => favoritesNotifier.value;

  bool isFavorite(Recipe recipe) {
    return favorites.any((r) => r.title == recipe.title);
  }

  void toggleFavorite(Recipe recipe) {
    final current = List<Recipe>.from(favoritesNotifier.value);
    if (isFavorite(recipe)) {
      current.removeWhere((r) => r.title == recipe.title);
    } else {
      current.add(recipe);
    }
    favoritesNotifier.value = current;
  }
}
