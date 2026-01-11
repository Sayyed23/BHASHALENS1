import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/firebase_auth_service.dart';
import 'package:bhashalens_app/pages/home/widgets/feature_card.dart';
import 'package:bhashalens_app/pages/home/widgets/recent_activity_card.dart';
import 'package:bhashalens_app/pages/home/widgets/quick_access_button.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            RecentActivityCard(
              onTap: () {
                // TODO: Navigate to recent activity details
              },
            ),
            const SizedBox(height: 24),
            _buildFeatureCards(context),
            const SizedBox(height: 24),
            _buildQuickAccessSection(context),
            const SizedBox(height: 100), // Bottom padding for scrolling
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final firebaseAuthService = Provider.of<FirebaseAuthService>(context);
    String userName =
        'User'; // Default fallback name    
    final user = firebaseAuthService.currentUser;

    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userName = user.displayName!.split(' ')[0];
      } else if (user.email != null && user.email!.isNotEmpty) {
        userName = user.email!.split('@')[0];
      }
      if (userName.isNotEmpty) {
        userName =
            userName[0].toUpperCase() + userName.substring(1).toLowerCase();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Namaste, $userName',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How can we help you communicate today?',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF94A3B8), // Slate-400 equivalent
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      children: [
        FeatureCard(
          title: 'Translation Mode',
          description: 'Translate text, voice, and signboards instantly',
          buttonText: 'Open Translation Mode',
          icon: Icons.camera_alt,
          iconColor: const Color(0xFF0EA5E9), // Sky Blue
          isPrimary: true,
          // Deep Blue Wave Gradient
          backgroundGradient: const LinearGradient(
            colors: [
              Color(0xFF0F172A), // Dark Slate
              Color(0xFF1E3A8A), // Dark Blue
              Color(0xFF1D4ED8), // Blue
            ],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
          onTap: () => Navigator.pushNamed(context, '/translation_mode'),
        ),
        FeatureCard(
          title: 'Explain & Simplify',
          description:
              'Understand notices, bills, and messages in simple words',
          buttonText: 'Explain Something',
          icon: Icons.article,
          iconColor: const Color(0xFFA855F7), // Purple
          // Soft Purple/Grey Gradient
          backgroundGradient: LinearGradient(
            colors: [
              const Color(0xFF581C87).withValues(alpha: 0.2),
              const Color(0xFFC084FC).withValues(alpha: 0.1),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          onTap: () => Navigator.pushNamed(context, '/explain_mode'),
        ),
        FeatureCard(
          title: 'Daily Life Assistant',
          description:
              'Speak confidently in offices, hospitals, and daily life',
          buttonText: 'Get Help Speaking',
          icon: Icons.chat_bubble,
          iconColor: const Color(0xFF22C55E), // Green
          // Soft Green Gradient
          backgroundGradient: LinearGradient(
            colors: [
              const Color(0xFF14532D).withValues(alpha: 0.3),
              const Color(0xFF4ADE80).withValues(alpha: 0.1),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          onTap: () => Navigator.pushNamed(context, '/assistant_mode'),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACCESS',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            QuickAccessButton(
              label: 'SOS',
              icon: Icons.campaign, // Siren/Alert
              color: const Color(0xFFEF4444), // Red-500
              onTap: () {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('SOS Feature Coming Soon'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'Offline Pack',
              icon: Icons.wifi_off,
              color: const Color(0xFF3B82F6), // Blue-500
              onTap: () => Navigator.pushNamed(context, '/offline_models'),
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'Saved Items',
              icon: Icons.bookmark,
              color: const Color(0xFFEAB308), // Yellow-500
              onTap: () => Navigator.pushNamed(
                context,
                '/history_saved',
                arguments: 1,
              ), // Index 1 for Saved
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'History',
              icon: Icons.history,
              color: const Color(0xFF94A3B8), // Slate-400
              onTap: () =>
                  Navigator.pushNamed(context, '/history_saved', arguments: 0),
            ),
          ],
        ),
      ],
    );
  }
}
