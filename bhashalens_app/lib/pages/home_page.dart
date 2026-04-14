import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bhashalens_app/pages/home/home_content.dart';
import 'package:bhashalens_app/widgets/common_bottom_nav_bar.dart';
import 'package:bhashalens_app/widgets/web_constrained_body.dart';
import 'package:bhashalens_app/widgets/accessibility_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _connectivity = Connectivity();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
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
                final hasConnection =
                    results != null &&
                    (results.contains(ConnectivityResult.mobile) ||
                        results.contains(ConnectivityResult.wifi) ||
                        results.contains(ConnectivityResult.ethernet));

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
      body: AccessibilityWrapper(
        currentPage: '/home',
        child: wrapWithWebMaxWidth(
          context,
          child: const SafeArea(child: HomeContent()),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 0),
    );
  }
}
