import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/offline_explain_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:bhashalens_app/theme/app_colors.dart';
import 'package:bhashalens_app/widgets/main_bottom_navbar.dart';

class ExplainModePage extends StatefulWidget {
  final String? initialText;
  const ExplainModePage({super.key, this.initialText});

  @override
  State<ExplainModePage> createState() => _ExplainModePageState();
}

class _ExplainModePageState extends State<ExplainModePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _explanationData;
  bool _isProcessing = false;
  String _selectedInputLanguage = 'Auto-detect';
  String _selectedOutputLanguage = 'Hindi';
  late TabController _tabController;

  final List<String> _tabs = ['Camera', 'Voice', 'Text'];

  // Theme Colors from AppColors
  static const bgDark = AppColors.backgroundDark;
  static const cardDark = AppColors.surfaceDark;
  static const primaryBlue = AppColors.primary;
  static const textGrey = AppColors.textMuted;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: 2);
    _tabController.addListener(() => setState(() {}));

    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _inputController.text = widget.initialText!;
      Future.delayed(Duration.zero, _explainWithContext);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _explainWithContext() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _explanationData = null;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final offlineService = Provider.of<OfflineExplainService>(context, listen: false);

      final Map<String, dynamic> result;
      if (isOffline) {
        result = await offlineService.explainAsMap(
          text,
          targetLanguage: _selectedOutputLanguage,
        );
      } else {
        result = await geminiService.explainAndSimplifyWithContext(
          text,
          simplicity: 'Detailed and Clear',
          targetLanguage: _selectedOutputLanguage,
          sourceLanguage: _selectedInputLanguage,
        );
      }

      if (mounted) {
        setState(() {
          _explanationData = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _scanText() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null || !mounted) return;

    final geminiService = Provider.of<GeminiService>(context, listen: false);
    setState(() => _isProcessing = true);

    try {
      final bytes = await image.readAsBytes();
      final extractedText = await geminiService.extractTextFromImage(bytes);

      if (mounted) {
        if (extractedText.isNotEmpty && extractedText != 'No text detected') {
          setState(() {
            _inputController.text = extractedText;
            _isProcessing = false;
            _tabController.index = 2; // Switch to Text tab
          });
          _explainWithContext();
        } else {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not extract text")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OCR Error: $e")),
        );
      }
    }
  }

  Future<void> _handleVoiceInput() async {
    final voiceService = Provider.of<VoiceTranslationService>(context, listen: false);
    
    if (voiceService.isListening) {
      await voiceService.stopListening();
    } else {
      await voiceService.listenOnce((text) {
        if (text.isNotEmpty && mounted) {
          setState(() {
            _inputController.text = text;
            _tabController.index = 2; // Switch to Text tab
          });
          _explainWithContext();
        }
      }, localeId: _selectedInputLanguage == 'Auto-detect' ? 'en-US' : _getLocaleId(_selectedInputLanguage));
    }
  }

  String _getLocaleId(String languageName) {
    switch (languageName) {
      case 'English': return 'en-US';
      case 'Hindi': return 'hi-IN';
      case 'Marathi': return 'mr-IN';
      case 'Tamil': return 'ta-IN';
      case 'Telugu': return 'te-IN';
      case 'Bengali': return 'bn-IN';
      default: return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Explain & Simplify",
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
      body: Column(
        children: [
          // Top Language Selector Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "DETECTED LANGUAGE",
                            style: TextStyle(color: textGrey, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: _selectedInputLanguage,
                            dropdownColor: cardDark,
                            underline: Container(),
                            icon: const Icon(Icons.keyboard_arrow_down, color: textGrey),
                            style: const TextStyle(color: primaryBlue, fontSize: 16, fontWeight: FontWeight.bold),
                            items: ['Auto-detect', 'English', 'Hindi', 'Marathi', 'Tamil', 'Telugu', 'Bengali']
                                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedInputLanguage = val!),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: textGrey.withValues(alpha: 0.3), size: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "EXPLAIN IN",
                            style: TextStyle(color: textGrey, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: _selectedOutputLanguage,
                            dropdownColor: cardDark,
                            underline: Container(),
                            icon: const Icon(Icons.keyboard_arrow_down, color: textGrey),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            items: ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu', 'Bengali']
                                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedOutputLanguage = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Read Explanation Aloud",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Switch(
                      value: true,
                      onChanged: (val) {},
                      activeThumbColor: primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: textGrey,
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 16), SizedBox(width: 4), Text("Camera")])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mic, size: 16), SizedBox(width: 4), Text("Voice")])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.text_fields, size: 16), SizedBox(width: 4), Text("Text")])),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (_explanationData == null) ...[
                    // Input Area
                    if (_tabController.index == 0)
                      _buildCameraPlaceholder()
                    else if (_tabController.index == 1)
                      _buildVoicePlaceholder()
                    else
                      _buildTextInputArea(),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _explainWithContext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _isProcessing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                        label: Text(_isProcessing ? "Analyzing..." : "Explain Simply"),
                      ),
                    ),
                  ] else ...[
                    // Result View
                    _buildResultView(),
                    const SizedBox(height: 24),
                    _buildActionFooter(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner, size: 64, color: primaryBlue.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text("Place document within frame", style: TextStyle(color: textGrey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _scanText,
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue.withValues(alpha: 0.1), foregroundColor: primaryBlue),
            child: const Text("Scan Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePlaceholder() {
    return Consumer<VoiceTranslationService>(
      builder: (context, voiceService, child) {
        return Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: voiceService.isListening ? primaryBlue : Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _handleVoiceInput,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: voiceService.isListening ? primaryBlue : primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    voiceService.isListening ? Icons.stop : Icons.mic,
                    size: 32,
                    color: voiceService.isListening ? Colors.white : primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Tap to start speaking",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Ask about a complex term or concept", style: TextStyle(color: textGrey, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _inputController,
        maxLines: 8,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Type or paste complex text here...",
          hintStyle: TextStyle(color: textGrey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original Text Snippet
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote, color: textGrey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _inputController.text,
                  style: const TextStyle(color: textGrey, fontSize: 13, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Primary Simplified Result
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb, color: primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Simple Explanation",
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _explanationData!['simplified_text'] ?? '',
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.replay_10, color: primaryBlue), onPressed: () {}),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  IconButton(icon: const Icon(Icons.forward_10, color: primaryBlue), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Secondary Explanation
        if (_explanationData!['explanation'] != null)
          _buildInfoSection("Insight", _explanationData!['explanation'], Icons.info_outline),
        
        const SizedBox(height: 16),
        
        // Key Points
        if (_explanationData!['key_points'] != null && (_explanationData!['key_points'] as List).isNotEmpty)
          _buildKeyPointsSection(_explanationData!['key_points']),

        const SizedBox(height: 24),
        
        // Chat Input stub
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Ask something like: What should I do?",
                  style: TextStyle(color: textGrey, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textGrey, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildKeyPointsSection(List<dynamic> points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Key Takeaways", style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...points.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, color: primaryBlue, size: 16),
                const SizedBox(width: 12),
                Expanded(child: Text(p.toString(), style: const TextStyle(color: Colors.white70, fontSize: 14))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFooterAction(Icons.bookmark_border, "Save"),
        _buildFooterAction(Icons.share_outlined, "Share"),
        _buildFooterAction(Icons.translate, "Translate"),
        _buildFooterAction(Icons.refresh, "Reset", onTap: () {
          setState(() {
            _explanationData = null;
            _inputController.clear();
          });
        }),
      ],
    );
  }

  Widget _buildFooterAction(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
