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
import 'dialogs/add_inventory_flow.dart';
import 'widgets/restaurant_dashboard_drawer.dart';

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
        leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
                    },
                  )   ,
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
          ),
          RestaurantRecipesTab(
              viewModel: _viewModel,
             onGenerateRecipe: _showRecipeGenerationDialog,
             onGenerateAdvancedRecipe: _showAdvancedRecipeDialog,
          ),
          RestaurantAnalyticsTab(viewModel: _viewModel),
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
    );
  }

   
  Widget _buildFloatingActionButton() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
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
