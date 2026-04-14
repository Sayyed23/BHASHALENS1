import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:bhashalens_app/pages/offline_models_page.dart';
import 'package:bhashalens_app/widgets/accessibility_wrapper.dart';
import 'package:bhashalens_app/theme/app_colors.dart';

class VoiceTranslatePage extends StatefulWidget {
  const VoiceTranslatePage({super.key});

  @override
  State<VoiceTranslatePage> createState() => _VoiceTranslatePageState();
}

class _VoiceTranslatePageState extends State<VoiceTranslatePage> {
  @override
  void initState() {
    super.initState();
    // Pre-check offline readiness for default languages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vs = context.read<VoiceTranslationService>();
      _refreshAllOfflineStatus(vs);
    });
  }

  Future<void> _refreshAllOfflineStatus(VoiceTranslationService vs) async {
    await vs.checkLanguageReadiness(vs.userALanguage);
    await vs.checkLanguageReadiness(vs.userBLanguage);
  }

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
            icon: Icon(Icons.download_rounded, color: colorScheme.onSurface),
            tooltip: 'Offline Models',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OfflineModelsPage(),
              ),
            ),
          ),
          IconButton(
            icon:
                Icon(Icons.help_outline_rounded, color: colorScheme.onSurface),
            onPressed: () => _showHelpDialog(theme),
          ),
        ],
      ),
      body: AccessibilityWrapper(
        currentPage: '/voice',
        child: Consumer<VoiceTranslationService>(
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

              // Offline Mode Banner
              if (voiceService.isOfflineMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.orange.withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline Mode — Using on-device translation',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OfflineModelsPage(),
                          ),
                        ),
                        child: const Text(
                          'Models',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Error Banner
              if (voiceService.errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppColors.error.withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          voiceService.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => voiceService.clearError(),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              // Offline Readiness Info Banner
              if (voiceService.isOfflineMode)
                Builder(builder: (_) {
                  final langA = voiceService.userALanguage;
                  final langB = voiceService.userBLanguage;
                  final statusA = voiceService.offlineStatus[langA];
                  final statusB = voiceService.offlineStatus[langB];
                  final issues = <String>[];

                  if (statusA != null && !statusA.translationModelReady) {
                    issues.add('${_getLanguageName(langA)} translation model');
                  }
                  if (statusB != null && !statusB.translationModelReady) {
                    issues.add('${_getLanguageName(langB)} translation model');
                  }
                  if (statusA != null && !statusA.sttAvailable) {
                    issues.add('${_getLanguageName(langA)} speech recognition');
                  }
                  if (statusB != null && !statusB.sttAvailable) {
                    issues.add('${_getLanguageName(langB)} speech recognition');
                  }
                  if (statusA != null && !statusA.ttsAvailable) {
                    issues.add('${_getLanguageName(langA)} text-to-speech');
                  }
                  if (statusB != null && !statusB.ttsAvailable) {
                    issues.add('${_getLanguageName(langB)} text-to-speech');
                  }

                  if (issues.isEmpty) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.amber.withValues(alpha: 0.15),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Missing: ${issues.join(", ")}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const OfflineModelsPage(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Fix',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

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
            if (val != null) {
              onChanged(val);
              _checkAndPromptOfflineModels(val);
            }
          },
          items: VoiceTranslationService.supportedLanguages.entries.map((e) {
            final vs = context.read<VoiceTranslationService>();
            final status = vs.offlineStatus[e.key];
            Widget? trailing;
            if (status != null) {
              if (status.isFullyReady) {
                trailing = const Icon(Icons.check_circle,
                    size: 14, color: Color(0xFF22C55E));
              } else if (status.translationModelReady) {
                trailing = const Icon(Icons.warning_amber_rounded,
                    size: 14, color: Colors.amber);
              } else {
                trailing = const Icon(Icons.cloud_download_outlined,
                    size: 14, color: Colors.grey);
              }
            }
            return DropdownMenuItem(
              value: e.key,
              child: Row(
                children: [
                  Expanded(child: Text(e.value)),
                  if (trailing != null) ...[const SizedBox(width: 4), trailing],
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

  void _handleMicrophoneTap(
      String user, VoiceTranslationService voiceService) async {
    if (voiceService.isListening) {
      voiceService.stopListening();
      return;
    }

    // When offline, check if translation models are available
    if (voiceService.isOfflineMode) {
      final langA = voiceService.userALanguage;
      final langB = voiceService.userBLanguage;
      final modelsReady = await voiceService.areOfflineModelsReady(langA, langB);
      if (!modelsReady && mounted) {
        _showDownloadModelsDialog(voiceService, langA, langB);
        return;
      }

      // Also warn about STT if not available for the speaker's language
      final speakerLang = user == 'A' ? langA : langB;
      if (!voiceService.isLocaleAvailable(speakerLang) && mounted) {
        final langName = VoiceTranslationService.supportedLanguages[speakerLang] ?? speakerLang;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$langName speech recognition is not installed on your device. '
              'Add it in Settings → System → Languages & input.',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        return;
      }
    }

    voiceService.startListening(user);
  }

  /// Check offline readiness when a language is selected and prompt if needed
  void _checkAndPromptOfflineModels(String languageCode) async {
    final vs = context.read<VoiceTranslationService>();
    final status = await vs.checkLanguageReadiness(languageCode);

    if (!mounted) return;

    if (!status.translationModelReady) {
      final langName = VoiceTranslationService.supportedLanguages[languageCode] ?? languageCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$langName offline model not downloaded. '
            'Download it for offline voice translation.',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Download',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfflineModelsPage(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _showDownloadModelsDialog(
    VoiceTranslationService voiceService,
    String langA,
    String langB,
  ) async {
    final theme = Theme.of(context);
    final missingModels = await voiceService.mlKitService
        .getMissingModelsForTranslation(langA, langB);

    if (!mounted || missingModels.isEmpty) return;

    final missingNames = missingModels
        .map((code) =>
            VoiceTranslationService.supportedLanguages[code] ?? code)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Download Offline Models',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To translate offline, download these language models:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...missingNames.map((name) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Text(
              'Requires internet to download (~30MB each).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfflineModelsPage(),
                ),
              );
            },
            child: Text(
              'Download',
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
