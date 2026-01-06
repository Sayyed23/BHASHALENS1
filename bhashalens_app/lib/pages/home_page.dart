import 'package:flutter/material.dart';
import 'package:bhashalens_app/widgets/home_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, '/translation_mode');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/explain_mode');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/assistant_mode');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/settings');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force dark theme as per design request for Home Page visual style if desired,
    // or rely on system theme. The requirement said "Dark theme with soft gradients".
    // We will assume the AppTheme handles the dark mode toggle or we can wrap scaffold.

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // 1. Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/logo2.png', height: 28),
                      const SizedBox(width: 8),
                      Text(
                        'BhashaLens',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'HI',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.swap_horiz, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'EN',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                        icon: const Icon(Icons.settings),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 2. Greeting Section
              Text(
                'Namaste, Rahul',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'How can we help you communicate today?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              // 3. Recent Activity Card
              RecentActivityCard(
                subtitle: 'Voice translation: English to Hindi',
                onTap: () {
                  // TODO: Navigate to history details
                },
              ),

              // 4. Mode Selection Cards
              ModeCard(
                icon: Icons.camera_alt, // Combined icon concept
                title: 'Translation Mode',
                description: 'Translate text, voice, and signboards instantly',
                buttonText: 'Open Translation Mode',
                // Using a gradient-like solid color for now as placeholder for "soft gradients"
                color: const Color(0xFF1E2B3A),
                // In a real app, use gradients or background images
                onTap: () => Navigator.pushNamed(context, '/translation_mode'),
              ),
              ModeCard(
                icon: Icons.description,
                title: 'Explain & Simplify',
                description:
                    'Understand notices, bills, and messages in simple words',
                buttonText: 'Explain Something',
                color: const Color(0xFF2A2A2A),
                onTap: () => Navigator.pushNamed(context, '/explain_mode'),
              ),
              ModeCard(
                icon: Icons.chat_bubble,
                title: 'Daily Life Assistant',
                description:
                    'Speak confidently in offices, hospitals, and daily life',
                buttonText: 'Get Help Speaking',
                color: const Color(0xFF233025),
                onTap: () => Navigator.pushNamed(context, '/assistant_mode'),
              ),

              const SizedBox(height: 24),

              // 5. Quick Access Section
              Text(
                'QUICK ACCESS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickAccessButton(
                    icon: Icons.emergency,
                    label: 'SOS',
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => Navigator.pushNamed(context, '/emergency'),
                  ),
                  const SizedBox(width: 12),
                  QuickAccessButton(
                    icon: Icons.wifi_off,
                    label: 'Offline Pack',
                    onTap: () =>
                        Navigator.pushNamed(context, '/offline_models'),
                  ),
                  const SizedBox(width: 12),
                  QuickAccessButton(
                    icon: Icons.bookmark,
                    label: 'Saved Items',
                    onTap: () =>
                        Navigator.pushNamed(context, '/saved_translations'),
                  ),
                  const SizedBox(width: 12),
                  QuickAccessButton(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () {
                      // TODO: Navigate to history
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: 'Translate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Explain',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
