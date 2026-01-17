import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../models/inventory_item.dart';
import '../../../models/donation.dart';
import '../../../services/supabase_service.dart';
import '../../../services/recipe_api_service.dart';
import '../../scanner_screen.dart';
import '../../../services/barcode_lookup_service.dart';
import 'view_model/restaurant_dashboard_view_model.dart';
import 'tabs/overview/restaurant_overview_tab.dart';
import 'tabs/inventory/restaurant_inventory_tab.dart';
import 'tabs/donations/restaurant_donations_tab.dart';
import 'tabs/recipes/restaurant_recipes_tab.dart';
import 'tabs/recipes/dialogs/recipe_generation_dialog.dart';
import 'tabs/recipes/dialogs/advanced_recipe_dialog.dart';
import 'tabs/recipes/dialogs/recipe_detail_dialog.dart';
import 'tabs/analytics/restaurant_analytics.dart';

class RestaurantDashboard extends StatefulWidget {
  final UserProfile profile;
  
  const RestaurantDashboard({super.key, required this.profile});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  late final RestaurantDashboardViewModel _viewModel ;
  

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 5, vsync: this);

      _viewModel = RestaurantDashboardViewModel();
      _viewModel.addListener(_onViewModelChanged);

      _loadData();
    }

    void _onViewModelChanged() {
      if (mounted) {
        setState(() {});
      }
    }
    @override
    void dispose() {
      _viewModel.removeListener(_onViewModelChanged);
      _tabController.dispose();
      
      super.dispose();
    }

    Future<void> _loadData() async {
      try {
        await _viewModel.loadData(
          restaurantId: widget.profile.id,
          isDemo: widget.profile.id == 'demo-user-id',
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.profile.name} Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.favorite), text: 'Donations'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Recipes'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RestaurantOverviewTab(
              viewModel: _viewModel,
              restaurantName: widget.profile.name,
              onNavigate: (index) => _tabController.animateTo(index),
            ),
          RestaurantInventoryTab(
            viewModel: _viewModel,
            onRefresh: _loadData,
            onItemAction: _handleInventoryAction,
          ),
          RestaurantDonationsTab(
            viewModel: _viewModel,
            onRefresh: _loadData,
            onDonationAction: _handleDonationAction,
          ),
          RestaurantRecipesTab(
              viewModel: _viewModel,
             onGenerateRecipe: _showRecipeGenerationDialog,
             onGenerateAdvancedRecipe: _showAdvancedRecipeDialog,
          ),
          RestaurantAnalyticsTab(viewModel: _viewModel),
        ],
      ),
      drawer: _buildDrawer(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

 

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showAddItemDialog(),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddInventoryDialog(
        profile: widget.profile,
        onItemAdded: (newItem) async {
          try {
            print('Adding item: ${newItem.name}'); // Debug log
            print('Profile ID: ${widget.profile.id}'); // Debug log
            
            if (widget.profile.id != 'demo-user-id') {
              print('Using real database'); // Debug log
              print('Profile ID type: ${widget.profile.id.runtimeType}'); // Debug log
              print('Profile ID value: "${widget.profile.id}"'); // Debug log
              
              // Check if the profile ID looks like a valid UUID
              if (widget.profile.id.length != 36 || !widget.profile.id.contains('-')) {
                throw Exception('Invalid restaurant ID format. Expected UUID format.');
              }
              
              final savedItem = await _viewModel.addInventoryItem(
                restaurantId: widget.profile.id, // Use profile ID directly
                name: newItem.name,
                quantity: newItem.quantity,
                expiryDate: newItem.expiryDate,
                status: newItem.status,
                category: newItem.category, // Added category parameter
              );
              print('Item saved to database: ${savedItem.id}'); // Debug log
                 setState(() {
                   _viewModel.inventory.add(savedItem);
                 });
                 // Recalculate analytics after adding item
                 _viewModel.calculateAnalytics();
               } else {
                 print('Using demo mode'); // Debug log
                 setState(() {
                   _viewModel.inventory.add(newItem);
                 });
                 // Recalculate analytics after adding item
                 _viewModel.calculateAnalytics();
               }
            print('Item added successfully to inventory list'); // Debug log
          } catch (e) {
            print('Error adding item: $e'); // Debug log
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving item: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleInventoryAction(String action, InventoryItem item) {
    switch (action) {
      case 'edit':
        _showEditItemDialog(item);
        break;
      case 'donate':
        _showPostDonationDialog(item);
        break;
      case 'delete':
        _deleteInventoryItem(item);
        break;
    }
  }

  void _showEditItemDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => EditInventoryDialog(
        profile: widget.profile,
        item: item,
        onItemUpdated: (updatedItem) async {
          try {
            if (widget.profile.id != 'demo-user-id') {
                    final savedItem = await _viewModel.updateInventoryItem(
                      itemId: item.id,
                      name: updatedItem.name,
                      quantity: updatedItem.quantity,
                      category: updatedItem.category,
                      expiryDate: updatedItem.expiryDate,
                      status: updatedItem.status,
                    );

              setState(() {
                final index = _viewModel.inventory.indexWhere((i) => i.id == item.id);
                if (index != -1) {
                  _viewModel.inventory[index] = savedItem;
                }
              });
            } else {
              setState(() {
                final index = _viewModel.inventory.indexWhere((i) => i.id == item.id);
                if (index != -1) {
                  _viewModel.inventory[index] = updatedItem;
                }
              });
            }
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating item: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showPostDonationDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => PostDonationDialog(
        profile: widget.profile,
        item: item,
        onDonationPosted: (donation) async {
          try {
            if (widget.profile.id != 'demo-user-id') {
              final savedDonation = await _viewModel.addDonation(
                restaurantId: widget.profile.id,
                title: donation.title,
                description: donation.description,
                quantity: donation.quantity,
                expiryDate: donation.expiryDate,
              );
              if (savedDonation != null) {
                setState(() {
                  _viewModel.donations.add(savedDonation);
                });
                // Recalculate analytics after adding donation
                _viewModel.calculateAnalytics();
              }
            } else {
              setState(() {
                _viewModel.donations.add(donation);
              });
              // Recalculate analytics after adding donation
              _viewModel.calculateAnalytics();
            }
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Donation posted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error posting donation: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleDonationAction(String action, Donation donation) {
    switch (action) {
      case 'view':
        // TODO: Implement view details
        break;
    }
  }

  void _deleteInventoryItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                if (widget.profile.id != 'demo-user-id') {
                  await _viewModel.deleteInventoryItem(
                        itemId: item.id,
                        restaurantId: widget.profile.id,
                        isDemo: widget.profile.id == 'demo-user-id',
                        );
                }
                setState(() {
                  _viewModel.inventory.removeWhere((i) => i.id == item.id);
                });
                // Recalculate analytics after deleting item
                _viewModel.calculateAnalytics();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => const NotificationsDialog(),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(profile: widget.profile),
    );
  }

  void _showDrawer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Profile: ${widget.profile.name}'),
              subtitle: Text(widget.profile.role.toUpperCase()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.of(context).pop();
                _showNotifications();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                _showSettings();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () => _signOut(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.recycling,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.profile.role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _tabController.index == 0,
            onTap: () {
              _tabController.animateTo(0);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Inventory'),
            selected: _tabController.index == 1,
            onTap: () {
              _tabController.animateTo(1);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Donations'),
            selected: _tabController.index == 2,
            onTap: () {
              _tabController.animateTo(2);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Recipes'),
            selected: _tabController.index == 3,
            onTap: () {
              _tabController.animateTo(3);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            selected: _tabController.index == 4,
            onTap: () {
              _tabController.animateTo(4);
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.of(context).pop();
              _showNotifications();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              _showSettings();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _signOut();
            },
          ),
        ],
      ),
    );
  }

 

  void _showRecipeGenerationDialog(InventoryItem item) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RecipeGenerationDialog(
      item: item,
      generateRecipe: _generateAIRecipe,
      onShowAdvanced: _showAdvancedRecipeDialog,
    ),
  );
}

 void _showAdvancedRecipeDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AdvancedRecipeDialog(
      inventory: _viewModel.inventory,
      onRecipeSelected: _showDetailedAIRecipe,
    ),
  );
}


  // Real API-based Recipe Generation
  Future<List<Map<String, dynamic>>> _generateAIRecipe(InventoryItem primaryItem) async {
    final availableItems = _viewModel.inventory.where((item) => item.id != primaryItem.id).toList();
    final expiringItems = availableItems.where((item) => 
      item.expiryDate.difference(DateTime.now()).inDays <= 3
    ).toList();
    
    // Use real recipe API
    final allIngredients = [primaryItem, ...availableItems];
    final recipes = await RecipeApiService.getRecipesByIngredients(allIngredients);
    
    // Sort by waste reduction potential and expiry urgency
    recipes.sort((a, b) {
      final aUrgency = _calculateUrgencyFromNames(a['ingredients'] as List<String>);
      final bUrgency = _calculateUrgencyFromNames(b['ingredients'] as List<String>);
      return bUrgency.compareTo(aUrgency);
    });
    
    return recipes.take(5).toList(); // Return top 5 recipes
  }

  // Find ingredients that work well together
  List<InventoryItem> _findCompatibleIngredients(InventoryItem primary, List<InventoryItem> available) {
    final compatible = <InventoryItem>[];
    
    for (final item in available) {
      if (_areIngredientsCompatible(primary, item)) {
        compatible.add(item);
      }
    }
    
    return compatible;
  }

  // Check if two ingredients are compatible for cooking
  bool _areIngredientsCompatible(InventoryItem item1, InventoryItem item2) {
    final name1 = item1.name.toLowerCase();
    final name2 = item2.name.toLowerCase();
    final cat1 = item1.category.toLowerCase();
    final cat2 = item2.category.toLowerCase();
    
    // Bread + protein combinations
    if ((name1.contains('bread') || name1.contains('toast') || name1.contains('bun')) && 
        (name2.contains('egg') || name2.contains('cheese') || name2.contains('meat') || name2.contains('chicken'))) {
      return true;
    }
    if ((name2.contains('bread') || name2.contains('toast') || name2.contains('bun')) && 
        (name1.contains('egg') || name1.contains('cheese') || name1.contains('meat') || name1.contains('chicken'))) {
      return true;
    }
    
    // Dairy + other ingredients
    if ((cat1 == 'dairy' && cat2 != 'dairy') || (cat2 == 'dairy' && cat1 != 'dairy')) {
      return true;
    }
    
    // Vegetables + other vegetables
    if (cat1 == 'vegetables' && cat2 == 'vegetables') {
      return true;
    }
    
    // Fruits + dairy (smoothies, desserts)
    if ((cat1 == 'fruits' && cat2 == 'dairy') || (cat2 == 'fruits' && cat1 == 'dairy')) {
      return true;
    }
    
    // Fruits + other fruits
    if (cat1 == 'fruits' && cat2 == 'fruits') {
      return true;
    }
    
    // Any ingredient with herbs/spices
    if (name1.contains('herb') || name1.contains('spice') || name1.contains('garlic') || name1.contains('onion') ||
        name2.contains('herb') || name2.contains('spice') || name2.contains('garlic') || name2.contains('onion')) {
      return true;
    }
    
    return false;
  }

  // Generate real recipes based on actual ingredients
  List<Map<String, dynamic>> _generateRealRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Analyze primary ingredient and find real recipes
    final primaryName = primary.name.toLowerCase();
    final primaryCategory = primary.category.toLowerCase();
    
    // Bread-based recipes
    if (primaryName.contains('bread') || primaryName.contains('toast') || primaryName.contains('bun')) {
      recipes.addAll(_generateBreadBasedRecipes(primary, compatible, expiring));
    }
    
    // Egg-based recipes
    if (primaryName.contains('egg')) {
      recipes.addAll(_generateEggBasedRecipes(primary, compatible, expiring));
    }
    
    // Cheese-based recipes
    if (primaryName.contains('cheese')) {
      recipes.addAll(_generateCheeseBasedRecipes(primary, compatible, expiring));
    }
    
    // Vegetable-based recipes
    if (primaryCategory == 'vegetables') {
      recipes.addAll(_generateVegetableBasedRecipes(primary, compatible, expiring));
    }
    
    // Fruit-based recipes
    if (primaryCategory == 'fruits') {
      recipes.addAll(_generateFruitBasedRecipes(primary, compatible, expiring));
    }
    
    // Generic combinations
    if (recipes.isEmpty) {
      recipes.addAll(_generateGenericCombinations(primary, compatible, expiring));
    }
    
    return recipes;
  }

  void _showRecipeForItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recipe for ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Here are some recipe ideas for your ${item.name}:'),
            const SizedBox(height: 16),
            _buildRecipeSuggestion(item),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSuggestion(InventoryItem item) {
    final suggestions = _getRecipeSuggestions(item.category);
    
    return Column(
      children: suggestions.map((suggestion) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(suggestion['name']),
            subtitle: Text(suggestion['description']),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).pop();
              _showRecipeDetail(suggestion);
            },
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getRecipeSuggestions(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return [
          {
            'name': 'Fruit Smoothie',
            'description': 'Blend with yogurt and honey',
            'time': '5 min',
            'difficulty': 'Easy',
            'ingredients': ['Any fruits', 'Yogurt', 'Honey'],
            'instructions': '1. Blend all ingredients\n2. Serve chilled',
          },
          {
            'name': 'Fruit Salad',
            'description': 'Fresh fruit combination',
            'time': '10 min',
            'difficulty': 'Easy',
            'ingredients': ['Mixed fruits', 'Lemon juice', 'Mint'],
            'instructions': '1. Cut fruits into pieces\n2. Add lemon juice\n3. Garnish with mint',
          },
        ];
      case 'vegetables':
        return [
          {
            'name': 'Vegetable Stir-fry',
            'description': 'Quick and healthy stir-fry',
            'time': '15 min',
            'difficulty': 'Easy',
            'ingredients': ['Any vegetables', 'Garlic', 'Soy sauce', 'Oil'],
            'instructions': '1. Heat oil in pan\n2. Add garlic\n3. Add vegetables\n4. Season with soy sauce',
          },
          {
            'name': 'Roasted Vegetables',
            'description': 'Oven-roasted vegetable medley',
            'time': '30 min',
            'difficulty': 'Easy',
            'ingredients': ['Any vegetables', 'Olive oil', 'Salt', 'Herbs'],
            'instructions': '1. Preheat oven\n2. Toss vegetables with oil\n3. Roast for 25-30 min',
          },
        ];
      case 'dairy':
        return [
          {
            'name': 'Cheese Sauce',
            'description': 'Versatile cheese sauce',
            'time': '10 min',
            'difficulty': 'Easy',
            'ingredients': ['Cheese', 'Milk', 'Butter', 'Flour'],
            'instructions': '1. Melt butter\n2. Add flour\n3. Add milk gradually\n4. Add cheese',
          },
        ];
      default:
        return [
          {
            'name': 'Creative Leftover Dish',
            'description': 'Transform your ${category.toLowerCase()} into something new',
            'time': '20 min',
            'difficulty': 'Easy',
            'ingredients': ['Your item', 'Basic seasonings'],
            'instructions': '1. Assess the item\n2. Add seasonings\n3. Cook creatively',
          },
        ];
    }
  }

  void _showRecipeDetail(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipe['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                'Ingredients:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(recipe['ingredients'] as List).map((ingredient) => 
                Text('• $ingredient')).toList(),
              const SizedBox(height: 16),
              Text(
                'Instructions:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(recipe['instructions']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Real recipe generators based on actual ingredients
  List<Map<String, dynamic>> _generateBreadBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final eggs = compatible.where((item) => item.name.toLowerCase().contains('egg')).toList();
    final cheese = compatible.where((item) => item.name.toLowerCase().contains('cheese')).toList();
    final meat = compatible.where((item) => 
      item.name.toLowerCase().contains('chicken') || 
      item.name.toLowerCase().contains('meat') || 
      item.name.toLowerCase().contains('ham')
    ).toList();
    
    // Egg Sandwich
    if (eggs.isNotEmpty) {
      final ingredients = [primary, eggs.first];
      if (cheese.isNotEmpty) ingredients.add(cheese.first);
      
      recipes.add({
        'name': 'Classic Egg Sandwich',
        'description': 'Perfect breakfast sandwich with ${eggs.first.name} and ${primary.name}',
        'time': '10 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': ingredients,
        'instructions': '1. Toast the ${primary.name} until golden\n2. Scramble the ${eggs.first.name} with salt and pepper\n3. ${cheese.isNotEmpty ? 'Add ${cheese.first.name} to the egg while cooking' : ''}\n4. Assemble sandwich and serve hot',
        'nutritionalValue': 'High protein breakfast with carbs for energy',
        'serves': '1-2 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateEggBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final bread = compatible.where((item) => 
      item.name.toLowerCase().contains('bread') || 
      item.name.toLowerCase().contains('toast')
    ).toList();
    final cheese = compatible.where((item) => item.name.toLowerCase().contains('cheese')).toList();
    final vegetables = compatible.where((item) => item.category.toLowerCase() == 'vegetables').toList();
    
    // Scrambled Eggs
    final scrambledIngredients = [primary];
    if (cheese.isNotEmpty) scrambledIngredients.add(cheese.first);
    if (vegetables.isNotEmpty) scrambledIngredients.add(vegetables.first);
    
    recipes.add({
      'name': 'Scrambled Eggs',
      'description': 'Creamy scrambled ${primary.name}${cheese.isNotEmpty ? ' with ${cheese.first.name}' : ''}${vegetables.isNotEmpty ? ' and ${vegetables.first.name}' : ''}',
      'time': '8 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 95,
      'ingredients': scrambledIngredients,
      'instructions': '1. Beat the ${primary.name} in a bowl\n2. ${cheese.isNotEmpty ? 'Add grated ${cheese.first.name}' : ''}\n3. ${vegetables.isNotEmpty ? 'Sauté ${vegetables.first.name} first, then add eggs' : 'Heat butter in a pan'}\n4. Cook eggs slowly, stirring constantly\n5. Season with salt and pepper, serve hot',
      'nutritionalValue': 'High protein breakfast with essential amino acids',
      'serves': '1-2 people',
    });
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateCheeseBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final vegetables = compatible.where((item) => item.category.toLowerCase() == 'vegetables').toList();
    final bread = compatible.where((item) => 
      item.name.toLowerCase().contains('bread') || 
      item.name.toLowerCase().contains('toast')
    ).toList();
    
    // Cheese Sauce
    recipes.add({
      'name': 'Homemade Cheese Sauce',
      'description': 'Versatile ${primary.name} sauce perfect for pasta, vegetables, or nachos',
      'time': '15 min',
      'difficulty': 'Easy',
      'type': 'sauce',
      'wasteReduction': 95,
      'ingredients': [primary],
      'instructions': '1. Melt butter in a saucepan\n2. Add flour and cook for 1 minute\n3. Gradually whisk in milk\n4. Add ${primary.name} and stir until smooth\n5. Season with salt, pepper, and mustard\n6. Serve over pasta or vegetables',
      'nutritionalValue': 'High in protein and calcium',
      'serves': '4-6 people',
    });
    
    // Cheese and Vegetable Casserole
    if (vegetables.isNotEmpty) {
      final ingredients = [primary, ...vegetables.take(2)];
      
      recipes.add({
        'name': 'Cheese and Vegetable Casserole',
        'description': 'Baked casserole with ${primary.name} and ${vegetables.map((e) => e.name).join(', ')}',
        'time': '45 min',
        'difficulty': 'Medium',
        'type': 'main',
        'wasteReduction': 90,
        'ingredients': ingredients,
        'instructions': '1. Preheat oven to 375°F\n2. ${vegetables.map((e) => 'Slice ${e.name}').join(' and ')}\n3. Layer vegetables in a baking dish\n4. Sprinkle with ${primary.name}\n5. Bake for 30-35 minutes until golden\n6. Let rest 5 minutes before serving',
        'nutritionalValue': 'Complete meal with vegetables and dairy',
        'serves': '4-6 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateVegetableBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final otherVegetables = compatible.where((item) => item.category.toLowerCase() == 'vegetables').toList();
    final cheese = compatible.where((item) => item.name.toLowerCase().contains('cheese')).toList();
    
    // Vegetable Stir-fry
    if (otherVegetables.isNotEmpty) {
      final ingredients = [primary, ...otherVegetables.take(3)];
      
      recipes.add({
        'name': 'Mixed Vegetable Stir-fry',
        'description': 'Quick stir-fry with ${primary.name} and ${otherVegetables.map((e) => e.name).join(', ')}',
        'time': '15 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': ingredients,
        'instructions': '1. Heat oil in a large wok or pan\n2. Add garlic and ginger, cook 30 seconds\n3. Add ${primary.name} and cook 2-3 minutes\n4. Add ${otherVegetables.map((e) => e.name).join(', ')} in order of cooking time\n5. Season with soy sauce and sesame oil\n6. Serve immediately over rice',
        'nutritionalValue': 'High in vitamins, fiber, and antioxidants',
        'serves': '3-4 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateFruitBasedRecipes(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Find compatible ingredients
    final otherFruits = compatible.where((item) => item.category.toLowerCase() == 'fruits').toList();
    final dairy = compatible.where((item) => item.category.toLowerCase() == 'dairy').toList();
    
    // Fruit Smoothie
    if (dairy.isNotEmpty) {
      final ingredients = [primary];
      if (otherFruits.isNotEmpty) ingredients.add(otherFruits.first);
      ingredients.add(dairy.first);
      
      recipes.add({
        'name': 'Fresh Fruit Smoothie',
        'description': 'Nutritious smoothie with ${primary.name}${otherFruits.isNotEmpty ? ', ${otherFruits.first.name}' : ''} and ${dairy.first.name}',
        'time': '5 min',
        'difficulty': 'Easy',
        'type': 'beverage',
        'wasteReduction': 95,
        'ingredients': ingredients,
        'instructions': '1. Peel and chop ${primary.name}${otherFruits.isNotEmpty ? ' and ${otherFruits.first.name}' : ''}\n2. Add to blender with ${dairy.first.name}\n3. Add honey or sugar to taste\n4. Blend until smooth and creamy\n5. Serve immediately over ice',
        'nutritionalValue': 'High in vitamins, antioxidants, and probiotics',
        'serves': '2-3 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateGenericCombinations(InventoryItem primary, List<InventoryItem> compatible, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Create a simple combination recipe
    final ingredients = [primary];
    if (compatible.isNotEmpty) ingredients.add(compatible.first);
    
    recipes.add({
      'name': 'Creative ${primary.name} Dish',
      'description': 'Simple and delicious way to use ${primary.name}${compatible.isNotEmpty ? ' with ${compatible.first.name}' : ''}',
      'time': '20 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 85,
      'ingredients': ingredients,
      'instructions': '1. Prepare ${primary.name} as desired\n2. ${compatible.isNotEmpty ? 'Add ${compatible.first.name} for extra flavor' : 'Season with salt and pepper'}\n3. Cook using your preferred method\n4. Taste and adjust seasoning\n5. Serve hot and enjoy',
      'nutritionalValue': 'Nutritious meal using available ingredients',
      'serves': '2-3 people',
    });
    
    return recipes;
  }

  // Legacy method - keeping for compatibility
  List<Map<String, dynamic>> _generateFruitRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Fruit Smoothie with expiring items
    final smoothieIngredients = [primary];
    final expiringFruits = expiring.where((item) => item.category.toLowerCase() == 'fruits').take(2).toList();
    smoothieIngredients.addAll(expiringFruits);
    
    if (smoothieIngredients.length > 1) {
      recipes.add({
        'name': 'Zero-Waste Fruit Smoothie',
        'description': 'Blend ${smoothieIngredients.map((e) => e.name).join(', ')} with yogurt and honey',
        'time': '5 min',
        'difficulty': 'Easy',
        'type': 'beverage',
        'wasteReduction': 95,
        'ingredients': smoothieIngredients,
        'instructions': '1. Peel and chop all fruits\n2. Add to blender with yogurt and honey\n3. Blend until smooth\n4. Serve immediately',
        'nutritionalValue': 'High in vitamins and antioxidants',
        'serves': '2-3 people',
      });
    }
    
    // Fruit Salad with multiple items
    final saladIngredients = [primary];
    final otherFruits = available.where((item) => 
      item.category.toLowerCase() == 'fruits' && item.id != primary.id
    ).take(3).toList();
    saladIngredients.addAll(otherFruits);
    
    if (saladIngredients.length > 1) {
      recipes.add({
        'name': 'Rainbow Fruit Salad',
        'description': 'Fresh combination of ${saladIngredients.map((e) => e.name).join(', ')}',
        'time': '10 min',
        'difficulty': 'Easy',
        'type': 'salad',
        'wasteReduction': 90,
        'ingredients': saladIngredients,
        'instructions': '1. Wash and cut all fruits into bite-sized pieces\n2. Mix gently in a bowl\n3. Add lemon juice and mint\n4. Chill before serving',
        'nutritionalValue': 'Rich in fiber and natural sugars',
        'serves': '4-6 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateVegetableRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Vegetable Stir-fry with expiring items
    final stirFryIngredients = [primary];
    final expiringVeggies = expiring.where((item) => item.category.toLowerCase() == 'vegetables').take(3).toList();
    stirFryIngredients.addAll(expiringVeggies);
    
    if (stirFryIngredients.length > 1) {
      recipes.add({
        'name': 'Emergency Vegetable Stir-fry',
        'description': 'Quick stir-fry using ${stirFryIngredients.map((e) => e.name).join(', ')}',
        'time': '15 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 95,
        'ingredients': stirFryIngredients,
        'instructions': '1. Heat oil in a large pan\n2. Add garlic and ginger\n3. Add vegetables in order of cooking time\n4. Season with soy sauce and sesame oil\n5. Serve immediately',
        'nutritionalValue': 'High in vitamins and fiber',
        'serves': '2-4 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateDairyRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Cheese-based recipes
    if (primary.name.toLowerCase().contains('cheese')) {
      recipes.add({
        'name': 'Quick Cheese Sauce',
        'description': 'Versatile sauce using ${primary.name}',
        'time': '10 min',
        'difficulty': 'Easy',
        'type': 'sauce',
        'wasteReduction': 95,
        'ingredients': [primary],
        'instructions': '1. Melt butter in a pan\n2. Add flour and cook for 1 minute\n3. Gradually add milk\n4. Add cheese and stir until smooth\n5. Season to taste',
        'nutritionalValue': 'High in protein and calcium',
        'serves': '4-6 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateBreadRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    // Stale bread recipes
    if (primary.expiryDate.difference(DateTime.now()).inDays <= 1) {
      recipes.add({
        'name': 'Bread Pudding Delight',
        'description': 'Transform stale ${primary.name} into a delicious dessert',
        'time': '45 min',
        'difficulty': 'Medium',
        'type': 'dessert',
        'wasteReduction': 100,
        'ingredients': [primary],
        'instructions': '1. Cut bread into cubes\n2. Mix with eggs, milk, and sugar\n3. Add vanilla and cinnamon\n4. Bake at 350°F for 30 minutes\n5. Serve warm',
        'nutritionalValue': 'Comfort food with protein and carbs',
        'serves': '6-8 people',
      });
    }
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateGenericRecipes(InventoryItem primary, List<InventoryItem> available, List<InventoryItem> expiring) {
    final recipes = <Map<String, dynamic>>[];
    
    recipes.add({
      'name': 'Creative Leftover Transformation',
      'description': 'Transform ${primary.name} into something new',
      'time': '20 min',
      'difficulty': 'Easy',
      'type': 'main',
      'wasteReduction': 85,
      'ingredients': [primary],
      'instructions': '1. Assess the condition of ${primary.name}\n2. Remove any bad parts\n3. Season creatively\n4. Cook with complementary ingredients\n5. Serve with confidence',
      'nutritionalValue': 'Maximizes nutrition from available ingredients',
      'serves': '2-4 people',
    });
    
    return recipes;
  }

  List<Map<String, dynamic>> _generateMultiIngredientRecipes() {
    final recipes = <Map<String, dynamic>>[];
    final expiringItems = _viewModel.inventory.where((item) => 
      item.expiryDate.difference(DateTime.now()).inDays <= 2
    ).toList();
    
    // If no expiring items, use all available items
    final availableItems = expiringItems.isNotEmpty ? expiringItems : _viewModel.inventory;
    
    if (availableItems.length >= 2) {
      recipes.add({
        'name': 'Zero-Waste Feast',
        'description': 'Complete meal using ${availableItems.map((e) => e.name).join(', ')}',
        'time': '45 min',
        'difficulty': 'Medium',
        'type': 'main',
        'wasteReduction': 100,
        'ingredients': availableItems,
        'instructions': '1. Sort ingredients by cooking time\n2. Start with longest-cooking items\n3. Add shorter-cooking items progressively\n4. Season and serve as a complete meal',
        'nutritionalValue': 'Complete nutrition from diverse ingredients',
        'serves': '4-6 people',
      });
    }
    
    // Add category-specific multi-ingredient recipes
    if (availableItems.length >= 3) {
      final fruits = availableItems.where((item) => item.category.toLowerCase() == 'fruits').toList();
      final vegetables = availableItems.where((item) => item.category.toLowerCase() == 'vegetables').toList();
      
      if (fruits.length >= 2) {
        recipes.add({
          'name': 'Tropical Fruit Medley',
          'description': 'Fresh combination of ${fruits.map((e) => e.name).join(', ')}',
          'time': '15 min',
          'difficulty': 'Easy',
          'type': 'salad',
          'wasteReduction': 95,
          'ingredients': fruits,
          'instructions': '1. Wash and prepare all fruits\n2. Cut into bite-sized pieces\n3. Mix with lemon juice and honey\n4. Chill and serve',
          'nutritionalValue': 'High in vitamins and natural sugars',
          'serves': '4-6 people',
        });
      }
      
      if (vegetables.length >= 3) {
        recipes.add({
          'name': 'Garden Vegetable Stir-fry',
          'description': 'Quick stir-fry using ${vegetables.map((e) => e.name).join(', ')}',
          'time': '20 min',
          'difficulty': 'Easy',
          'type': 'main',
          'wasteReduction': 90,
          'ingredients': vegetables,
          'instructions': '1. Heat oil in a large wok\n2. Add vegetables in order of cooking time\n3. Season with soy sauce and garlic\n4. Serve over rice or noodles',
          'nutritionalValue': 'High in fiber and vitamins',
          'serves': '3-4 people',
        });
      }
    }
    
    // If still no recipes, add a generic one
    if (recipes.isEmpty && availableItems.isNotEmpty) {
      recipes.add({
        'name': 'Creative Leftover Transformation',
        'description': 'Transform your available ingredients into something delicious',
        'time': '25 min',
        'difficulty': 'Easy',
        'type': 'main',
        'wasteReduction': 85,
        'ingredients': availableItems.take(3).toList(),
        'instructions': '1. Assess all available ingredients\n2. Remove any bad parts\n3. Season creatively with herbs and spices\n4. Cook using your preferred method\n5. Serve with confidence',
        'nutritionalValue': 'Maximizes nutrition from available ingredients',
        'serves': '2-4 people',
      });
    }
    
    return recipes;
  }

  int _calculateUrgency(List<InventoryItem> ingredients) {
    int urgency = 0;
    for (final item in ingredients) {
      final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 1) urgency += 100;
      else if (daysUntilExpiry <= 2) urgency += 80;
      else if (daysUntilExpiry <= 3) urgency += 60;
    }
    return urgency;
  }

  int _calculateUrgencyFromNames(List<String> ingredientNames) {
    int urgency = 0;
    for (final name in ingredientNames) {
      // Find matching inventory item
      final item = _viewModel.inventory.firstWhere(
        (item) => item.name.toLowerCase().contains(name.toLowerCase()) || 
                  name.toLowerCase().contains(item.name.toLowerCase()),
        orElse: () => _viewModel.inventory.first, // fallback
      );
      
      final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 1) urgency += 100;
      else if (daysUntilExpiry <= 2) urgency += 80;
      else if (daysUntilExpiry <= 3) urgency += 60;
    }
    return urgency;
  }

  Color _getRecipeColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getRecipeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'beverage':
        return Icons.local_drink;
      case 'salad':
        return Icons.eco;
      case 'dessert':
        return Icons.cake;
      case 'main':
        return Icons.restaurant;
      case 'side':
        return Icons.dining;
      case 'soup':
        return Icons.soup_kitchen;
      case 'sauce':
        return Icons.water_drop;
      case 'ingredient':
        return Icons.inventory;
      default:
        return Icons.restaurant_menu;
    }
  }

 void _showDetailedAIRecipe(Map<String, dynamic> recipe) {
  showDialog(
    context: context,
    builder: (context) => RecipeDetailDialog(
      recipe: recipe,
      onMarkUsed: _markIngredientsAsUsed,
    ),
  );
}

  void _markIngredientsAsUsed(List<InventoryItem> ingredients) {
    // This would mark ingredients as used in a real implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked ${ingredients.length} ingredients as used!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class AddInventoryDialog extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(InventoryItem) onItemAdded;
  
  const AddInventoryDialog({
    super.key,
    required this.profile,
    required this.onItemAdded,
  });

  @override
  State<AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<AddInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  String _category = 'Fruits';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Inventory Item'),
      content: SingleChildScrollView( // ✅ prevents overflow
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity (e.g., 5 kg, 10 units)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                  DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                  DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                  DropdownMenuItem(value: 'Bread & Pastries', child: Text('Bread & Pastries')),
                  DropdownMenuItem(value: 'Canned Goods', child: Text('Canned Goods')),
                  DropdownMenuItem(value: 'Frozen Foods', child: Text('Frozen Foods')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? 'Fruits'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Expiry Date: ${_expiryDate.toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 👇 Scan Barcode button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScannerScreen(
                        onScanned: (code) async {
                          final product = await BarcodeLookupService.fetchProductFromBarcode(code);

                          setState(() {
                            _nameCtrl.text = product['name'] ?? "Unknown Product";
                            _quantityCtrl.text = product['quantity'] ?? "1";

                            // ✅ Only allow known categories
                            final apiCategory = product['category'] ?? "Other";
                            const allowedCategories = [
                              'Fruits',
                              'Vegetables',
                              'Dairy',
                              'Bread & Pastries',
                              'Canned Goods',
                              'Frozen Foods',
                              'Other',
                            ];

                            if (allowedCategories.contains(apiCategory)) {
                              _category = apiCategory;
                            } else {
                              _category = "Other";
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Scan Barcode"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final newItem = InventoryItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                restaurantId: widget.profile.id,
                name: _nameCtrl.text.trim(),
                quantity: _quantityCtrl.text.trim(),
                category: _category,
                expiryDate: _expiryDate,
                status: 'available',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                await widget.onItemAdded(newItem);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}

class NotificationsDialog extends StatefulWidget {
  const NotificationsDialog({super.key});

  @override
  State<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<NotificationsDialog> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Items Expiring Soon',
      'message': '3 items in your inventory are expiring within 2 days',
      'time': '2 hours ago',
      'type': 'warning',
      'read': false,
    },
    {
      'title': 'Recipe Suggestion',
      'message': 'New recipe available: Chicken Chapati Roll using your expiring items',
      'time': '4 hours ago',
      'type': 'recipe',
      'read': false,
    },
    {
      'title': 'Donation Claimed',
      'message': 'Your "Fresh Vegetables" donation has been claimed by Green NGO',
      'time': '1 day ago',
      'type': 'donation',
      'read': true,
    },
    {
      'title': 'Weekly Impact Report',
      'message': 'You saved 15kg of food waste this week! View your analytics.',
      'time': '2 days ago',
      'type': 'analytics',
      'read': true,
    },
    {
      'title': 'New Feature Available',
      'message': 'Smart recipe generation is now available! Try it out.',
      'time': '3 days ago',
      'type': 'feature',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          '${_notifications.where((n) => !n['read']).length} unread notifications',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Notifications List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationCard(notification, index);
                },
              ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark All Read'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final Color typeColor = _getNotificationTypeColor(notification['type']);
    final IconData typeIcon = _getNotificationTypeIcon(notification['type']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification['read'] ? 1 : 3,
      child: InkWell(
        onTap: () => _markAsRead(index),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification['read'] ? Colors.white : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: typeColor.withOpacity(0.1),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: notification['read'] ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification['read'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['time'],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'recipe':
        return Colors.green;
      case 'donation':
        return Colors.red;
      case 'analytics':
        return Colors.purple;
      case 'feature':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'recipe':
        return Icons.restaurant_menu;
      case 'donation':
        return Icons.favorite;
      case 'analytics':
        return Icons.analytics;
      case 'feature':
        return Icons.new_releases;
      default:
        return Icons.notifications;
    }
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['read'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }
}

class SettingsDialog extends StatefulWidget {
  final UserProfile profile;
  
  const SettingsDialog({super.key, required this.profile});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _expiryNotifications = true;
  bool _donationNotifications = true;
  bool _recipeNotifications = true;
  bool _analyticsNotifications = true;
  double _expiryWarningDays = 3.0;
  bool _autoGenerateRecipes = true;
  bool _darkMode = false;
  String _selectedLanguage = 'English';
  bool _emailReminders = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.green.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restaurant Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          '${widget.profile.name} • ${widget.profile.location}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Settings Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notifications Section
                    _buildSettingsSection(
                      'Notifications',
                      Icons.notifications,
                      Colors.blue,
                      [
                        _buildSwitchTile(
                          'Expiry Warnings',
                          'Get notified when items are about to expire',
                          _expiryNotifications,
                          (value) => setState(() => _expiryNotifications = value),
                        ),
                        _buildSwitchTile(
                          'Donation Updates',
                          'Notifications for donation status changes',
                          _donationNotifications,
                          (value) => setState(() => _donationNotifications = value),
                        ),
                        _buildSwitchTile(
                          'Recipe Suggestions',
                          'Get notified about new recipe opportunities',
                          _recipeNotifications,
                          (value) => setState(() => _recipeNotifications = value),
                        ),
                        _buildSwitchTile(
                          'Analytics Reports',
                          'Weekly and monthly impact reports',
                          _analyticsNotifications,
                          (value) => setState(() => _analyticsNotifications = value),
                        ),
                        _buildSwitchTile(
                          'Email Reminders',
                          'Receive email notifications',
                          _emailReminders,
                          (value) => setState(() => _emailReminders = value),
                        ),
                        _buildSwitchTile(
                          'Push Notifications',
                          'Mobile push notifications',
                          _pushNotifications,
                          (value) => setState(() => _pushNotifications = value),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Inventory Management Section
                    _buildSettingsSection(
                      'Inventory Management',
                      Icons.inventory,
                      Colors.orange,
                      [
                        _buildSliderTile(
                          'Expiry Warning Days',
                          'Days before expiry to show warnings',
                          _expiryWarningDays,
                          1,
                          7,
                          (value) => setState(() => _expiryWarningDays = value),
                        ),
                        _buildSwitchTile(
                          'Auto Recipe Generation',
                          'Automatically suggest recipes for expiring items',
                          _autoGenerateRecipes,
                          (value) => setState(() => _autoGenerateRecipes = value),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // App Preferences Section
                    _buildSettingsSection(
                      'App Preferences',
                      Icons.palette,
                      Colors.purple,
                      [
                        _buildSwitchTile(
                          'Dark Mode',
                          'Use dark theme throughout the app',
                          _darkMode,
                          (value) => setState(() => _darkMode = value),
                        ),
                        _buildDropdownTile(
                          'Language',
                          'Select your preferred language',
                          _selectedLanguage,
                          ['English', 'Spanish', 'French', 'German', 'Hindi'],
                          (value) => setState(() => _selectedLanguage = value!),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Account Section
                    _buildSettingsSection(
                      'Account',
                      Icons.account_circle,
                      Colors.grey,
                      [
                        _buildInfoTile('Restaurant Name', widget.profile.name),
                        _buildInfoTile('Location', widget.profile.location),
                        _buildInfoTile('Role', widget.profile.role.toUpperCase()),
                        _buildActionTile(
                          'Change Password',
                          'Update your account password',
                          Icons.lock,
                          () => _showChangePasswordDialog(),
                        ),
                        _buildActionTile(
                          'Export Data',
                          'Download your inventory and analytics data',
                          Icons.download,
                          () => _showExportDataDialog(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveSettings(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, ValueChanged<double> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              label: '${value.round()} days',
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.info_outline, color: Colors.grey),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(icon, color: Colors.green),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Data export functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // Here you would save the settings to SharedPreferences or database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }
}

class EditInventoryDialog extends StatefulWidget {
  final UserProfile profile;
  final InventoryItem item;
  final Future<void> Function(InventoryItem) onItemUpdated;
  
  const EditInventoryDialog({
    super.key,
    required this.profile,
    required this.item,
    required this.onItemUpdated,
  });

  @override
  State<EditInventoryDialog> createState() => _EditInventoryDialogState();
}

class _EditInventoryDialogState extends State<EditInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _quantityCtrl;
  late String _category;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _quantityCtrl = TextEditingController(text: widget.item.quantity);
    _category = widget.item.category;
    _expiryDate = widget.item.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Inventory Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantity (e.g., 5 kg, 10 units)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                DropdownMenuItem(value: 'Bread & Pastries', child: Text('Bread & Pastries')),
                DropdownMenuItem(value: 'Canned Goods', child: Text('Canned Goods')),
                DropdownMenuItem(value: 'Frozen Foods', child: Text('Frozen Foods')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _category = value ?? 'Fruits'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Expiry Date: ${_expiryDate.toString().split(' ')[0]}'),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _expiryDate = picked);
                    }
                  },
                  child: const Text('Pick Date'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final updatedItem = InventoryItem(
                id: widget.item.id,
                restaurantId: widget.item.restaurantId,
                name: _nameCtrl.text.trim(),
                quantity: _quantityCtrl.text.trim(),
                category: _category,
                expiryDate: _expiryDate,
                status: widget.item.status,
                createdAt: widget.item.createdAt,
                updatedAt: DateTime.now(),
              );
              
              await widget.onItemUpdated(updatedItem);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Update Item'),
        ),
      ],
    );
  }
}

class PostDonationDialog extends StatefulWidget {
  final UserProfile profile;
  final InventoryItem item;
  final Future<void> Function(Donation) onDonationPosted;
  
  const PostDonationDialog({
    super.key,
    required this.profile,
    required this.item,
    required this.onDonationPosted,
  });

  @override
  State<PostDonationDialog> createState() => _PostDonationDialogState();
}

class _PostDonationDialogState extends State<PostDonationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.item.name;
    _descriptionCtrl.text = 'Fresh ${widget.item.name} available for donation';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post as Donation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Donation Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Item Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  Text('Quantity: ${widget.item.quantity}'),
                  Text('Category: ${widget.item.category}'),
                  Text('Expires: ${widget.item.expiryDate.toString().split(' ')[0]}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final donation = Donation(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                restaurantId: widget.profile.id,
                title: _titleCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                quantity: widget.item.quantity,
                expiryDate: widget.item.expiryDate,
                status: 'available',
                postedAt: DateTime.now(),
              );
              await widget.onDonationPosted(donation);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Donation posted successfully!'), backgroundColor: Colors.green),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Post Donation'),
        ),
      ],
    );
  }
}
