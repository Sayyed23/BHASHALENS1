import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/accessibility_service.dart';
import 'package:bhashalens_app/services/supabase_auth_service.dart';
import 'package:bhashalens_app/pages/gemini_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibilityService = Provider.of<AccessibilityService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: Navigate to profile settings
          ),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Preferred Language & Dialect'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: Navigate to language settings
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.blue),
            title: const Text('Gemini AI Settings'),
            subtitle: const Text('Configure OCR and Translation'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GeminiSettingsPage(),
                ),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notification Settings'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: Navigate to notification settings
          ),
          SwitchListTile(
            title: const Text('High Contrast Mode'),
            secondary: const Icon(Icons.contrast),
            value: accessibilityService.highContrastMode,
            onChanged: (bool value) {
              accessibilityService.toggleHighContrastMode();
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Text Size'),
            trailing: DropdownButton<double>(
              value: accessibilityService.textSizeFactor,
              items: const [
                DropdownMenuItem(value: 0.8, child: Text('Small')),
                DropdownMenuItem(value: 1.0, child: Text('Medium')),
                DropdownMenuItem(value: 1.2, child: Text('Large')),
              ],
              onChanged: (double? newValue) {
                if (newValue != null) {
                  accessibilityService.setTextSizeFactor(newValue);
                }
              },
            ),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: Navigate to privacy settings
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authService = Provider.of<SupabaseAuthService>(
      context,
      listen: false,
    );
    final String? error = await authService.signOut();

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged out!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigation will be handled automatically by the auth state listener in main.dart
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
