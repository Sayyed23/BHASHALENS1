import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bhashalens_app/pages/home/home_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _connectivity = Connectivity();

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 1) {
      Navigator.pushNamed(context, '/translation_mode').then((_) {
        // Reset to Home index after returning
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
      });
    } else if (index == 2) {
      Navigator.pushNamed(context, '/explain_mode').then((_) {
        // Reset to Home index after returning
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
      });
    } else if (index == 3) {
      Navigator.pushNamed(context, '/history_saved', arguments: 0).then((_) {
        // Reset to Home index after returning
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
      });
    } else if (index == 4) {
      Navigator.pushNamed(context, '/assistant_mode').then((_) {
        // Reset to Home index after returning
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
      });
    }
  }

  @override
  void dispose() {
    // StreamBuilder handles the subscription, but good practice to clean up if we had manual listeners.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ... (Keep existing AppBar code if I can't see it all, but I have viewed it)
        // I will just return the modified BottomNavigationBar part to avoid replacing valid AppBar code blindly
        // using replace_file_content on the bottom part.
        backgroundColor: const Color(0xFF0F172A), // Dark background
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.translate, color: Colors.blue[400]),
            const SizedBox(width: 8),
            const Text(
              'BhashaLens',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            StreamBuilder<List<ConnectivityResult>>(
              stream: _connectivity.onConnectivityChanged,
              builder: (context, snapshot) {
                final results = snapshot.data;
                // Check if offline (basic check: contains none or empty)
                final hasConnection =
                    results != null &&
                    (results.contains(ConnectivityResult.mobile) ||
                        results.contains(ConnectivityResult.wifi) ||
                        results.contains(ConnectivityResult.ethernet));

                // If snapshot has data and NO connection, show offline
                if (snapshot.hasData && !hasConnection) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[600]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_off, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          "Offline",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          Consumer<VoiceTranslationService>(
            builder: (context, voiceService, child) {
              return GestureDetector(
                onTap: () {
                  voiceService.swapLanguages();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        voiceService.userBLanguage.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.swap_horiz,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        voiceService.userALanguage.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const SafeArea(child: HomeContent()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: Colors.blue[400],
        unselectedItemColor: Colors.grey,
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Records'),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}
