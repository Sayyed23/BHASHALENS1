import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class TextTranslatePage extends StatefulWidget {
  const TextTranslatePage({super.key});

  @override
  State<TextTranslatePage> createState() => _TextTranslatePageState();
}

class _TextTranslatePageState extends State<TextTranslatePage> {
  final TextEditingController _textController = TextEditingController();
  String _sourceLanguageCode = 'auto'; // 'auto' means Auto-detected
  String _targetLanguageCode = 'en';
  String _translatedText = '';
  bool _isTranslating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Text Translation',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Language Selector Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLanguagePicker(
                      label: "FROM",
                      currentCode: _sourceLanguageCode,
                      isSource: true,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sourceLanguageCode = val);
                        }
                      },
                      theme: theme,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _swapLanguages,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildLanguagePicker(
                      label: "TO",
                      currentCode: _targetLanguageCode,
                      isSource: false,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _targetLanguageCode = val);
                        }
                      },
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input Area
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Text Input
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 120),
                      child: TextField(
                        controller: _textController,
                        style: theme.textTheme.bodyLarge,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "Enter text to translate...",
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),

                  if (_translatedText.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                          color: colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TRANSLATION",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              GestureDetector(
                                onTap: _copyTranslation,
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 18,
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _translatedText,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Actions Row
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionIcon(
                          icon: Icons.content_paste_rounded,
                          onTap: _pasteFromClipboard,
                          theme: theme,
                        ),
                        const SizedBox(width: 12),
                        _buildActionIcon(
                          icon: Icons.close_rounded,
                          onTap: () => setState(() {
                            _textController.clear();
                            _translatedText = '';
                          }),
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Translate Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isTranslating ? null : _translateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                ),
                child: _isTranslating
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.translate_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            "Translate Now",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),

            // Recent Section
            if (true) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "RECENT HISTORY",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Clear All",
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentCard(
                original: "How are you doing today?",
                translated: "आज आप कैसे हैं?",
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildRecentCard(
                original: "Where is the nearest supermarket?",
                translated: "निकटतम सुपरमार्केट कहाँ है?",
                theme: theme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker({
    required String label,
    required String currentCode,
    required bool isSource,
    required Function(String?) onChanged,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    final Map<String, String> languages = isSource
        ? {'auto': 'Auto-detect', ...VoiceTranslationService.supportedLanguages}
        : VoiceTranslationService.supportedLanguages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: languages.containsKey(currentCode)
                ? currentCode
                : languages.keys.first,
            dropdownColor: colorScheme.surface,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: colorScheme.primary, size: 18),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            isExpanded: true,
            onChanged: onChanged,
            items: languages.entries.map((e) {
              return DropdownMenuItem<String>(
                value: e.key,
                child: Text(e.value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.primary, size: 18),
      ),
    );
  }

  Widget _buildRecentCard({
    required String original,
    required String translated,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  original,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  translated,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.history_rounded,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  void _swapLanguages() {
    if (_sourceLanguageCode == 'auto') return;
    setState(() {
      final temp = _sourceLanguageCode;
      _sourceLanguageCode = _targetLanguageCode;
      _targetLanguageCode = temp;
      _translatedText = '';
    });
  }

  void _copyTranslation() {
    if (_translatedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _textController.text = data!.text!;
      });
    }
  }

  Future<void> _translateText() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isTranslating = true);

    try {
      final service =
          Provider.of<VoiceTranslationService>(context, listen: false);

      final translation = await service.translateText(
        _textController.text,
        _targetLanguageCode,
        fromLanguage: _sourceLanguageCode,
      );

      if (mounted) {
        setState(() => _translatedText = translation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }
}
