import 'dart:convert';
import 'package:a1/API/gemini.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_detail_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final String apiKey = '1c266f8a0eb84f7d8888e73fc2141053';
  List<Map<String, dynamic>> recipes = [];
  int recipeCount = 8;
  bool isLoadingMore = false;
  Set<int> likedRecipes = {}; // Store liked recipe IDs

  // Controller for the search bar (for Gemini)
  final TextEditingController _searchController = TextEditingController();

  // Function to call Gemini API using the external function and display the result
  void _searchGeminiRecipe() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Optionally show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String recipeDetail = await fetchRecipeFromGemini(query);

    // Close the loading dialog
    Navigator.of(context).pop();

    // Show the detailed recipe in a dialog or navigate to another screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detailed Recipe for $query"),
        content: SingleChildScrollView(
          child: Text(recipeDetail),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    
    final url = Uri.parse(
        'https://api.spoonacular.com/recipes/random?apiKey=$apiKey&number=$recipeCount');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List recipeList = data['recipes'];

        setState(() {
          recipes.addAll(recipeList.map<Map<String, dynamic>>((recipe) {
            return {
              'id': recipe['id'],
              'title': recipe['title'] ?? 'No Title',
              'image': recipe['image'] ?? 'https://via.placeholder.com/150',
            };
          }).toList());
          isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void loadMoreRecipes() {
    setState(() {
      isLoadingMore = true;
      recipeCount += 8;
    });
    fetchRecipes();
  }

  void toggleLike(int recipeId) {
    setState(() {
      if (likedRecipes.contains(recipeId)) {
        likedRecipes.remove(recipeId);
      } else {
        likedRecipes.add(recipeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Recipes"),
        backgroundColor: Colors.green,
      ),
      body: recipes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for recipes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          suffixIcon: Icon(Icons.search),
                        ),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          _searchGeminiRecipe();
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75, // Adjusted to prevent overflow
                      ),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        bool isLiked = likedRecipes.contains(recipe['id']);
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailScreen(recipeId: recipe['id']),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    recipe['image'],
                                    height:
                                        120, // Fixed height to avoid overflow
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    recipe['title'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow
                                        .ellipsis, // Prevents overflow
                                  ),
                                ),
                                Spacer(), // Pushes like button to bottom
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      color: isLiked ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () => toggleLike(recipe['id']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (!isLoadingMore)
                    ElevatedButton(
                      onPressed: loadMoreRecipes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'See More',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  if (isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
    );
  }
}
