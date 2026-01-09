import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';

class ExplainModePage extends StatefulWidget {
  const ExplainModePage({super.key});

  @override
  State<ExplainModePage> createState() => _ExplainModePageState();
}

class _ExplainModePageState extends State<ExplainModePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _simplifiedText = '';
  bool _isProcessing = false;
  String _selectedSimplicity = 'Very Simple';
  String _selectedOutputLanguage = 'Hindi'; // Default from mockup
  late TabController _tabController;

  // Mockup shows: Scan, Paste, Speak
  final List<String> _tabs = ['Scan', 'Paste', 'Speak'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Listen to voice service for real-time transcription
    final voiceService = Provider.of<VoiceTranslationService>(
      context,
      listen: false,
    );
    voiceService.addListener(_onVoiceUpdate);
  }

  void _handleTabSelection() {
    if (_tabController.index == 2) {
      // Speak tab selected
      // Maybe auto-start listening? keeping manual for now based on typical UX
    } else {
      // Stop listening if moved away from Speak tab
      final voiceService = Provider.of<VoiceTranslationService>(
        context,
        listen: false,
      );
      if (voiceService.isListening) {
        voiceService.stopListening();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    final voiceService = Provider.of<VoiceTranslationService>(
      context,
      listen: false,
    );
    voiceService.removeListener(_onVoiceUpdate);
    super.dispose();
  }

  void _onVoiceUpdate() {
    final voiceService = Provider.of<VoiceTranslationService>(
      context,
      listen: false,
    );
    // Only update if on Speak tab
    if (_tabController.index == 2 &&
        voiceService.isListening &&
        voiceService.currentTranscript.isNotEmpty &&
        voiceService.currentSpeaker == 'user') {
      setState(() {
        _inputController.text = voiceService.currentTranscript;
      });
    }
  }

  Future<void> _scanText() async {
    // Launch camera to scan text
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        if (!mounted) return;
        setState(() => _isProcessing = true);

        final geminiService = Provider.of<GeminiService>(
          context,
          listen: false,
        );
        final bytes = await image.readAsBytes();

        if (!mounted) return;
        final extracted = await geminiService.extractTextFromImage(bytes);

        if (!mounted) return;
        setState(() {
          _inputController.text = extracted;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Error scanning: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to scan text: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _inputController.text = data!.text!;
      });
    }
  }

  Future<void> _toggleListening() async {
    final voiceService = Provider.of<VoiceTranslationService>(
      context,
      listen: false,
    );
    if (voiceService.isListening) {
      await voiceService.stopListening();
    } else {
      await voiceService.startListening('user');
    }
  }

  Future<void> _simplify() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or scan some text first.')),
      );
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You are offline. AI features require an internet connection.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _simplifiedText = '';
      // Switch input to result view if needed, or just show result below
    });
    FocusScope.of(context).unfocus();

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final result = await geminiService.explainAndSimplify(
        text,
        simplicity: _selectedSimplicity,
        targetLanguage: _selectedOutputLanguage,
      );

      if (mounted) {
        setState(() {
          _simplifiedText = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to explain: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        if (index == 0) _scanText();
        if (index == 1) _pasteText(); // Optional: Auto paste when tab selected?
        // Or keep it manual button in the tab view.
        if (index == 2) {
          // Maybe auto start listening
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3)
              : Colors.transparent, // Blue for selected
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(String title, String value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C), // Dark card bg
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    title == 'Simplicity' ? Icons.tune : Icons.translate,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSimplicityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: ['Very Simple', 'Simple', 'Moderate', 'Detailed']
            .map(
              (e) => ListTile(
                title: Text(e),
                onTap: () {
                  setState(() => _selectedSimplicity = e);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showLanguagePicker() {
    final languages = [
      'English',
      'Hindi',
      'Marathi',
      'Bengali',
      'Tamil',
      'Telugu',
      'Spanish',
      'French',
    ];
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: languages
            .map(
              (e) => ListTile(
                title: Text(e),
                onTap: () {
                  setState(() => _selectedOutputLanguage = e);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = Provider.of<VoiceTranslationService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark BG like mockup
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF006D77,
        ), // Teal/Greenish header from mockup
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Explain & Simplify',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Scan or paste something you don\'t understand',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Custom Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Darker tab bg
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTabButton('Scan', Icons.camera_alt_outlined, 0),
                    _buildTabButton('Paste', Icons.content_paste, 1),
                    _buildTabButton('Speak', Icons.mic_none, 2),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Input Area
              Container(
                constraints: const BoxConstraints(minHeight: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Card color
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      maxLines: 6,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText:
                            'Paste notice, bill, message, or instructions here...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                    if (_tabController.index ==
                        1) // Show Paste button inside only if Paste tab? or always?
                      // Mockup shows a floating-ish "Paste" button inside the text area
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          onPressed: _pasteText,
                          icon: const Icon(Icons.content_paste, size: 16),
                          label: const Text('Paste'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E2C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (_tabController.index == 2 && voiceService.isListening)
                      const Text(
                        "Listening...",
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Explain Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _buildSettingsCard(
                    'Simplicity',
                    _selectedSimplicity,
                    _showSimplicityPicker,
                  ),
                  const SizedBox(width: 12),
                  _buildSettingsCard(
                    'Output',
                    _selectedOutputLanguage,
                    _showLanguagePicker,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Main Action Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _simplify,
                  icon: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isProcessing
                        ? 'Simplifying...'
                        : 'Explain in Simple Words',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF2196F3,
                    ), // Blue like mockup
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor: Colors.blue.withValues(alpha: 0.4),
                  ),
                ),
              ),

              if (_simplifiedText.isNotEmpty) ...[
                const SizedBox(height: 30),
                Text(
                  'Simplified Explanation:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _simplifiedText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up_rounded,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              // Speak simplified text
                              voiceService.speakText(
                                _simplifiedText,
                                'en',
                              ); // Language?
                            },
                            tooltip: 'Listen',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _simplifiedText),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Copied!")),
                              );
                            },
                            tooltip: 'Copy',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
