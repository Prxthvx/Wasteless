import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../services/supabase_service.dart';

class SettingsDialog extends StatelessWidget {
  final UserProfile profile;
  const SettingsDialog({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NGO: ${profile.name}'),
          Text('Location: ${profile.location}'),
          const SizedBox(height: 16),
          const Text('Settings options would go here'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size.fromHeight(40),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.client.auth.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sign out failed: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
