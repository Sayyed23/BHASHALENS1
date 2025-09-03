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
  int _currentIndex = 2; // Voice tab is selected

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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Participant Setup Block - Compact for small screens
          _buildParticipantSetup(isSmallScreen),

          // Conversation Area Block - Optimized proportions
          Expanded(
            flex: isSmallScreen ? 4 : 5,
            child: _buildConversationArea(),
          ),

          // Conversation Timeline Block - Collapsible for small screens
          if (!isSmallScreen)
            Expanded(flex: 3, child: _buildConversationTimeline())
          else
            Expanded(flex: 2, child: _buildCompactTimeline()),

          // Action Controls Block - Compact design
          _buildActionControls(isSmallScreen),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Live Conversation',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showSettingsDialog(),
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showHelpDialog(),
        ),
      ],
    );
  }

  Widget _buildParticipantSetup(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User A Language Selector
          Expanded(
            child: _buildLanguageSelector(
              'User A',
              _voiceService.userALanguage,
              (language) => _voiceService.setUserALanguage(language),
              isSmallScreen,
            ),
          ),

          // Swap Button
          Container(
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
            child: IconButton(
              onPressed: () => _voiceService.swapLanguages(),
              icon: Icon(
                Icons.swap_horiz,
                color: AppColors.primaryOrange,
                size: isSmallScreen ? 24 : 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.grey100,
                shape: const CircleBorder(),
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              ),
            ),
          ),

          // User B Language Selector
          Expanded(
            child: _buildLanguageSelector(
              'User B',
              _voiceService.userBLanguage,
              (language) => _voiceService.setUserBLanguage(language),
              isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    String label,
    String currentLanguage,
    Function(String) onChanged,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.grey50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentLanguage,
              isExpanded: true,
              isDense: isSmallScreen,
              items: VoiceTranslationService.supportedLanguages.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationArea() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // User A Section
          Expanded(
            child: _buildUserSection(
              'A',
              AppColors.primaryOrangeLight.withOpacity(0.1),
              isSmallScreen,
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: AppColors.grey200,
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          ),

          // User B Section
          Expanded(
            child: _buildUserSection(
              'B',
              AppColors.secondaryBlueLight.withOpacity(0.1),
              isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(
    String user,
    Color backgroundColor,
    bool isSmallScreen,
  ) {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Consumer<VoiceTranslationService>(
        builder: (context, voiceService, child) {
          final isCurrentUser = voiceService.currentSpeaker == user;
          final isListening = voiceService.isListening && isCurrentUser;
          final transcript = isCurrentUser
              ? voiceService.currentTranscript
              : '';

          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Label
                Text(
                  'User $user',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 11,
                    fontWeight: FontWeight.w600,
                    color: user == 'A'
                        ? AppColors.primaryOrange
                        : AppColors.secondaryBlue,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),

                // Microphone Button
                GestureDetector(
                  onTap: () => _handleMicrophoneTap(user, voiceService),
                  child: Container(
                    width: isSmallScreen ? 35 : 55,
                    height: isSmallScreen ? 35 : 55,
                    decoration: BoxDecoration(
                      color: isListening
                          ? AppColors.error
                          : (user == 'A'
                                ? AppColors.primaryOrange
                                : AppColors.secondaryBlue),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isListening
                                      ? AppColors.error
                                      : (user == 'A'
                                            ? AppColors.primaryOrange
                                            : AppColors.secondaryBlue))
                                  .withOpacity(0.3),
                          blurRadius: isSmallScreen ? 2 : 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: AppColors.white,
                      size: isSmallScreen ? 14 : 20,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),

                // Transcript
                if (transcript.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppColors.grey300),
                    ),
                    child: Text(
                      transcript,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 7 : 9,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                SizedBox(height: isSmallScreen ? 1 : 2),

                // Status Text
                Text(
                  isListening ? 'Listening...' : 'Tap to speak',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 6 : 8,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTimeline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timeline Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Conversation Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Consumer<VoiceTranslationService>(
                  builder: (context, voiceService, child) {
                    return TextButton.icon(
                      onPressed: () => voiceService.clearConversation(),
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Timeline Messages
          Expanded(
            child: Consumer<VoiceTranslationService>(
              builder: (context, voiceService, child) {
                if (voiceService.conversationHistory.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppColors.grey400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Start a conversation to see the timeline',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: voiceService.conversationHistory.length,
                  itemBuilder: (context, index) {
                    final message = voiceService.conversationHistory[index];
                    return _buildTimelineMessage(message);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimeline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryOrange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Recent Messages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Consumer<VoiceTranslationService>(
                  builder: (context, voiceService, child) {
                    return IconButton(
                      onPressed: () => voiceService.clearConversation(),
                      icon: const Icon(Icons.clear_all, size: 16),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.all(4),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Compact Messages
          Expanded(
            child: Consumer<VoiceTranslationService>(
              builder: (context, voiceService, child) {
                if (voiceService.conversationHistory.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 32,
                          color: AppColors.grey400,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start talking to see messages',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show only last 3 messages in compact mode
                final recentMessages =
                    voiceService.conversationHistory.length > 3
                    ? voiceService.conversationHistory.sublist(
                        voiceService.conversationHistory.length - 3,
                      )
                    : voiceService.conversationHistory;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: recentMessages.length,
                  itemBuilder: (context, index) {
                    final message = recentMessages[index];
                    return _buildCompactTimelineMessage(message);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMessage(ConversationMessage message) {
    final isUserA = message.speaker == 'A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isUserA
                  ? AppColors.primaryOrange
                  : AppColors.secondaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                message.speaker,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
                // Original Text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.originalText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Translated Text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUserA
                        ? AppColors.primaryOrangeLight.withOpacity(0.1)
                        : AppColors.secondaryBlueLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUserA
                          ? AppColors.primaryOrange
                          : AppColors.secondaryBlue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.translatedText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isUserA
                                ? AppColors.primaryOrange
                                : AppColors.secondaryBlue,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _voiceService.speakText(
                          message.translatedText,
                          message.targetLanguage,
                        ),
                        icon: const Icon(Icons.volume_up, size: 16),
                        style: IconButton.styleFrom(
                          foregroundColor: isUserA
                              ? AppColors.primaryOrange
                              : AppColors.secondaryBlue,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ],
                  ),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimelineMessage(ConversationMessage message) {
    final isUserA = message.speaker == 'A';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Avatar
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isUserA
                  ? AppColors.primaryOrange
                  : AppColors.secondaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                message.speaker,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Compact Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original Text (Compact)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    message.originalText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),

                // Translated Text (Compact)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUserA
                        ? AppColors.primaryOrangeLight.withOpacity(0.1)
                        : AppColors.secondaryBlueLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isUserA
                          ? AppColors.primaryOrange
                          : AppColors.secondaryBlue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.translatedText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUserA
                                ? AppColors.primaryOrange
                                : AppColors.secondaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _voiceService.speakText(
                          message.translatedText,
                          message.targetLanguage,
                        ),
                        icon: const Icon(Icons.volume_up, size: 12),
                        style: IconButton.styleFrom(
                          foregroundColor: isUserA
                              ? AppColors.primaryOrange
                              : AppColors.secondaryBlue,
                          padding: const EdgeInsets.all(2),
                          minimumSize: const Size(20, 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isSmallScreen
          ? _buildCompactActionControls()
          : _buildFullActionControls(),
    );
  }

  Widget _buildFullActionControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveConversation,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyTranscript,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryOrange,
              side: const BorderSide(color: AppColors.primaryOrange),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareConversation,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondaryBlue,
              side: const BorderSide(color: AppColors.secondaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveConversation,
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyTranscript,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryOrange,
              side: const BorderSide(color: AppColors.primaryOrange),
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareConversation,
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondaryBlue,
              side: const BorderSide(color: AppColors.secondaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) => _onTabTapped(index),
      selectedItemColor: AppColors.primaryOrange,
      unselectedItemColor: AppColors.grey500,
      backgroundColor: AppColors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Settings'),
        content: Consumer<VoiceTranslationService>(
          builder: (context, voiceService, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Use OpenAI API'),
                  subtitle: Text(
                    voiceService.useOpenAI ? 'OpenAI GPT' : 'Google Gemini',
                  ),
                  value: voiceService.useOpenAI,
                  onChanged: (value) => voiceService.setApiProvider(value),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Speech Recognition'),
                  subtitle: Text(
                    voiceService.speechEnabled ? 'Enabled' : 'Disabled',
                  ),
                  trailing: Icon(
                    voiceService.speechEnabled
                        ? Icons.check_circle
                        : Icons.error,
                    color: voiceService.speechEnabled
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
    setState(() {
      _currentIndex = index;
    });

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
