import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../models/inventory_item.dart';
import '../../../services/supabase_service.dart';
import '../../../services/recipe_api_service.dart';
import '../../../services/chat_navigation_helper.dart';
import 'view_model/restaurant_dashboard_view_model.dart';
import 'tabs/overview/restaurant_overview_tab.dart';
import 'tabs/inventory/restaurant_inventory_tab.dart';
import 'tabs/donations/restaurant_donations_tab.dart';
import 'tabs/recipes/restaurant_recipes_tab.dart';
import 'tabs/recipes/dialogs/recipe_generation_dialog.dart';
import 'tabs/recipes/dialogs/advanced_recipe_dialog.dart';
import 'tabs/recipes/dialogs/recipe_detail_dialog.dart';
import 'tabs/analytics/restaurant_analytics.dart';
import 'dialogs/add_inventory_flow.dart';
import 'widgets/restaurant_dashboard_drawer.dart';
import 'dialogs/notifications_dialog.dart';
import 'dialogs/settings_dialog.dart';
import 'dialogs/edit_inventory_dialog.dart';
import 'dialogs/post_donation_dialog.dart';
import '../../chat/widgets/unread_badge.dart';

class RestaurantDashboard extends StatefulWidget {
  final UserProfile profile;

  const RestaurantDashboard({super.key, required this.profile});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final RestaurantDashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);

    _viewModel = RestaurantDashboardViewModel();
    _viewModel.addListener(_onViewModelChanged);

    _loadData();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _viewModel.loadData(
        restaurantId: widget.profile.id,
        isDemo: widget.profile.id == 'demo-user-id',
      );
    } catch (e, stackTrace) {
      debugPrint('Error loading data: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButtonWithBadge(
            icon: Icons.chat,
            badgeCount: 0, // TODO: Connect to ChatService for real count
            iconColor: Colors.white,
            onPressed: () {
              ChatNavigationHelper.navigateToChatList(
                context: context,
                currentUserId: widget.profile.id,
              );
            },
          ),
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
            key: ValueKey(_viewModel.inventory.length),
            viewModel: _viewModel,
            onRefresh: _loadData,
            onItemAction: _handleInventoryAction,
          ),
          RestaurantDonationsTab(
            viewModel: _viewModel,
            onRefresh: _loadData,
            currentUserId: widget.profile.id,
          ),
          RestaurantRecipesTab(
            viewModel: _viewModel,
            onGenerateRecipe: _showRecipeGenerationDialog,
            onGenerateAdvancedRecipe: _showAdvancedRecipeDialog,
          ),
          RestaurantAnalyticsTab(
            viewModel: _viewModel,
            onNavigate: (index) => _tabController.animateTo(index),
          ),
        ],
      ),
      drawer: RestaurantDashboardDrawer(
        name: widget.profile.name,
        role: widget.profile.role,
        currentTab: _tabController.index,
        onTabSelected: (index) => _tabController.animateTo(index),
        onNotifications: _showNotifications,
        onSettings: _showSettings,
        onSignOut: _signOut,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget? _buildFloatingActionButton() {
    // Only show the add inventory button on the Inventory tab (index 1)
    if (_tabController.index != 1) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () => _onAddInventoryPressed(),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  void _onAddInventoryPressed() {
    showAddInventoryDialog(
      context: context,
      profile: widget.profile,
      viewModel: _viewModel,
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
                final index = _viewModel.inventory.indexWhere(
                  (i) => i.id == item.id,
                );
                if (index != -1) {
                  _viewModel.inventory[index] = savedItem;
                }
              });
            } else {
              setState(() {
                final index = _viewModel.inventory.indexWhere(
                  (i) => i.id == item.id,
                );
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
          // Capture ScaffoldMessenger before any async operations that might close the dialog
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          try {
            if (widget.profile.id != 'demo-user-id') {
              await _viewModel.addDonation(
                restaurantId: widget.profile.id,
                inventoryItemId: item.id,
                title: donation.title,
                description: donation.description,
                quantity: donation.quantity,
                expiryDate: donation.expiryDate,
              );
            } else {
              setState(() {
                _viewModel.donations.add(donation);
                // Remove from inventory in demo mode
                _viewModel.inventory.removeWhere((i) => i.id == item.id);
              });
              _viewModel.calculateAnalytics();
            }
            // Close dialog
            if (mounted) Navigator.of(context).pop();
            // Show success message using captured messenger
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Donation posted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            // Close dialog on error too
            if (mounted) Navigator.of(context).pop();
            // Reload data to recover from error state
            await _loadData();
            // Show error message using captured messenger
            scaffoldMessenger.showSnackBar(
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

  Future<void> _signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
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
  Future<List<Map<String, dynamic>>> _generateAIRecipe(
    InventoryItem primaryItem,
  ) async {
    final availableItems = _viewModel.inventory
        .where((item) => item.id != primaryItem.id)
        .toList();
    // final expiringItems = availableItems.where((item) =>
    //   item.expiryDate.difference(DateTime.now()).inDays <= 3
    // ).toList();

    // Use real recipe API
    final allIngredients = [primaryItem, ...availableItems];
    final recipes = await RecipeApiService.getRecipesByIngredients(
      allIngredients,
    );

    // Sort by waste reduction potential and expiry urgency
    recipes.sort((a, b) {
      final aUrgency = _calculateUrgencyFromNames(
        a['ingredients'] as List<String>,
      );
      final bUrgency = _calculateUrgencyFromNames(
        b['ingredients'] as List<String>,
      );
      return bUrgency.compareTo(aUrgency);
    });

    return recipes.take(3).toList(); // Return top 3 recipes
  }

  int _calculateUrgencyFromNames(List<String> ingredientNames) {
    int urgency = 0;
    for (final name in ingredientNames) {
      // Find matching inventory item
      final item = _viewModel.inventory.firstWhere(
        (item) =>
            item.name.toLowerCase().contains(name.toLowerCase()) ||
            name.toLowerCase().contains(item.name.toLowerCase()),
        orElse: () => _viewModel.inventory.first, // fallback
      );

      final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 1) {
        urgency += 100;
      } else if (daysUntilExpiry <= 2)
        urgency += 80;
      else if (daysUntilExpiry <= 3)
        urgency += 60;
    }
    return urgency;
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
