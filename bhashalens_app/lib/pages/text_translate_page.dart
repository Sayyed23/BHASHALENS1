import 'package:bhashalens_app/services/voice_translation_service.dart'; // Reuse for translation logic
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
  String _sourceLanguage = 'auto';
  String _targetLanguage = 'English';
  String _translatedText = '';
  bool _isTranslating = false;

  final List<String> _languages = [
    'Auto-detected',
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Japanese',
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF101822);
    const Color cardDark = Color(0xFF1C2027);
    const Color primaryBlue = Color(0xFF136DEC);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Text Translate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Language Selector Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLanguageDropdown("FROM", _sourceLanguage, (val) {
                    if (val != null) setState(() => _sourceLanguage = val);
                  }),
                  GestureDetector(
                    onTap: () {
                      if (_sourceLanguage == 'Auto-detected' ||
                          _sourceLanguage == 'auto') {
                        return;
                      }
                      setState(() {
                        final temp = _sourceLanguage;
                        _sourceLanguage = _targetLanguage;
                        _targetLanguage = temp;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF334155),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  _buildLanguageDropdown("TO", _targetLanguage, (val) {
                    if (val != null) setState(() => _targetLanguage = val);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input Area
            Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Enter text to translate...",
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_translatedText.isNotEmpty) ...[
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _translatedText,
                          style: const TextStyle(
                            color: primaryBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildIconButton(Icons.content_paste, () async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (data?.text != null) {
                          _textController.text = data!.text!;
                        }
                      }),
                      const SizedBox(width: 12),
                      _buildIconButton(Icons.mic, () {
                        // Voice Input logic placeholder
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Translate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _translateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9), // Cyan/Blue
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                ),
                child: _isTranslating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.translate, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Translate Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "RECENT",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Clear All",
                    style: TextStyle(color: primaryBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentCard(
              "Where is the nearest library?",
              "¿Dónde está la biblioteca más cercana?",
            ),
            const SizedBox(height: 12),
            _buildRecentCard(
              "I would like to order a coffee.",
              "Quisiera pedir un café.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(
    String label,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButton<String>(
          value: _languages.contains(value) ? value : _languages.first,
          dropdownColor: const Color(0xFF1C2027),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          underline: Container(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: _languages.map((String lang) {
            return DropdownMenuItem<String>(value: lang, child: Text(lang));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildRecentCard(String original, String translated) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2027),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  original,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translated,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.history, color: Colors.white24),
        ],
      ),
    );
  }

  Future<void> _translateText() async {
    if (_textController.text.isEmpty) return;
    setState(() => _isTranslating = true);

    try {
      final service = Provider.of<VoiceTranslationService>(
        context,
        listen: false,
      ); // Reusing Service
      final targetCode = _getLanguageCode(_targetLanguage);
      // Assuming 'auto' handling in service or default 'en'
      final translation = await service.translateText(
        _textController.text,
        targetCode,
        fromLanguage: _sourceLanguage == 'Auto-detected'
            ? 'auto'
            : _getLanguageCode(_sourceLanguage),
      );

      if (mounted) {
        setState(() => _translatedText = translation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  String _getLanguageCode(String lang) {
    switch (lang) {
      case 'English':
        return 'en';
      case 'Hindi':
        return 'hi';
      case 'Spanish':
        return 'es';
      case 'French':
        return 'fr';
      case 'German':
        return 'de';
      case 'Japanese':
        return 'ja';
      default:
        return 'en';
    }
  }
}
