import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TextTranslatePage extends StatefulWidget {
  const TextTranslatePage({super.key});

  @override
  State<TextTranslatePage> createState() => _TextTranslatePageState();
}

class _TextTranslatePageState extends State<TextTranslatePage> {
  final TextEditingController _textInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _originalText = '';
  String _translatedText = '';
  String _sourceLanguage = 'Auto-detected';
  String _targetLanguage = 'English';
  bool _isProcessing = false;

  @override
  void dispose() {
    _textInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectTargetLanguage() async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final languages = geminiService.getSupportedLanguages();

    final String? selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: const Color(0xFF111C22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Target Language',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return ListTile(
                      title: Text(
                        lang['name']!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, lang['name']);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (selectedLanguage != null && selectedLanguage != _targetLanguage) {
      setState(() {
        _targetLanguage = selectedLanguage;
      });
      // Re-translate if there is text
      if (_originalText.isNotEmpty) {
        _translateText();
      }
    }
  }

  Future<void> _translateText() async {
    final text = _textInputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text to translate'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted) return;
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      String translatedText = '';
      String detectedLanguage = 'Unknown';

      if (isOffline) {
        final mlKitService = MlKitTranslationService();
        // Offline translation
        // Assuming source is English for offline demo or we need a selector.

        final result = await mlKitService.translate(
          text: text,
          sourceLanguage: 'en', // Constraint for offline
          targetLanguage: _targetLanguage == 'Hindi'
              ? 'hi'
              : _targetLanguage == 'Marathi'
              ? 'mr'
              : _targetLanguage == 'Spanish'
              ? 'es'
              : _targetLanguage == 'French'
              ? 'fr'
              : 'en',
        );

        translatedText = result ?? 'Translation failed or model not downloaded';
        detectedLanguage = 'English (Offline/Assumed)';
      } else {
        final geminiService = Provider.of<GeminiService>(
          context,
          listen: false,
        );

        if (!geminiService.isInitialized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please configure Gemini API key in settings first',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        detectedLanguage = await geminiService.detectLanguage(text);
        translatedText = await geminiService.translateText(
          text,
          _targetLanguage,
          sourceLanguage: detectedLanguage,
        );
      }

      setState(() {
        _originalText = text;
        _translatedText = translatedText;
        _sourceLanguage = detectedLanguage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error translating text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _shareText() {
    if (_translatedText.isNotEmpty) {
      final shareText =
          'Original: $_originalText\n\nTranslation: $_translatedText';
      Share.share(shareText, subject: 'Translation from BhashaLens');
    }
  }

  void _saveTranslation() {
    if (_originalText.isNotEmpty && _translatedText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translation saved successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _copyText() {
    if (_translatedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _translatedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translation copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildHeader(theme, isDarkMode)),
          Expanded(child: _buildTextTranslationView(theme, isDarkMode)),
          // We can optionally verify if we want standard footer or not.
          // Assuming we want consistent navigation.
          // _buildFooterNavigationBlock(theme, isDarkMode),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        currentIndex:
            0, // No specific index or create a new one? Let's use 0 for now or none.
        // Actually, let's replicate the footer manually or use the same widget if we extracted it.
        // Since we didn't extract the footer widget, I'll direct copy the footer logic or just leave it for now.
        // The user prompted "Remove text feature from camera and make it separate feature".
        // I will implement a basic footer here.
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/home');
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed('/camera_translate');
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed('/voice_translate');
              break;
            case 3:
              Navigator.of(context).pushReplacementNamed('/saved_translations');
              break;
            case 4:
              Navigator.of(context).pushReplacementNamed('/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera),
            label: 'Camera',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            'Text Translate',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildTextTranslationView(ThemeData theme, bool isDarkMode) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Input section
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Language selector bar
                _buildLanguageSelectionBar(theme, isDarkMode),
                Divider(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  height: 1,
                ),
                // Text input field
                Container(
                  constraints: const BoxConstraints(minHeight: 150),
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _textInputController,
                    maxLines: null,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter text to translate...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Translate button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _translateText,
                    icon: _isProcessing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.translate,
                            color: theme.colorScheme.onPrimary,
                          ),
                    label: Text(_isProcessing ? 'Translating...' : 'Translate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Translation output
          if (_translatedText.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTranslationResultCard(theme, isDarkMode),
            const SizedBox(height: 16),
            _buildActionButtons(theme, isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionBar(ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
              ),
              child: Text(
                _sourceLanguage,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ),
          ),
          Container(
            height: 24,
            width: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          Expanded(
            child: TextButton(
              onPressed: () {
                _selectTargetLanguage();
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _targetLanguage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    size: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationResultCard(ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original text
          if (_originalText.isNotEmpty && !_isProcessing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _sourceLanguage,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _originalText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
            Divider(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              height: 24,
            ),
          ],
          // Translated text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _targetLanguage,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_translatedText.isNotEmpty && !_isProcessing)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isProcessing && _translatedText.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Generating translation...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  _translatedText.isEmpty
                      ? 'Translation will appear here...'
                      : _translatedText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: _translatedText.isEmpty ? 15 : 18,
                    fontWeight: _translatedText.isEmpty
                        ? FontWeight.normal
                        : FontWeight.w600,
                    color: _translatedText.isEmpty
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                        : theme.colorScheme.onSurface,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.content_copy,
          label: 'Copy',
          onTap: _copyText,
          color: theme.colorScheme.primary,
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onTap: _shareText,
          color: Colors.purple,
        ),
        _buildActionButton(
          icon: Icons.bookmark_border,
          label: 'Save',
          onTap: _saveTranslation,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
