import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/firebase_auth_service.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseAuthService = Provider.of<FirebaseAuthService>(context);
    // Extract first name for greeting if possible
    String displayName = 'Guest';
    final userEmail = firebaseAuthService.currentUser?.email;
    if (userEmail != null && userEmail.isNotEmpty) {
      displayName = userEmail.split('@')[0];
      // Capitalize first letter
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Section
          Text(
            'Namaste, $displayName',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How can we help you communicate today?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Recent Activity Card
          _buildRecentActivity(context),
          const SizedBox(height: 24),

          // Main Functionality Cards
          _buildFeatureCard(
            context,
            title: 'Translation Mode',
            description: 'Translate text, voice, and signboards instantly',
            buttonText: 'Open Translation Mode',
            icon: Icons.camera_alt,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
              ], // Dark Blue to Blue
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.pushNamed(context, '/translation_mode'),
            iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Explain & Simplify',
            description:
                'Understand notices, bills, and messages in simple words',
            buttonText: 'Explain Something',
            icon: Icons.description,
            gradient: const LinearGradient(
              colors: [Color(0xFF374151), Color(0xFF4B5563)], // Dark Grey
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.pushNamed(context, '/explain_mode'),
            iconBackgroundColor: Colors.purple.withValues(alpha: 0.3),
            accentColor: Colors.purpleAccent,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Daily Life Assistant',
            description:
                'Speak confidently in offices, hospitals, and daily life',
            buttonText: 'Get Help Speaking',
            icon: Icons.chat_bubble,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3930), Color(0xFF14532D)], // Dark Green
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.pushNamed(context, '/assistant_mode'),
            iconBackgroundColor: Colors.green.withValues(alpha: 0.3),
            accentColor: Colors.greenAccent,
          ),
          const SizedBox(height: 32),

          // Quick Access Section
          Text(
            'QUICK ACCESS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickAccessGrid(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to history or last item
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent activity',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Medical Bill Translation',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required Color iconBackgroundColor,
    Color? accentColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: accentColor ?? Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    final items = [
      {
        'icon': Icons.sos,
        'label': 'SOS',
        'color': Colors.redAccent,
        'route': '/emergency',
      },
      {
        'icon': Icons.wifi_off,
        'label': 'Offline Pack',
        'color': Colors.blue,
        'route': '/offline_models',
      },
      {
        'icon': Icons.bookmark,
        'label': 'Saved Items',
        'color': Colors.amber,
        'route': '/saved_translations',
      },
      {
        'icon': Icons.history,
        'label': 'History',
        'color': Colors.grey,
        'route': '/saved_translations',
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        return _buildQuickAccessItem(
          context,
          icon: item['icon'] as IconData,
          label: item['label'] as String,
          color: item['color'] as Color,
          onTap: () {
            final route = item['route'] as String?;
            if (route != null) {
              Navigator.pushNamed(context, route);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
