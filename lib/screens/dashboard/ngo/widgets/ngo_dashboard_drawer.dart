import 'package:flutter/material.dart';
import '../../../../models/user_profile.dart';

class NgoDashboardDrawer extends StatelessWidget {
  final UserProfile profile;
  final TabController tabController;
  final VoidCallback onShowNotifications;
  final VoidCallback onShowSettings;
  final VoidCallback onSignOut;

  const NgoDashboardDrawer({
    super.key,
    required this.profile,
    required this.tabController,
    required this.onShowNotifications,
    required this.onShowSettings,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _DrawerHeader(profile: profile),
          _TabItem(
            icon: Icons.dashboard,
            label: 'Overview',
            index: 0,
            tabController: tabController,
          ),
          _TabItem(
            icon: Icons.map,
            label: 'Discover',
            index: 1,
            tabController: tabController,
          ),
          _TabItem(
            icon: Icons.favorite,
            label: 'Available',
            index: 2,
            tabController: tabController,
          ),
          _TabItem(
            icon: Icons.history,
            label: 'My Claims',
            index: 3,
            tabController: tabController,
          ),
          _TabItem(
            icon: Icons.analytics,
            label: 'Impact',
            index: 4,
            tabController: tabController,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.of(context).pop();
              onShowNotifications();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              onShowSettings();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onSignOut();
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final UserProfile profile;

  const _DrawerHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.blue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          Text(
            profile.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            profile.role.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final TabController tabController;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = tabController.index == index;

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: isSelected,
      onTap: () {
        tabController.animateTo(index);
        Navigator.of(context).pop();
      },
    );
  }
}
