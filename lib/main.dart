import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/favorites_manager.dart';
import 'models/recipe.dart';
import 'widgets/recipe_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Attempting to initialize Firebase for auth and profile database services
    await Firebase.initializeApp();
    runApp(const RecipeApp());
  } catch (e) {
    // Gracefully handle connection errors without crashing the app
    runApp(FirebaseErrorApp(error: e.toString()));
  }
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;
  const FirebaseErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Firebase Connection Error!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'An error occurred while starting the app. Please check your google-services.json configuration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        error,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe Book',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFFF9FBFC),
        fontFamily: 'Poppins',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  bool _isSignUp = false;
  bool _isLoading = false;

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isSignUp && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _authService.signUp(email, password, name);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome! Let\'s cook something delicious.'),
          ),
        );
      } else {
        await _authService.signIn(email, password);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Welcome back!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isSignUp ? 'Create an Account' : 'Welcome Back!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Sign up today to explore thousands of delicious recipes'
                    : 'Log in to discover exclusive delicious recipes',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              if (_isSignUp) ...[
                _buildInputField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
              ],
              _buildInputField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                isObscure: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isSignUp ? 'Sign Up' : 'Log In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account? '
                        : "Don't have an account yet? ",
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? 'Log In' : 'Sign Up',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFFF9FBFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            hintText: 'Enter here',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const IngredientsSearchScreen(), // 💡 Search by Ingredients Tab
    const SavedRecipesScreen(), // 💡 Saved Recipes Tab
    const ProfileScreen(), // 💡 Premium Profile Tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: false,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_outlined),
            activeIcon: Icon(Icons.kitchen),
            label: 'Ingredients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final _searchController = TextEditingController();
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _userName = 'Food Lover';

  final List<String> _categories = [
    'All',
    'Fast Food',
    'Healthy',
    'Breakfast',
    'Dessert',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchRecipes();
  }

  void _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (profile != null && profile['name'] != null) {
        setState(() {
          _userName = profile['name'];
        });
      }
    }
  }

  void _fetchRecipes() async {
    setState(() => _isLoading = true);
    _searchController.clear();
    try {
      List<Recipe> data = await _apiService.fetchRandomRecipes(
        tags: _selectedCategory,
      );
      setState(() {
        _recipes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      List<Recipe> data = await _apiService.searchRecipes(query);
      setState(() {
        _recipes = data;
        _selectedCategory = 'All';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Greeting Header Block
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello $_userName! 👋',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Find Delicious Recipes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.deepOrange),
                      onPressed: () => _authService.signOut(),
                    ),
                  ),
                ],
              ),
            ),

            // Search input field with premium shadow decoration
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search for recipes here...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.deepOrange,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Categorized Horizontal Chips List
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 24),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _fetchRecipes();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.deepOrange : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey[200]!,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 8.0),
              child: Text(
                'Popular Recipes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),

            // Main recipe items scroll view
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepOrange,
                      ),
                    )
                  : _recipes.isEmpty
                  ? const Center(child: Text('No recipes found.'))
                  : ListView.builder(
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _recipes[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                          child: RecipeCard(recipe: recipe),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class IngredientsSearchScreen extends StatefulWidget {
  const IngredientsSearchScreen({Key? key}) : super(key: key);

  @override
  State<IngredientsSearchScreen> createState() =>
      _IngredientsSearchScreenState();
}

class _IngredientsSearchScreenState extends State<IngredientsSearchScreen> {
  final ApiService _apiService = ApiService();
  final Set<String> _selectedIngredients = {};
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = false;

  // Modern ingredient categorized collections to display
  final Map<String, List<Map<String, String>>> _ingredientCategories = {
    'Vegetables': [
      {'name': 'lettuce', 'emoji': '🥬'},
      {'name': 'tomato', 'emoji': '🍅'},
      {'name': 'onion', 'emoji': '🧅'},
      {'name': 'potato', 'emoji': '🥔'},
      {'name': 'cucumber', 'emoji': '🥒'},
      {'name': 'avocado', 'emoji': '🥑'},
    ],
    'Other': [
      {'name': 'cheese', 'emoji': '🧀'},
      {'name': 'beef', 'emoji': '🥩'},
      {'name': 'chicken', 'emoji': '🍗'},
      {'name': 'pepperoni', 'emoji': '🍕'},
      {'name': 'dough', 'emoji': '🍞'},
      {'name': 'chocolate', 'emoji': '🍫'},
    ],
  };

  void _toggleIngredient(String ingredientName) {
    setState(() {
      if (_selectedIngredients.contains(ingredientName)) {
        _selectedIngredients.remove(ingredientName);
      } else {
        _selectedIngredients.add(ingredientName);
      }
    });
    _filterRecipes();
  }

  void _filterRecipes() async {
    if (_selectedIngredients.isEmpty) {
      setState(() {
        _filteredRecipes = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Pull representative recipe selection to scan ingredients
      List<Recipe> rawData = await _apiService.fetchRandomRecipes(number: 25);

      // Match recipes containing selected local ingredients
      final matched = rawData.where((recipe) {
        return recipe.ingredients.any((ing) {
          final cleanIng = ing.toLowerCase();
          return _selectedIngredients.any(
            (sel) => cleanIng.contains(sel.toLowerCase()),
          );
        });
      }).toList();

      setState(() {
        _filteredRecipes = matched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search by Ingredients',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Text(
              'Select ingredients you currently have at home:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),

          // Categories and interactive grids list
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                ..._ingredientCategories.entries.map((category) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                        ), // 💡 Fixed symmetric layout syntax
                        child: Text(
                          category.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.2,
                            ),
                        itemCount: category.value.length,
                        itemBuilder: (context, idx) {
                          final item = category.value[idx];
                          final name = item['name']!;
                          final isSelected = _selectedIngredients.contains(
                            name,
                          );

                          return GestureDetector(
                            onTap: () => _toggleIngredient(name),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.deepOrange.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.deepOrange
                                      : Colors.grey[200]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['emoji']!,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.deepOrange
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          // Horizontal divider line
          const Divider(height: 1),

          // Filter result items display area
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF9FBFC),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepOrange,
                      ),
                    )
                  : _filteredRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedIngredients.isEmpty
                                ? 'Select ingredients to filter'
                                : 'No recipes found for selection',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _filteredRecipes[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                          child: RecipeCard(recipe: recipe),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedRecipesScreen extends StatelessWidget {
  const SavedRecipesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoritesManager = FavoritesManager();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Recipes',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<Recipe>>(
        valueListenable: favoritesManager.favoritesNotifier,
        builder: (context, favorites, _) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved recipes yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any recipe card to save it.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final recipe = favorites[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(recipe: recipe),
                    ),
                  );
                },
                child: RecipeCard(recipe: recipe),
              );
            },
          );
        },
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoritesManager = FavoritesManager();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.deepOrange,
            actions: [
              ValueListenableBuilder<List<Recipe>>(
                valueListenable: favoritesManager.favoritesNotifier,
                builder: (context, favorites, _) {
                  final isFav = favoritesManager.isFavorite(recipe);
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white,
                      ),
                      onPressed: () {
                        favoritesManager.toggleFavorite(recipe);
                      },
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'recipe-image-${recipe.title}',
                child: Image.network(recipe.imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // 💡 Fixed alignment layout typo
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildBadge(
                          Icons.access_time,
                          '${recipe.readyInMinutes} mins',
                          Colors.blue[50]!,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildBadge(
                          Icons.local_fire_department,
                          '${recipe.calories} kcal',
                          Colors.deepOrange[50]!,
                          Colors.deepOrange,
                        ),
                        const SizedBox(width: 12),
                        _buildBadge(
                          Icons.thumb_up,
                          '${recipe.likes} Likes',
                          Colors.orange[50]!,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.deepOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ing,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Text(
                        recipe.instructions,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    IconData icon,
    String text,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FavoritesManager _favoritesManager = FavoritesManager();

  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _notificationsEnabled = true;
  bool _offlineCacheEnabled = false;

  final _nameController = TextEditingController();
  String _selectedDiet = 'All-Rounder';
  String _avatarIndex = '0';

  // Custom avatars list with beautiful background colors
  final List<Map<String, dynamic>> _avatars = [
    {'emoji': '🍳', 'color': Colors.amber[100]!, 'label': 'Master Chef'},
    {'emoji': '🍕', 'color': Colors.orange[100]!, 'label': 'Pizza Lover'},
    {'emoji': '🥗', 'color': Colors.green[100]!, 'label': 'Green Foodie'},
    {'emoji': '🍩', 'color': Colors.pink[100]!, 'label': 'Sweet Tooth'},
    {'emoji': '🌶️', 'color': Colors.red[100]!, 'label': 'Spice Master'},
    {'emoji': '🍔', 'color': Colors.purple[100]!, 'label': 'Burger King'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final data = await _authService.getUserProfile(user.uid);
      setState(() {
        _userProfile = data;
        if (data != null) {
          if (data['name'] != null) _nameController.text = data['name'];
          if (data['dietPreference'] != null)
            _selectedDiet = data['dietPreference'];
          if (data['avatarIndex'] != null) _avatarIndex = data['avatarIndex'];
        }
        _isLoading = false;
      });
    }
  }

  void _updateDietPreference(String dietValue) async {
    final user = _authService.currentUser;
    if (user != null && !_isSaving) {
      setState(() {
        _selectedDiet = dietValue;
        _isSaving = true;
      });
      try {
        await _authService.updateUserProfile(
          user.uid,
          newName: _nameController.text,
          dietPreference: dietValue,
          avatarIndex: _avatarIndex,
        );
        _loadProfile();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update dietary preference: $e')),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Food Identity 🧑‍🍳',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a cute avatar to display on your profile.',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final av = _avatars[index];
                  final isCurrent = index.toString() == _avatarIndex;
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final user = _authService.currentUser;
                      if (user != null) {
                        setState(() {
                          _avatarIndex = index.toString();
                          _isSaving = true;
                        });
                        try {
                          await _authService.updateUserProfile(
                            user.uid,
                            newName: _nameController.text,
                            dietPreference: _selectedDiet,
                            avatarIndex: index.toString(),
                          );
                          _loadProfile();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating avatar: $e'),
                            ),
                          );
                        } finally {
                          setState(() => _isSaving = false);
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: av['color'],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrent
                              ? Colors.deepOrange
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            av['emoji'],
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            av['label'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? Colors.deepOrange[800]
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit Profile Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Colors.deepOrange,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final newName = _nameController.text.trim();
                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name cannot be empty!'),
                          ),
                        );
                        return;
                      }
                      setState(() => _isSaving = true);
                      try {
                        final user = _authService.currentUser;
                        if (user != null) {
                          await _authService.updateUserProfile(
                            user.uid,
                            newName: newName,
                            dietPreference: _selectedDiet,
                            avatarIndex: _avatarIndex,
                          );
                          _loadProfile();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } finally {
                        setState(() => _isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final parsedIndex = int.tryParse(_avatarIndex) ?? 0;
    final activeAvatar =
        _avatars[parsedIndex < _avatars.length ? parsedIndex : 0];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Premium Header with culinary background gradient
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF8A65), Colors.deepOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(40),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        child: const Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      // Avatar Card with hovering edit action
                      Positioned(
                        bottom: -50,
                        child: GestureDetector(
                          onTap: _showAvatarPicker,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: activeAvatar['color'],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    activeAvatar['emoji'],
                                    style: const TextStyle(fontSize: 50),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.deepOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 64),

                  // Display Name & Email Address text
                  Text(
                    _userProfile?['name'] ?? 'Food Lover',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email address linked',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),

                  // Edit Display Name Button trigger
                  OutlinedButton.icon(
                    onPressed: _showEditNameDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Display Name'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: const BorderSide(
                        color: Colors.deepOrange,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Premium Stats Cards Row Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ValueListenableBuilder<List<Recipe>>(
                      valueListenable: _favoritesManager.favoritesNotifier,
                      builder: (context, favorites, _) {
                        final savedCount = favorites.length;

                        // Chef level badge mapping
                        String level = 'Food Lover';
                        if (savedCount >= 5) {
                          level = 'Gourmet Chef';
                        } else if (savedCount >= 2) {
                          level = 'Home Cook';
                        }

                        final points = (savedCount * 120) + 150;

                        return Row(
                          children: [
                            _buildStatCard(
                              'Saved',
                              '$savedCount Recipes',
                              Icons.bookmark_added,
                              Colors.deepOrange,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'Chef Level',
                              level,
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'XP Points',
                              '$points pts',
                              Icons.stars,
                              Colors.blue,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Dietary Choice preference chips collection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: Colors.deepOrange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Dietary Preferences',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                  'All-Rounder',
                                  'Vegetarian',
                                  'Vegan',
                                  'Low Carb',
                                ].map((diet) {
                                  final isSelected = diet == _selectedDiet;
                                  return ChoiceChip(
                                    label: Text(diet),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        _updateDietPreference(diet);
                                      }
                                    },
                                    selectedColor: Colors.deepOrange,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    backgroundColor: Colors.grey[100],
                                    elevation: 0,
                                    pressElevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Account Mock Settings switches block
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            activeColor: Colors.deepOrange,
                            value: _notificationsEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                            title: const Text(
                              'Push Notifications',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            subtitle: Text(
                              'Get daily updates about delicious new meals.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            secondary: const Icon(
                              Icons.notifications_active_outlined,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          SwitchListTile(
                            activeColor: Colors.deepOrange,
                            value: _offlineCacheEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                _offlineCacheEnabled = value;
                              });
                            },
                            title: const Text(
                              'Offline Recipe Cache',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            subtitle: Text(
                              'Access your bookmarked recipes when offline.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            secondary: const Icon(
                              Icons.cloud_download_outlined,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Standard Sign Out Button action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _authService.signOut(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Log Out Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: col, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
