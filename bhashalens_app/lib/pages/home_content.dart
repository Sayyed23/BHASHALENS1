import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:bhashalens_app/services/supabase_auth_service.dart'; // Import SupabaseAuthService
import 'package:carousel_slider/carousel_slider.dart'; // Import carousel_slider

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
            _buildWelcomeUserInfoBlock(context),
            const SizedBox(height: 20),
            _buildQuickActionButtonsBlock(context),
            const SizedBox(height: 20),
            _buildRecentActivityBlock(context),
            const SizedBox(height: 20),
            _buildTipsInfoBlock(context),
            const SizedBox(height: 20),
            // Other blocks will go here
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeUserInfoBlock(BuildContext context) {
    final supabaseAuthService = Provider.of<SupabaseAuthService>(context);
    final userName =
        supabaseAuthService.getCurrentUser()?.email ??
        'Guest'; // Placeholder, replace with actual user name

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $userName!',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Ready to translate?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildQuickActionButtonsBlock(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionButton(
          context,
          Icons.camera_alt,
          'Camera Translate',
          '/camera_translate',
        ),
        _buildActionButton(
          context,
          Icons.mic,
          'Voice Translate',
          '/voice_translate',
        ),
        _buildActionButton(
          context,
          Icons.offline_bolt,
          'Offline Mode',
          '/offline_mode',
        ),
        _buildActionButton(
          context,
          Icons.bookmark,
          'Saved Translations',
          '/saved_translations',
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pushNamed(route),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Theme.of(
          context,
        ).cardColor, // Use card color for a modern look
        foregroundColor: Theme.of(
          context,
        ).textTheme.bodyLarge?.color, // Use text color
        elevation: 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.blueAccent),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityBlock(BuildContext context) {
    // Placeholder data for recent translations
    final List<Map<String, String>> recentTranslations = [
      {'original': 'Hello', 'translated': 'Hola', 'language': 'Spanish'},
      {'original': 'Thank you', 'translated': 'Merci', 'language': 'French'},
      {
        'original': 'Good morning',
        'translated': 'Guten Morgen',
        'language': 'German',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTranslations.length,
          itemBuilder: (context, index) {
            final translation = recentTranslations[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(
                  translation['original']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${translation['translated']} (${translation['language']})',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Implement navigation to re-open translation
                  print('Re-open translation: ${translation['original']}');
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTipsInfoBlock(BuildContext context) {
    final List<Map<String, String>> tips = [
      {
        'title': 'Offline Packs',
        'description': 'Download language packs for offline translation.',
        'icon': 'offline_bolt',
      },
      {
        'title': 'Camera Tips',
        'description': 'For best results, ensure good lighting and clear text.',
        'icon': 'light_mode',
      },
      {
        'title': 'Voice Accuracy',
        'description':
            'Speak clearly and at a moderate pace for better voice translation.',
        'icon': 'volume_up',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips & Information',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        CarouselSlider(
          options: CarouselOptions(
            height: 140, // Increased height to prevent overflow
            enlargeCenterPage: true,
            autoPlay: true,
            aspectRatio: 16 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.8,
          ),
          items: tips.map((tip) {
            return Builder(
              builder: (BuildContext context) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconData(tip['icon']!),
                          size: 30,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tip['title']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          tip['description']!,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'offline_bolt':
        return Icons.offline_bolt;
      case 'light_mode':
        return Icons.light_mode;
      case 'volume_up':
        return Icons.volume_up;
      default:
        return Icons.info_outline;
    }
  }
}
