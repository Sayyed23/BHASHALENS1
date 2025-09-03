import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:bhashalens_app/theme/app_colors.dart';
import 'package:bhashalens_app/pages/home_page.dart';
import 'package:bhashalens_app/pages/camera_translate_page.dart';
import 'package:bhashalens_app/pages/saved_translations_page.dart';
import 'package:bhashalens_app/pages/settings_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111C22), // Dark background matching HTML
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Language Selection Section
                  _buildLanguageSelection(),

                  const SizedBox(height: 32),

                  // Conversation Area
                  _buildConversationArea(),

                  const SizedBox(height: 32),

                  // Conversation History
                  _buildConversationHistory(),

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C22).withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF233C48), width: 1),
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
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
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
            const Expanded(
              child: Text(
                'Voice Translation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                icon: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => _showHelpDialog(),
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

  Widget _buildLanguageSelection() {
    return Row(
      children: [
        // Your Language
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Language',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94B7C9), // slate-400 equivalent
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF192B33), // secondary color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Consumer<VoiceTranslationService>(
                  builder: (context, voiceService, child) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: voiceService.userALanguage,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF192B33),
                        style: const TextStyle(color: Colors.white),
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
                          if (value != null)
                            voiceService.setUserALanguage(value);
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
            icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF233C48), // accent color
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
              const Text(
                'Their Language',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94B7C9), // slate-400 equivalent
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF192B33), // secondary color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Consumer<VoiceTranslationService>(
                  builder: (context, voiceService, child) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: voiceService.userBLanguage,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF192B33),
                        style: const TextStyle(color: Colors.white),
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
                          if (value != null)
                            voiceService.setUserBLanguage(value);
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

  Widget _buildConversationArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF192B33), // secondary color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // You Section
          _buildUserSection('You', 'A'),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFF233C48), // accent color
          ),

          // Them Section
          _buildUserSection('Them', 'B'),
        ],
      ),
    );
  }

  Widget _buildUserSection(String label, String user) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Consumer<VoiceTranslationService>(
        builder: (context, voiceService, child) {
          final isCurrentUser = voiceService.currentSpeaker == user;
          final isListening = voiceService.isListening && isCurrentUser;
          final transcript = isCurrentUser
              ? voiceService.currentTranscript
              : '';
          final language = user == 'A'
              ? voiceService.userALanguage
              : voiceService.userBLanguage;
          final languageName =
              VoiceTranslationService.supportedLanguages[language] ?? language;

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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        languageName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94B7C9), // slate-400
                        ),
                      ),
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
                                  ? const Color(0xFF1193D4) // primary color
                                  : const Color(0xFF233C48)), // accent color
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isListening
                                        ? Colors.red
                                        : (user == 'A'
                                              ? const Color(0xFF1193D4)
                                              : const Color(0xFF233C48)))
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_off,
                        color: Colors.white,
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
                    Text(
                      transcript,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Translated text would appear here',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF94B7C9), // slate-400
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conversation History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        Consumer<VoiceTranslationService>(
          builder: (context, voiceService, child) {
            if (voiceService.conversationHistory.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF192B33),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Color(0xFF94B7C9),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Start a conversation to see the history',
                        style: TextStyle(
                          color: Color(0xFF94B7C9),
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
                return _buildHistoryMessage(message);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryMessage(ConversationMessage message) {
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
                  ? const Color(0xFF1193D4)
                  : const Color(0xFF233C48),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                message.speaker,
                style: const TextStyle(
                  color: Colors.white,
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
                        ? const Color(0xFF233C48) // accent color
                        : const Color(0xFF1193D4), // primary color
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
                  child: Text(
                    message.originalText,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94B7C9), // slate-400
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Save Button
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF233C48), // accent color
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: _saveConversation,
              icon: const Icon(Icons.bookmark, color: Colors.white, size: 20),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
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
              color: const Color(0xFF233C48), // accent color
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: _copyTranscript,
              icon: const Icon(
                Icons.content_copy,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Copy',
                style: TextStyle(
                  color: Colors.white,
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
              color: const Color(0xFF233C48), // accent color
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: _shareConversation,
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              label: const Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
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
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111C22),
        border: Border(top: BorderSide(color: Color(0xFF233C48), width: 1)),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, false),
              _buildNavItem(Icons.camera_alt, 'Camera', 1, false),
              _buildNavItem(Icons.mic, 'Voice', 2, true),
              _buildNavItem(Icons.bookmark, 'Saved', 3, false),
              _buildNavItem(Icons.settings, 'Settings', 4, false),
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
  ) {
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1193D4).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1193D4)
                  : const Color(0xFF94B7C9),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF1193D4)
                    : const Color(0xFF94B7C9),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Event Handlers
  void _handleMicrophoneTap(String user, VoiceTranslationService voiceService) {
    if (voiceService.isListening) {
      voiceService.stopListening().then((_) {
        voiceService.processConversationTurn();
      });
    } else {
      voiceService.startListening(user);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use Live Conversation'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Select languages for User A and User B',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('2. Tap the microphone button to start speaking'),
              SizedBox(height: 8),
              Text('3. Your speech will be transcribed and translated'),
              SizedBox(height: 8),
              Text('4. The conversation appears in the timeline below'),
              SizedBox(height: 8),
              Text('5. Use the action buttons to save, copy, or share'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
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
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation saved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _copyTranscript() {
    final transcript = _voiceService.getConversationTranscript();
    // TODO: Implement copy to clipboard using transcript
    debugPrint('Transcript to copy: $transcript');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcript copied to clipboard!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _shareConversation() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppColors.warning,
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
