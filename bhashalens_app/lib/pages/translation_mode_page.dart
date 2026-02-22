import 'package:flutter/material.dart';
import 'package:bhashalens_app/pages/camera_translate_page.dart';
import 'package:bhashalens_app/pages/voice_translate_page.dart';
import 'package:bhashalens_app/pages/text_translate_page.dart';
import 'package:bhashalens_app/pages/home/widgets/feature_card.dart';
import 'package:bhashalens_app/theme/app_colors.dart';

class TranslationModePage extends StatelessWidget {
  const TranslationModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Translation Mode'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          FeatureCard(
            icon: Icons.camera_alt_rounded,
            title: 'Camera Translate',
            description:
                'Snap a photo to translate signboards, menus, and documents instantly.',
            buttonText: 'Open Camera',
            iconColor: AppColors.blue600,
            isPrimary: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraTranslatePage(),
                ),
              );
            },
          ),
          FeatureCard(
            icon: Icons.mic_rounded,
            title: 'Voice Translate',
            description:
                'Speak and translate in real-time for seamless conversations.',
            buttonText: 'Start Speaking',
            iconColor: const Color(0xFFA855F7), // Purple
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoiceTranslatePage(),
                ),
              );
            },
          ),
          FeatureCard(
            icon: Icons.translate_rounded,
            title: 'Text Translate',
            description:
                'Enter text manually to get accurate translations in seconds.',
            buttonText: 'Type Message',
            iconColor: const Color(0xFF22C55E), // Green
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TextTranslatePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
