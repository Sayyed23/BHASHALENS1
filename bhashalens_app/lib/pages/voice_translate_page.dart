import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';

class VoiceTranslatePage extends StatefulWidget {
  const VoiceTranslatePage({super.key});

  @override
  State<VoiceTranslatePage> createState() => _VoiceTranslatePageState();
}

class _VoiceTranslatePageState extends State<VoiceTranslatePage> {
  // VoiceTranslationService is accessed via Provider

  String convertLanguageCodeToName(String languageCode) {
    return VoiceTranslationService.supportedLanguages[languageCode] ??
        languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // We force dark mode look for this page based on mock (dark background)
    // Or we respect theme but use specific colors. Mock is dark.
    // Let's use the dark colors from mock.
    const backgroundColor = Color(0xFF111827); // Dark background
    const surfaceColor = Color(0xFF1F2937); // Card/Bubble default
    const accentColor = Color(0xFF3B82F6); // Blue

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Voice Translation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelpDialog(theme, true),
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
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Your Language (A)
                    _buildLanguagePill(
                      voiceService.userALanguage,
                      (lang) => voiceService.setUserALanguage(lang),
                      theme,
                    ),

                    // Swap Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GestureDetector(
                        onTap: () => voiceService.swapLanguages(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                    // Their Language (B)
                    _buildLanguagePill(
                      voiceService.userBLanguage,
                      (lang) => voiceService.setUserBLanguage(lang),
                      theme,
                    ),
                  ],
                ),
              ),

              // Chat Area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Show user Prompt "Tap a microphone below to start translating." if empty
                    if (voiceService.conversationHistory.isEmpty &&
                        !voiceService.isListening &&
                        !voiceService.isTranslating)
                      const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Column(
                          children: [
                            Icon(Icons.mic, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "Tap a microphone below to start translating.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                    ...voiceService.conversationHistory.map(
                      (msg) => _buildChatBubble(msg),
                    ),

                    // Active Transcript Bubble
                    if (voiceService.isListening || voiceService.isTranslating)
                      _buildActiveTranscriptBubble(voiceService),
                  ],
                ),
              ),

              // Bottom Controls
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                decoration: const BoxDecoration(
                  color: backgroundColor, // Match/Extend body
                ),
                child: Row(
                  children: [
                    // Hindi (Them / B) - Left
                    Expanded(
                      child: _buildMicButton(
                        label:
                            "${_getLanguageName(voiceService.userBLanguage)} (Them)",
                        isListening:
                            voiceService.isListening &&
                            voiceService.currentSpeaker == 'B',
                        onTap: () => _handleMicrophoneTap('B', voiceService),
                        activeColor: Colors
                            .grey[700]!, // Or distinct color for Them? Mock shows Grey vs Blue.
                        // Actually mock shows Left button is Grey pill with mic. Right is Blue pill with mic.
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // English (You / A) - Right
                    Expanded(
                      child: _buildMicButton(
                        label:
                            "${_getLanguageName(voiceService.userALanguage)} (You)",
                        isListening:
                            voiceService.isListening &&
                            voiceService.currentSpeaker == 'A',
                        onTap: () => _handleMicrophoneTap('A', voiceService),
                        activeColor: accentColor,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentCode,
          dropdownColor: const Color(0xFF1F2937),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          isDense: true,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          items: VoiceTranslationService.supportedLanguages.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flag could go here
                  Text(e.value),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMicButton({
    required String label,
    required bool isListening,
    required VoidCallback onTap,
    required Color activeColor,
    required bool isPrimary,
  }) {
    // Mock:
    // Left: Grey Pill, White Text/Icon
    // Right: Blue Pill, White Text/Icon
    final bgColor = isPrimary
        ? (isListening ? Colors.red : const Color(0xFF3B82F6))
        : (isListening ? Colors.red : const Color(0xFF374151));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isListening
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isListening ? Icons.graphic_eq : Icons.mic,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ConversationMessage msg) {
    final isYou = msg.speaker == 'A';
    return Align(
      alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isYou ? const Color(0xFF3B82F6) : const Color(0xFF374151),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isYou ? const Radius.circular(16) : Radius.zero,
            bottomRight: isYou ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isYou
                  ? "You (${msg.speakerLanguage})"
                  : "Them (${msg.speakerLanguage})",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.originalText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(
                color: Colors.white.withValues(alpha: 0.2),
                height: 1,
              ),
            ),

            Text(
              msg.translatedText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTranscriptBubble(VoiceTranslationService service) {
    final isYou = service.currentSpeaker == 'A';
    // If we only have transcript (original) but no translation yet
    final text = service.currentTranscript;
    if (text.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: (isYou ? const Color(0xFF3B82F6) : const Color(0xFF374151))
              .withOpacity(0.7), // Slightly transparent to indicate processing
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Listening...",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (service.isTranslating)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  height: 2,
                  width: 50,
                  child: LinearProgressIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.transparent,
                  ),
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

  void _showHelpDialog(ThemeData theme, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'How to Use Live Conversation',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Select languages for "You" and "Them".',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                '2. Tap the microphone button corresponding to who is speaking.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                '3. The app will transcribe and translate automatically.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(color: Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }
}
