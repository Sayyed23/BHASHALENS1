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
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final firebaseAuthService = Provider.of<FirebaseAuthService>(context);
    // Extract first name for a more personal greeting
    String userName = 'User';
    final user = firebaseAuthService.currentUser;

    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        // Use first name from display name
        userName = user.displayName!.split(' ')[0];
      } else if (user.email != null && user.email!.isNotEmpty) {
        // Fallback to email username
        userName = user.email!.split('@')[0];
      }

      // Capitalize first letter for typical names or email handles
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How can we help you communicate today?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
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
          iconColor: Colors.blue,
          // Using a gradient background to mimic the graphic
          backgroundGradient: const LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => Navigator.pushNamed(context, '/translation_mode'),
        ),
        FeatureCard(
          title: 'Explain & Simplify',
          description:
              'Understand notices, bills, and messages in simple words',
          buttonText: 'Explain Something',
          icon: Icons.article,
          iconColor: Colors.purple,
          // Gradient for the second card
          backgroundGradient: const LinearGradient(
            colors: [Color(0xFF4B1248), Color(0xFFF0C27B)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            stops: [0.0, 1.0], // Dark purple to soft gold/white
          ),
          // To make it look more like the mockup (grey/white image), we can tweak colors
          // For now, using a solid distinctive look
          backgroundColor: const Color(0xFF2D2D2D),
          onTap: () => Navigator.pushNamed(context, '/explain_mode'),
        ),
        FeatureCard(
          title: 'Daily Life Assistant',
          description:
              'Speak confidently in offices, hospitals, and daily life',
          buttonText: 'Get Help Speaking',
          icon: Icons.chat_bubble,
          iconColor: Colors.green,
          // Gradient for the third card
          backgroundGradient: const LinearGradient(
            colors: [Color(0xFF134E5E), Color(0xFF71B280)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
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
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            QuickAccessButton(
              label: 'SOS',
              icon: Icons.light_mode, // Or dedicated SOS icon if available
              color: const Color(0xFFE57373), // Red/Pink
              onTap: () {
                // TODO
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('SOS Clicked')),
                );
              },
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'Offline Pack',
              icon: Icons.wifi_off,
              color: const Color(0xFF64B5F6), // Blue
              onTap: () => Navigator.pushNamed(context, '/offline_models'),
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'Saved Items',
              icon: Icons.bookmark,
              color: const Color(0xFFFFD54F), // Amber/Yellow
              onTap: () => Navigator.pushNamed(context, '/saved_translations'),
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'History',
              icon: Icons.history,
              color: const Color(0xFFE0E0E0), // Grey
              onTap: () {
                // TODO
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('History Clicked')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
