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

  Map<String, dynamic>? _contextData;
  bool _isProcessing = false;
  String _selectedOutputLanguage = 'Hindi';
  late TabController _tabController;

  final List<String> _tabs = ['Camera', 'Voice'];

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
    if (_tabController.index == 1) {
      // Voice tab selected
    } else {
      // Stop listening if moved away from Voice tab
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
    // Only update if on Voice tab
    if (_tabController.index == 1) {
      // Logic for chat updates is handled by VoiceTranslationService adding to history
      // We just need to trigger context analysis when a new message is added
      // Or we can react to transcripts.

      // Let's rely on transcript finalizing.
      // Actually, VoiceTranslationService.processConversationTurn() adds to history.
      // We can iterate over history and find the last one.

      if (voiceService.conversationHistory.isNotEmpty) {
        final lastMsg = voiceService.conversationHistory.last;
        // If we haven't analyzed this message yet, do it.
        // Store lastAnalyzedId to avoid re-analysis
        if (lastMsg.id != _lastAnalyzedMsgId && !voiceService.isListening) {
          _lastAnalyzedMsgId = lastMsg.id;
          _inputController.text =
              lastMsg.originalText; // Ensure text logic works
          _explainWithContext();
        }
      }

      setState(() {}); // Rebuild UI for transcript updates
    }
  }

  String? _lastAnalyzedMsgId;

  Future<void> _scanText() async {
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

  Future<void> _explainWithContext() async {
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
      _contextData = null; // Reset previous result
    });
    FocusScope.of(context).unfocus();

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final result = await geminiService.explainTextWithContext(
        text,
        targetLanguage: _selectedOutputLanguage,
      );

      if (mounted) {
        setState(() {
          _contextData = result;
          // Also speak the meaning if available
          /* 
          // Disable auto-speak for now as it disrupts conversation flow
          if (_contextData!['meaning'] != null) {
             final voiceService = Provider.of<VoiceTranslationService>(context, listen: false);
             voiceService.speakText(_contextData!['meaning'], 'en'); 
          }
          */
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

  void _showLanguagePicker() {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final languages = geminiService.getSupportedLanguages();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Select Target Language",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: languages
                  .map(
                    (e) => ListTile(
                      title: Text(
                        e['name']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: _selectedOutputLanguage == e['name']
                          ? const Icon(Icons.check, color: Color(0xFF136DEC))
                          : null,
                      onTap: () {
                        setState(() => _selectedOutputLanguage = e['name']!);
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mockup Colors
    const Color bgDark = Color(0xFF101822);
    const Color cardDark = Color(0xFF1C2027);
    const Color primaryBlue = Color(0xFF136DEC);
    const Color accentWarning = Color(0xFFFF9800);
    const Color accentDanger = Color(0xFFEF5350);
    const Color textGrey = Color(0xFF9DA8B9);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏥 ', style: TextStyle(fontSize: 20)),
            Text(
              _contextData != null
                  ? 'Contextual Insight'
                  : 'Explain Mode', // Dynamic title?
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: _showLanguagePicker,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ENGLISH', // Source placeholder
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 10,
                      color: primaryBlue,
                    ),
                  ),
                  Text(
                    _selectedOutputLanguage.toUpperCase(),
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      // Persistent Context Sheet for Voice Mode
      bottomSheet: _tabController.index == 1 && _contextData != null
          ? Container(
              color: const Color(0xFF101822),
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151A22), // Darker card
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: const Color(0xFF3B4554).withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        color: Colors.grey[700],
                        margin: const EdgeInsets.only(bottom: 16),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Color(0xFF136DEC),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "CONTEXT EXPLANATION",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _contextData!['analysis'] ??
                          (_contextData!['meaning'] ?? 'Analyzing context...'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Suggested Questions
                    if (_contextData!['suggested_questions'] != null)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              (_contextData!['suggested_questions'] as List)
                                  .map(
                                    (q) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.help_outline,
                                            color: Color(0xFFFF9800),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            q.toString(),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),

                    const SizedBox(height: 16),
                    // Cultural Insight Mini
                    if (_contextData!['cultural_insight'] != null &&
                        (_contextData!['cultural_insight'] as String).length >
                            10)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF136DEC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFF136DEC,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: Color(0xFF136DEC),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _contextData!['cultural_insight'],
                                style: const TextStyle(
                                  color: Color(0xFF136DEC),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 100,
            ), // Space for bottom bar if needed
            child: Column(
              children: [
                // Input / Scan Controls (Sticky-ish in mockup, but we keep simple)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardDark.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF3B4554).withValues(alpha: 0.5),
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCapsuleButton(
                            Icons.mic,
                            "Voice Mode",
                            _tabController.index == 1,
                            () => _tabController.animateTo(1),
                            primaryBlue,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(
                              0xFF3B4554,
                            ).withValues(alpha: 0.5),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          _buildCapsuleButton(
                            Icons.photo_camera,
                            "Camera Mode",
                            _tabController.index == 0,
                            () {
                              _tabController.animateTo(0);
                              _scanText();
                            },
                            primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Voice Mode: Chat UI
                if (_tabController.index == 1) ...[
                  Container(
                    height:
                        MediaQuery.of(context).size.height *
                        0.4, // Adjust height
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Consumer<VoiceTranslationService>(
                      builder: (context, service, child) {
                        // Combine history + current transcript
                        return ListView(
                          // reverse: true, // If we want bottom-up
                          children: [
                            ...service.conversationHistory.map(
                              (msg) => _buildChatBubble(msg, true),
                            ),
                            if (service.isListening &&
                                service.currentTranscript.isNotEmpty)
                              _buildChatBubbleStub(
                                service.currentTranscript,
                                true,
                              ),

                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Mic Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        final service = Provider.of<VoiceTranslationService>(
                          context,
                          listen: false,
                        );
                        if (service.isListening) {
                          service.stopListening();
                        } else {
                          service.startListening('user'); // Assume user for now
                        }
                      },
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: primaryBlue,
                        child: Consumer<VoiceTranslationService>(
                          builder: (context, service, _) => Icon(
                            service.isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Camera Mode: Main Content Area (Original Logic hidden if Voice)
                if (_tabController.index == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Input Card
                        if (_contextData == null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF3B4554,
                                ).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _inputController,
                                  maxLines: 4,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Enter or scan text to analyze context...',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isProcessing
                                        ? null
                                        : _explainWithContext,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: _isProcessing
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.auto_awesome),
                                    label: Text(
                                      _isProcessing
                                          ? "Analyzing..."
                                          : "Explain Context",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Context Result UI matching Mockup
                          _buildTranslationCard(
                            _inputController.text,
                            _contextData!['translation'] ?? '',
                            cardDark,
                            primaryBlue,
                            textGrey,
                          ),
                          const SizedBox(height: 16),

                          // "What this means" (Meaning)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryBlue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "What this means",
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _contextData!['meaning'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white, // White/90
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Grid: When to use & Tone
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  Icons.person_pin_circle,
                                  "When to use",
                                  _contextData!['when_to_use'] ?? '',
                                  cardDark,
                                  primaryBlue,
                                  textGrey,
                                  isAccent: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  Icons.campaign,
                                  "Tone",
                                  _contextData!['tone'] ?? '',
                                  cardDark,
                                  accentWarning,
                                  textGrey,
                                  isAccent: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Situational Context
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3B4554),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: textGrey),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Situational Context",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...((_contextData!['situational_context']
                                            as List<dynamic>?) ??
                                        [])
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Icon(
                                                Icons.circle,
                                                size: 6,
                                                color: primaryBlue,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                item.toString(),
                                                style: TextStyle(
                                                  color: textGrey,
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Cultural Insight
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -10,
                                  top: -10,
                                  child: Icon(
                                    Icons.public,
                                    size: 60,
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Cultural Insight",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _contextData!['cultural_insight'] ??
                                          'No specific cultural insight.',
                                      style: TextStyle(
                                        color: textGrey,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Safety Note (Conditional)
                          if (_contextData!['safety_note'] != null &&
                              (_contextData!['safety_note'] as String)
                                  .isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: accentDanger.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accentDanger.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: accentDanger,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Safety Note",
                                        style: TextStyle(
                                          color: accentDanger,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _contextData!['safety_note'] ?? '',
                                    style: TextStyle(
                                      color: textGrey,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Footer Actions (Share/Copy/Reset)
                          Row(
                            children: [
                              _buildIconCircleButton(
                                Icons.restart_alt,
                                cardDark,
                                () {
                                  setState(() {
                                    _contextData = null;
                                    _inputController.clear();
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildIconCircleButton(
                                Icons.content_copy,
                                cardDark,
                                () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          "${_contextData!['translation']}\nMeaning: ${_contextData!['meaning']}",
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied!')),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Share logic
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 4,
                                    shadowColor: primaryBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  icon: const Icon(Icons.share),
                                  label: const Text(
                                    "Share Phrase",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildCapsuleButton(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationCard(
    String original,
    String translation,
    Color bg,
    Color primary,
    Color subText,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B4554).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF3B4554).withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ORIGINAL TEXT",
                  style: TextStyle(
                    color: subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$original"',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Translation Body
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TRANSLATION",
                  style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  translation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text("Play Audio"),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B4554),
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.slow_motion_video, size: 20),
                      label: const Text("Slow"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String content,
    Color bg,
    Color iconColor,
    Color subTextColor, {
    required bool isAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B4554)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircleButton(IconData icon, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF3B4554)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildChatBubble(dynamic msg, bool isUser) {
    final isMe = msg.speaker == 'user' || msg.speaker == 'A';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF136DEC) : const Color(0xFF1C2027),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.originalText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (msg.translatedText.isNotEmpty)
              Text(
                msg.translatedText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubbleStub(String text, bool isUser) {
    return Align(
      alignment: Alignment.centerRight, // User speaking
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF136DEC).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
