import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/notification_service.dart';
import '../dashboard/restaurant_dashboard.dart';
import '../dashboard/ngo_dashboard.dart';

class DemoRolePickerScreen extends StatefulWidget {
  const DemoRolePickerScreen({super.key});

  @override
  State<DemoRolePickerScreen> createState() => _DemoRolePickerScreenState();
}

class _DemoRolePickerScreenState extends State<DemoRolePickerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Demo User');
  final _locationCtrl = TextEditingController(text: 'Demo City');
  String _role = 'restaurant';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _enterDemo() {
  if (!(_formKey.currentState?.validate() ?? false)) return;
    final profile = UserProfile(
      id: 'demo-user-id',
      email: 'demo@example.com',
      name: _nameCtrl.text.trim(),
      role: _role,
      location: _locationCtrl.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    if (_role == 'restaurant') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RestaurantDashboard(profile: profile)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => NGODashboard(profile: profile)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Try Demo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Explore WasteLess without signing up',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
                  DropdownMenuItem(value: 'ngo', child: Text('NGO')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'restaurant'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _enterDemo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Enter Demo'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.showDemoNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo notification sent! Check your device notifications.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.notifications),
                label: const Text('Test Notifications'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

