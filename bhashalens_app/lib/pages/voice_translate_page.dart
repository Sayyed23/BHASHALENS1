import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:bhashalens_app/theme/app_colors.dart';

class VoiceTranslatePage extends StatefulWidget {
  const VoiceTranslatePage({super.key});

  @override
  State<VoiceTranslatePage> createState() => _VoiceTranslatePageState();
}

class _VoiceTranslatePageState extends State<VoiceTranslatePage> {
  String convertLanguageCodeToName(String languageCode) {
    return VoiceTranslationService.supportedLanguages[languageCode] ??
        languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Live Translation',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                Icon(Icons.help_outline_rounded, color: colorScheme.onSurface),
            onPressed: () => _showHelpDialog(theme),
          ),
        ],
      ),
      body: Consumer<VoiceTranslationService>(
        builder: (context, voiceService, child) {
          return Column(
            children: [
              // Language Selector Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Your Language (A)
                    Expanded(
                      child: _buildLanguagePill(
                        voiceService.userALanguage,
                        (lang) => voiceService.setUserALanguage(lang),
                        theme,
                      ),
                    ),

                    // Swap Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => voiceService.swapLanguages(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                    // Their Language (B)
                    Expanded(
                      child: _buildLanguagePill(
                        voiceService.userBLanguage,
                        (lang) => voiceService.setUserBLanguage(lang),
                        theme,
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Area
              Expanded(
                child: Container(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (voiceService.conversationHistory.isEmpty &&
                          !voiceService.isListening &&
                          !voiceService.isTranslating)
                        Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Column(
                            children: [
                              Icon(
                                Icons.mic_rounded,
                                size: 64,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Tap a microphone below to start\na real-time translation",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ...voiceService.conversationHistory.map(
                        (msg) => _buildChatBubble(msg, theme),
                      ),

                      // Active Transcript Bubble
                      if (voiceService.isListening ||
                          voiceService.isTranslating)
                        _buildActiveTranscriptBubble(voiceService, theme),
                    ],
                  ),
                ),
              ),

              // Bottom Controls
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Them / B - Left
                    Expanded(
                      child: _buildMicButton(
                        label: _getLanguageName(voiceService.userBLanguage),
                        subtitle: "Them",
                        isListening: voiceService.isListening &&
                            voiceService.currentSpeaker == 'B',
                        onTap: () => _handleMicrophoneTap('B', voiceService),
                        theme: theme,
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // You / A - Right
                    Expanded(
                      child: _buildMicButton(
                        label: _getLanguageName(voiceService.userALanguage),
                        subtitle: "You",
                        isListening: voiceService.isListening &&
                            voiceService.currentSpeaker == 'A',
                        onTap: () => _handleMicrophoneTap('A', voiceService),
                        theme: theme,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getLanguageName(String code) {
    return VoiceTranslationService.supportedLanguages[code] ?? code;
  }

  Widget _buildLanguagePill(
    String currentCode,
    Function(String) onChanged,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentCode,
          dropdownColor: colorScheme.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: colorScheme.primary, size: 18),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          isExpanded: true,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          items: VoiceTranslationService.supportedLanguages.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMicButton({
    required String label,
    required String subtitle,
    required bool isListening,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isPrimary,
  }) {
    final colorScheme = theme.colorScheme;

    final bgColor = isListening
        ? AppColors.error
        : (isPrimary ? colorScheme.primary : colorScheme.secondary);

    final onColor = isListening
        ? Colors.white
        : (isPrimary ? colorScheme.onPrimary : colorScheme.onSecondary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isListening
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(
              isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
              color: onColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: onColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: onColor.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ConversationMessage msg, ThemeData theme) {
    final isYou = msg.speaker == 'A';
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isYou ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isYou ? const Radius.circular(20) : Radius.zero,
            bottomRight: isYou ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isYou
              ? null
              : Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isYou
                  ? "YOU (${msg.speakerLanguage})"
                  : "THEM (${msg.speakerLanguage})",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isYou
                    ? colorScheme.onPrimary.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg.originalText,
              style: TextStyle(
                color: isYou ? colorScheme.onPrimary : colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              width: double.infinity,
              color: (isYou ? colorScheme.onPrimary : colorScheme.outline)
                  .withValues(alpha: 0.1),
            ),
            const SizedBox(height: 8),
            Text(
              msg.translatedText,
              style: TextStyle(
                color: isYou ? colorScheme.onPrimary : colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTranscriptBubble(
      VoiceTranslationService service, ThemeData theme) {
    final isYou = service.currentSpeaker == 'A';
    final colorScheme = theme.colorScheme;
    final text = service.currentTranscript;
    if (text.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: (isYou ? colorScheme.primary : colorScheme.surface)
              .withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: isYou
              ? null
              : Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isYou ? colorScheme.onPrimary : colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Listening...",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isYou
                        ? colorScheme.onPrimary.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(
                color: isYou ? colorScheme.onPrimary : colorScheme.onSurface,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMicrophoneTap(String user, VoiceTranslationService voiceService) {
    if (voiceService.isListening) {
      voiceService.stopListening();
    } else {
      voiceService.startListening(user);
    }
  }

  void _showHelpDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'How to Use',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHelpStep(Icons.language_rounded,
                'Select languages for "You" and "Them".', theme),
            const SizedBox(height: 16),
            _buildHelpStep(Icons.mic_rounded,
                'Tap a microphone when that person speaks.', theme),
            const SizedBox(height: 16),
            _buildHelpStep(Icons.translate_rounded,
                'App will transcribe and translate instantly.', theme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
