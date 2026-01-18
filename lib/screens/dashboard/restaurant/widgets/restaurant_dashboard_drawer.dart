import 'package:flutter/material.dart';

class RestaurantDashboardDrawer extends StatelessWidget {
  final String name;
  final String role;
  final int currentTab;
  final void Function(int index) onTabSelected;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  const RestaurantDashboardDrawer({
    super.key,
    required this.name,
    required this.role,
    required this.currentTab,
    required this.onTabSelected,
    required this.onNotifications,
    required this.onSettings,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.recycling, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          _drawerItem(context, Icons.dashboard, 'Dashboard', 0),
          _drawerItem(context, Icons.inventory, 'Inventory', 1),
          _drawerItem(context, Icons.favorite, 'Donations', 2),
          _drawerItem(context, Icons.restaurant_menu, 'Recipes', 3),
          _drawerItem(context, Icons.analytics, 'Analytics', 4),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              onNotifications();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              onSettings();
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onSignOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: currentTab == index,
      onTap: () {
        Navigator.pop(context);
        onTabSelected(index);
      },
    );
  }
}
