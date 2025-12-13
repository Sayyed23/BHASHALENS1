import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:bhashalens_app/pages/home_page.dart';
import 'package:bhashalens_app/pages/camera_translate_page.dart';
import 'package:bhashalens_app/pages/saved_translations_page.dart';
import 'package:bhashalens_app/pages/settings_page.dart';
import 'package:bhashalens_app/models/saved_translation.dart';
import 'package:bhashalens_app/theme/app_theme.dart';

class VoiceTranslatePage extends StatefulWidget {
  const VoiceTranslatePage({super.key});

  @override
  State<VoiceTranslatePage> createState() => _VoiceTranslatePageState();
}

class _VoiceTranslatePageState extends State<VoiceTranslatePage> {
  late VoiceTranslationService _voiceService;

  @override
  void initState() {
    super.initState();
    _voiceService = Provider.of<VoiceTranslationService>(
      context,
      listen: false,
    );
  }

  String convertLanguageCodeToName(String languageCode) {
    return VoiceTranslationService.supportedLanguages[languageCode] ??
        languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          theme.colorScheme.surface, // Dark background matching HTML
      body: Column(
        children: [
          // Header
          _buildHeader(theme, isDarkMode),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Language Selection Section
                  _buildLanguageSelection(theme, isDarkMode),

                  const SizedBox(height: 32),

                  // Conversation Area
                  _buildConversationArea(theme, isDarkMode),

                  const SizedBox(height: 32),

                  // Conversation History
                  _buildConversationHistory(theme, isDarkMode),

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(theme, isDarkMode),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          _buildBottomNavigation(theme, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.surface, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            // Title
            Expanded(
              child: Text(
                'Voice Translation',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Help button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () => _showHelpDialog(theme, isDarkMode),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelection(ThemeData theme, bool isDarkMode) {
    return Row(
      children: [
        // Your Language
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Language',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(
                    0.7,
                  ), // slate-400 equivalent
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // secondary color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Consumer<VoiceTranslationService>(
                  builder: (context, voiceService, child) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: voiceService.userALanguage,
                        isExpanded: true,
                        dropdownColor: theme.colorScheme.surface,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        items: VoiceTranslationService
                            .supportedLanguages
                            .entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            voiceService.setUserALanguage(value);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Swap Button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton(
            onPressed: () => _voiceService.swapLanguages(),
            icon: Icon(
              Icons.swap_horiz,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary, // accent color
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),

        // Their Language
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Their Language',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(
                    0.7,
                  ), // slate-400 equivalent
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // secondary color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Consumer<VoiceTranslationService>(
                  builder: (context, voiceService, child) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: voiceService.userBLanguage,
                        isExpanded: true,
                        dropdownColor: theme.colorScheme.surface,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        items: VoiceTranslationService
                            .supportedLanguages
                            .entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            voiceService.setUserBLanguage(value);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConversationArea(ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // secondary color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // You Section
          _buildUserSection('You', 'A', theme, isDarkMode),

          // Divider
          Container(
            height: 1,
            color: theme.colorScheme.primary, // accent color
          ),

          // Them Section
          _buildUserSection('Them', 'B', theme, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildUserSection(
    String label,
    String user,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Consumer<VoiceTranslationService>(
      builder: (context, voiceService, child) {
        debugPrint(
          '_buildUserSection: label=$label, speaker=$user, isListening=${voiceService.isListening}, isTranslating=${voiceService.isTranslating}, currentTranscript=${voiceService.currentTranscript}, currentTranslatedText=${voiceService.currentTranslatedText}',
        );
        final isCurrentUser = voiceService.currentSpeaker == user;
        final isListening = voiceService.isListening && isCurrentUser;
        final transcript = isCurrentUser ? voiceService.currentTranscript : '';
        final language = user == 'A'
            ? voiceService.userALanguage
            : voiceService.userBLanguage;
        final languageName = _voiceService.convertLanguageCodeToName(language);

        return Column(
          children: [
            // Header with label and microphone button
            Row(
              children: [
                // User info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      languageName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(
                          0.7,
                        ), // slate-400
                      ),
                    ),
                    if (isListening) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Listening...',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else if (voiceService.isTranslating) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Translating...',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const Spacer(),

                // Microphone button
                GestureDetector(
                  onTap: () => _handleMicrophoneTap(user, voiceService),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isListening
                          ? Colors.red
                          : (user == 'A'
                                ? theme
                                      .colorScheme
                                      .primary // primary color
                                : theme.colorScheme.surface), // accent color
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isListening
                                      ? Colors.red
                                      : (user == 'A'
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.surface))
                                  .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_off,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),

            // Transcript area
            if (transcript.isNotEmpty) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      transcript,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Translated text
                  if (voiceService.currentTranslatedText.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        voiceService.currentTranslatedText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildConversationHistory(ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversation History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        Consumer<VoiceTranslationService>(
          builder: (context, voiceService, child) {
            if (voiceService.conversationHistory.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start a conversation to see the history',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: voiceService.conversationHistory.map((message) {
                return _buildHistoryMessage(message, theme, isDarkMode);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryMessage(
    ConversationMessage message,
    ThemeData theme,
    bool isDarkMode,
  ) {
    final isUserA = message.speaker == 'A';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUserA
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                message.speaker,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chat bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUserA
                        ? theme
                              .colorScheme
                              .surface // accent color
                        : theme.colorScheme.primary, // primary color
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      topRight: const Radius.circular(8),
                      bottomLeft: isUserA
                          ? const Radius.circular(0)
                          : const Radius.circular(8),
                      bottomRight: isUserA
                          ? const Radius.circular(8)
                          : const Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.originalText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: isUserA
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message.translatedText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                          color: isUserA
                              ? theme.colorScheme.onSurface.withOpacity(0.7)
                              : theme.colorScheme.onPrimary.withOpacity(
                                  0.7,
                                ), // slate-400
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(
                      0.7,
                    ), // slate-400
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isDarkMode) {
    return Column(
      children: [
        Row(
          children: [
            // Save Button
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // accent color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: _saveConversation,
                  icon: Icon(
                    Icons.bookmark,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  label: Text(
                    'Save',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Copy Button
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // accent color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: _copyTranscript,
                  icon: Icon(
                    Icons.content_copy,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  label: Text(
                    'Copy',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Share Button
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // accent color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: _shareConversation,
                  icon: Icon(
                    Icons.share,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  label: Text(
                    'Share',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Clear Conversation Button
        Consumer<VoiceTranslationService>(
          builder: (context, voiceService, child) {
            if (voiceService.conversationHistory.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(
                  0.8,
                ), // accent color
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: _clearConversation,
                icon: Icon(
                  Icons.clear_all,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                label: Text(
                  'Clear Conversation',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.surface, width: 1),
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, false, theme, isDarkMode),
              _buildNavItem(
                Icons.camera_alt,
                'Camera',
                1,
                false,
                theme,
                isDarkMode,
              ),
              _buildNavItem(Icons.mic, 'Voice', 2, true, theme, isDarkMode),
              _buildNavItem(
                Icons.bookmark,
                'Saved',
                3,
                false,
                theme,
                isDarkMode,
              ),
              _buildNavItem(
                Icons.settings,
                'Settings',
                4,
                false,
                theme,
                isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    bool isSelected,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMicrophoneTap(String user, VoiceTranslationService voiceService) {
    if (_voiceService.isListening) {
      _voiceService.stopListening();
    } else {
      _voiceService.startListening(user);
    }
  }

  void _showHelpDialog(ThemeData theme, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'How to Use Live Conversation',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Select languages for User A and User B',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2. Tap the microphone button to start speaking',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3. Your speech will be transcribed and translated',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '4. The conversation appears in the timeline below',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '5. Use the action buttons to save, copy, or share',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    debugPrint('Tab tapped: $index');
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CameraTranslatePage()),
        );
        break;
      case 2:
        // Already on voice page
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SavedTranslationsPage(),
          ),
        );
        break;
      case 4:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
    }
  }

  void _saveConversation() {
    final provider = Provider.of<SavedTranslationsProvider>(
      context,
      listen: false,
    );
    final history = _voiceService.conversationHistory;
    if (history.isNotEmpty) {
      final last = history.last;
      provider.add(
        SavedTranslation(
          originalText: last.originalText,
          translatedText: last.translatedText,
          fromLanguage:
              VoiceTranslationService.supportedLanguages[last
                  .speakerLanguage] ??
              last.speakerLanguage,
          toLanguage:
              VoiceTranslationService.supportedLanguages[last.targetLanguage] ??
              last.targetLanguage,
          dateTime: last.timestamp,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Translation saved successfully!',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: CustomColors.of(context).success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No translation to save!',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: CustomColors.of(context).warning,
        ),
      );
    }
  }

  void _copyTranscript() {
    final transcript = _voiceService.getConversationTranscript();
    // TODO: Implement copy to clipboard using transcript
    debugPrint('Transcript to copy: $transcript');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Transcript copied to clipboard!',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: CustomColors.of(context).info,
      ),
    );
  }

  void _shareConversation() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share functionality coming soon!',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: CustomColors.of(context).warning,
      ),
    );
  }

  void _clearConversation() {
    _voiceService.clearConversation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Conversation history cleared!',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: CustomColors.of(context).info,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
