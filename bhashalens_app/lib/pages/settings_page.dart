import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = true;
  bool pushNotifications = false;
  bool emailNotifications = false;

  void _navigateTo(String route) {
    if (route == 'settings') {
      // Already on settings, do nothing
      return;
    }
    // Map route keys to named routes
    final routeMap = {
      'edit_profile': '/profile',
      'app_language': '/app_language',
      'default_language': '/default_language',
      'text_size': '/text_size',
      'privacy_policy': '/privacy_policy',
      'security_settings': '/security_settings',
      'about': '/about',
      'help_center': '/help_support',
      'contact_us': '/contact_us',
      'send_feedback': '/send_feedback',
      'terms_of_service': '/terms_of_service',
      'licenses': '/licenses',
      'logout': '/login',
      'delete_account': '/delete_account',
      'home': '/home',
      'camera': '/camera_translate',
      'voice': '/voice_translate',
      'saved': '/saved_translations',
    };
    final namedRoute = routeMap[route];
    if (namedRoute != null) {
      Navigator.of(context).pushNamed(namedRoute);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No page found for "$route"')));
    }
  }

  int _selectedIndex = 4;
  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    // Navigation logic for bottom nav bar
    switch (index) {
      case 0:
        _navigateTo('home');
        break;
      case 1:
        _navigateTo('camera');
        break;
      case 2:
        _navigateTo('voice');
        break;
      case 3:
        _navigateTo('saved');
        break;
      case 4:
        _navigateTo('settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1193d4);
    final bgColor = const Color(0xFF111c22);
    final sectionColor = const Color(0xFF192b33);
    final dividerColor = const Color(0xFF233c48);
    final textColor = Colors.white;
    final subTextColor = const Color(0xFF92b7c9);

    Widget sectionHeader(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    Widget navRow({
      required String title,
      String? subtitle,
      String? route,
      VoidCallback? onTap,
      Widget? trailing,
      bool showArrow = true,
    }) {
      return InkWell(
        onTap: onTap ?? (route != null ? () => _navigateTo(route) : null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: textColor.withOpacity(0.5),
                ),
            ],
          ),
        ),
      );
    }

    Widget switchRow({
      required String title,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: textColor, fontSize: 16)),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: primaryColor,
              inactiveTrackColor: dividerColor,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Profile
          sectionHeader('Profile'),
          navRow(
            title: 'Edit Profile',
            subtitle: 'Jane Doe',
            route: 'edit_profile',
            trailing: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBbVBqt3DYmnbVBx70158AbvCo840Z_4aZoEjpahYl3olS9kOMdyluu09smNvCsklZDlpMr7SwNMm5Dh9ZlgCFqzqyPPtU9vJSOyCI8DV_lTS_-l8H-zZ7NvSmPm4Dk3Mrdutby0hDxYEM-gHet_l_OAK7djeBihoVESUfmgnap070qYfhRyr9aAW2rl9_WtjvQ-R56yhlGiP4ypkTkrQNeZXidPyzOPU5ZSTM5GwT6Y-raFeeMmZn8e3QlxSuFwIqaQEBJzn8-0q4',
              ),
            ),
          ),
          Divider(color: dividerColor, height: 1),

          // Language & Dialect
          sectionHeader('Language & Dialect'),
          navRow(
            title: 'App Language',
            subtitle: 'English (US)',
            route: 'app_language',
          ),
          Divider(color: dividerColor, height: 1),
          navRow(
            title: 'Default Language',
            subtitle: 'English (US)',
            route: 'default_language',
          ),
          Divider(color: dividerColor, height: 1),

          // Accessibility
          sectionHeader('Accessibility'),
          navRow(title: 'Text Size', route: 'text_size'),
          Divider(color: dividerColor, height: 1),
          switchRow(
            title: 'Dark Mode',
            value: isDarkMode,
            onChanged: (val) => setState(() => isDarkMode = val),
          ),
          Divider(color: dividerColor, height: 1),

          // Notifications
          sectionHeader('Notifications'),
          switchRow(
            title: 'Push Notifications',
            value: pushNotifications,
            onChanged: (val) => setState(() => pushNotifications = val),
          ),
          Divider(color: dividerColor, height: 1),
          switchRow(
            title: 'Email Notifications',
            value: emailNotifications,
            onChanged: (val) => setState(() => emailNotifications = val),
          ),
          Divider(color: dividerColor, height: 1),

          // Privacy & Security
          sectionHeader('Privacy & Security'),
          navRow(title: 'Privacy Policy', route: 'privacy_policy'),
          Divider(color: dividerColor, height: 1),
          navRow(title: 'Security Settings', route: 'security_settings'),
          Divider(color: dividerColor, height: 1),

          // General
          sectionHeader('General'),
          navRow(title: 'About', route: 'about'),
          Divider(color: dividerColor, height: 1),
          ListTile(
            title: Text(
              'App Version',
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            trailing: Text(
              '1.2.3',
              style: TextStyle(color: subTextColor, fontSize: 16),
            ),
            tileColor: Colors.transparent,
          ),
          Divider(color: dividerColor, height: 1),

          // Support & Feedback
          sectionHeader('Support & Feedback'),
          navRow(title: 'Help Center', route: 'help_center'),
          Divider(color: dividerColor, height: 1),
          navRow(title: 'Contact Us', route: 'contact_us'),
          Divider(color: dividerColor, height: 1),
          navRow(title: 'Send Feedback', route: 'send_feedback'),
          Divider(color: dividerColor, height: 1),

          // Legal
          sectionHeader('Legal'),
          navRow(title: 'Terms of Service', route: 'terms_of_service'),
          Divider(color: dividerColor, height: 1),
          navRow(title: 'Licenses', route: 'licenses'),
          Divider(color: dividerColor, height: 1),

          // Log Out & Delete Account
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sectionColor,
                      foregroundColor: textColor,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _navigateTo('logout'),
                    child: const Text('Log Out'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _navigateTo('delete_account'),
                    child: const Text('Delete Account'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: sectionColor.withOpacity(0.9),
        selectedItemColor: primaryColor,
        unselectedItemColor: subTextColor,
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera),
            label: 'Camera',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
