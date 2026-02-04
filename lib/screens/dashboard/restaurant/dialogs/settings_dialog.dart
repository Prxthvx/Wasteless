import 'package:flutter/material.dart';
import '../../../../models/user_profile.dart';

class SettingsDialog extends StatefulWidget {
  final UserProfile profile;

  const SettingsDialog({
    super.key,
    required this.profile,
  });

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
      child: SizedBox(
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