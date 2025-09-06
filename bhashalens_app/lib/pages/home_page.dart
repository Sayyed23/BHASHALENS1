import 'package:flutter/material.dart';
import 'package:bhashalens_app/widgets/responsive_layout.dart';
import 'package:bhashalens_app/services/supabase_auth_service.dart';
import 'package:bhashalens_app/pages/home_content.dart'; // Import HomeContent
import 'package:bhashalens_app/pages/camera_translate_page.dart'; // Import CameraTranslatePage
import 'package:bhashalens_app/pages/voice_translate_page.dart'; // Import VoiceTranslatePage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Set Home as default selected tab

  // Using a GlobalKey for the Scaffold to open the drawer from anywhere
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<Widget> _widgetOptions = <Widget>[
    // Placeholder widgets for each tab
    HomeContent(), // Use HomeContent for the Home tab
    Center(child: Text('Camera Translate Content')),
    VoiceTranslatePage(), // Voice Translate Content
    Center(child: Text('Saved Translations Content')),
    Center(child: Text('Settings Content')),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Camera tab
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CameraTranslatePage()),
      );
    } else if (index == 2) {
      // Voice tab
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const VoiceTranslatePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(context),
      desktopBody: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo2.png',
              height: 30, // Adjust height as needed
            ),
            const SizedBox(width: 8),
            Text(
              'BhashaLens',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Navigate to Notification Page
              print('Navigate to Notification Page');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo2.png',
              height: 30, // Adjust height as needed
            ),
            const SizedBox(width: 8),
            Text(
              'BhashaLens',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Navigate to Notification Page
              print('Navigate to Notification Page');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              if (index == 1) {
                // Camera tab
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CameraTranslatePage(),
                  ),
                );
              } else if (index == 2) {
                // Voice tab
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VoiceTranslatePage(),
                  ),
                );
              } else {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.camera_alt),
                label: Text('Camera'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.mic),
                label: Text('Voice'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bookmark),
                label: Text('Saved'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Center(child: _widgetOptions.elementAt(_selectedIndex)),
          ),
        ],
      ),
      // Desktop layout might use a permanent drawer or side navigation
      drawer: _buildDrawer(
        context,
      ), // Still use the same drawer for consistency
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.of(context).pushNamed('/help_support');
            },
          ),
          ListTile(
            leading: const Icon(Icons.emergency),
            title: const Text('Emergency'),
            onTap: () {
              Navigator.of(context).pushNamed('/emergency');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await SupabaseAuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
          // TODO: Add more drawer items as needed
        ],
      ),
    );
  }
}
