import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/firebase_auth_service.dart';
import 'package:bhashalens_app/pages/home/widgets/feature_card.dart';
import 'package:bhashalens_app/pages/home/widgets/recent_activity_card.dart';
import 'package:bhashalens_app/pages/home/widgets/quick_access_button.dart';
import 'package:bhashalens_app/theme/app_colors.dart';

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
    String userName = 'User'; // Default fallback name

    try {
      final firebaseAuthService = Provider.of<FirebaseAuthService?>(context);
      if (firebaseAuthService != null) {
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
      }
    } catch (e) {
      // Auth service not available, stick to default 'User'
      debugPrint('Auth service access error: $e');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Namaste, $userName 👋',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'How can we help you communicate today?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          iconColor: AppColors.blue600,
          isPrimary: true,
          // Premium Deep Blue Gradient
          backgroundGradient: const LinearGradient(
            colors: [
              AppColors.slate900,
              AppColors.blue700,
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
          onTap: () => Navigator.pushNamed(context, '/explain_mode'),
        ),
        FeatureCard(
          title: 'Daily Life Assistant',
          description:
              'Speak confidently in offices, hospitals, and daily life',
          buttonText: 'Get Help Speaking',
          icon: Icons.chat_bubble,
          iconColor: const Color(0xFF22C55E), // Green
          onTap: () => Navigator.pushNamed(context, '/assistant_mode'),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACCESS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            QuickAccessButton(
              label: 'SOS',
              icon: Icons.campaign,
              color: AppColors.sosRed,
              onTap: () {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('SOS Feature Coming Soon'),
                    backgroundColor: AppColors.sosRed,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'Offline Pack',
              icon: Icons.wifi_off,
              color: AppColors.blue600,
              onTap: () => Navigator.pushNamed(context, '/offline_models'),
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'Saved Items',
              icon: Icons.bookmark,
              color: const Color(0xFFEAB308), // Yellow
              onTap: () => Navigator.pushNamed(
                context,
                '/history_saved',
                arguments: 1,
              ),
            ),
            const SizedBox(width: 12),
            QuickAccessButton(
              label: 'History',
              icon: Icons.history,
              color: theme.colorScheme.onSurfaceVariant,
              onTap: () =>
                  Navigator.pushNamed(context, '/history_saved', arguments: 0),
            ),
          ],
        ),
      ],
    );
  }
}
