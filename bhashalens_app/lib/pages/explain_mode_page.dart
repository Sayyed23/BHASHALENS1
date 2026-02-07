import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/offline_explain_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';

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

  Map<String, dynamic>? _contextData;
  bool _isProcessing = false;
  String _selectedOutputLanguage = 'Hindi';
  String _selectedInputLanguage = 'Auto-detected';
  late TabController _tabController;

  final List<String> _tabs = ['Camera', 'Voice'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Check for initial text
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _inputController.text = widget.initialText!;
      // Delay slightly to allow build to finish before starting async
      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        _explainWithContext();
      });
    }

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
      if (voiceService.conversationHistory.isNotEmpty) {
        final lastMsg = voiceService.conversationHistory.last;
        if (lastMsg.id != _lastAnalyzedMsgId &&
            !voiceService.isListening &&
            !_isAnalyzing) {
          setState(() {
            _lastAnalyzedMsgId = lastMsg.id;
            _inputController.text = lastMsg.originalText;
            _isAnalyzing = true;
          });
          _explainWithContext().then((_) {
            if (mounted) setState(() => _isAnalyzing = false);
          }).catchError((e) {
            if (mounted) setState(() => _isAnalyzing = false);
            debugPrint("Analysis failed: $e");
          });
        }
      }
      setState(() {});
    }
  }

  String? _lastAnalyzedMsgId;
  bool _isAnalyzing = false;

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

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _contextData = null; // Reset previous result
    });
    FocusScope.of(context).unfocus();

    // Get service references before async operations to avoid context issues
    final geminiService = Provider.of<GeminiService>(context, listen: false);

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    try {
      if (isOffline) {
        // Use offline explain service
        final offlineService = OfflineExplainService();
        final result = await offlineService.explainAsMap(text);

        // Add offline indicator to result
        result['_offline'] = true;

        if (mounted) {
          setState(() {
            _contextData = result;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using offline explanation (basic mode)'),
              backgroundColor: Colors.blueGrey,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Use online Gemini service (acquired before async ops)
        final result = await geminiService.explainTextWithContext(
          text,
          targetLanguage: _selectedOutputLanguage,
          sourceLanguage: _selectedInputLanguage,
        );

        if (mounted) {
          setState(() {
            _contextData = result;
          });
        }
      }
    } catch (e) {
      // On any error, try offline fallback
      try {
        final offlineService = OfflineExplainService();
        final result = await offlineService.explainAsMap(text);
        result['_offline'] = true;

        if (mounted) {
          setState(() {
            _contextData = result;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection failed. Using offline explanation.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to explain: $e')));
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showLanguagePicker({bool isInput = false}) {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    var languages = geminiService.getSupportedLanguages();

    // Add Auto-detected option for input
    if (isInput) {
      languages = [
        {'code': 'auto', 'name': 'Auto-detected'},
        ...languages,
      ];
    }

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
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              isInput ? "Select Source Language" : "Select Target Language",
              style: const TextStyle(
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
                      trailing: (isInput
                                  ? _selectedInputLanguage
                                  : _selectedOutputLanguage) ==
                              e['name']
                          ? const Icon(Icons.check, color: Color(0xFF136DEC))
                          : null,
                      onTap: () {
                        setState(() {
                          if (isInput) {
                            _selectedInputLanguage = e['name']!;
                          } else {
                            _selectedOutputLanguage = e['name']!;
                          }
                        });
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

  void _swapLanguages() {
    if (_selectedInputLanguage == 'Auto-detected') return;
    setState(() {
      final temp = _selectedInputLanguage;
      _selectedInputLanguage = _selectedOutputLanguage;
      _selectedOutputLanguage = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mockup Colors
    const Color bgDark = Color(0xFF101822);
    const Color cardDark = Color(0xFF1C2027);
    const Color primaryBlue = Color(0xFF136DEC);
    const Color textGrey = Color(0xFF9DA8B9);
    const Color accentWarning = Color(0xFFFF9800);
    const Color accentDanger = Color(0xFFEF5350);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16), // Rounded pill
            border: Border.all(
              color: const Color(0xFF3B4554).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // FROM
              Expanded(
                child: GestureDetector(
                  onTap: () => _showLanguagePicker(isInput: true),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "FROM",
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _selectedInputLanguage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Increased size
                                fontWeight: FontWeight.bold, // Bolder
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: textGrey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Swap Icon
              GestureDetector(
                onTap: _swapLanguages,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B4554).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: _selectedInputLanguage == 'Auto-detected'
                        ? Colors.grey.withValues(alpha: 0.5)
                        : primaryBlue,
                    size: 20,
                  ),
                ),
              ),
              // TO
              Expanded(
                child: GestureDetector(
                  onTap: () => _showLanguagePicker(isInput: false),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "TO",
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedOutputLanguage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Increased size
                                fontWeight: FontWeight.bold, // Bolder
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: textGrey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
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
            padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Large Mode Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B4554).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBigTabButton(
                          Icons.keyboard_outlined,
                          "Text Input",
                          _tabController.index == 0,
                          () {
                            setState(() {
                              _tabController.animateTo(0);
                            });
                          },
                          primaryBlue,
                        ),
                      ),
                      Expanded(
                        child: _buildBigTabButton(
                          Icons.mic_none_outlined,
                          "Voice Chat",
                          _tabController.index == 1,
                          () {
                            setState(() {
                              _tabController.animateTo(1);
                            });
                          },
                          primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Voice Mode: Chat UI
                if (_tabController.index == 1) ...[
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Consumer<VoiceTranslationService>(
                      builder: (context, service, child) {
                        if (service.conversationHistory.isEmpty &&
                            service.currentTranscript.isEmpty &&
                            !service.isListening) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.graphic_eq,
                                  size: 80,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Tap the mic to start",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        // Combine history + current transcript
                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const SizedBox(height: 20),

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
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryBlue,
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Consumer<VoiceTranslationService>(
                          builder: (context, service, _) => Icon(
                            service.isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Text Input Mode: Main Content Area
                if (_tabController.index == 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Input Card
                      if (_contextData == null)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardDark,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(
                                0xFF3B4554,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Is there something confusing you want to understand?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: bgDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: TextField(
                                  controller: _inputController,
                                  maxLines: 6,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type here or scan...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  onChanged: (val) => setState(() {}),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _scanText,
                                    icon: const Icon(
                                      Icons.camera_alt_outlined,
                                      color: Color(0xFF136DEC),
                                    ),
                                    label: const Text(
                                      "Scan Text",
                                      style: TextStyle(
                                        color: Color(0xFF136DEC),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      backgroundColor: const Color(
                                        0xFF136DEC,
                                      ).withValues(alpha: 0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_inputController.text.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _inputController.clear();
                                        });
                                      },
                                      child: const Text(
                                        "Clear",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing
                                      ? null
                                      : _explainWithContext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: _isProcessing
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ) // End Input Card
                      else ...[
                        // Context Result UI matching Mockup
                        _buildTranslationCard(
                          _inputController.text,
                          _contextData!['translation'] ?? '',
                          cardDark,
                          primaryBlue,
                          textGrey,
                          onPlayAudio: () => _speakInOutputLanguage(
                            _contextData!['translation'],
                          ),
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
                                  const Icon(
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
                                  const Spacer(),
                                  InkWell(
                                    onTap: () => _speakInOutputLanguage(
                                      _contextData!['meaning'],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryBlue.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.volume_up_rounded,
                                        size: 20,
                                        color: primaryBlue,
                                      ),
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
                                onPlayAudio: () => _speakInOutputLanguage(
                                  _contextData!['when_to_use'],
                                ),
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
                                onPlayAudio: () => _speakInOutputLanguage(
                                  _contextData!['tone'],
                                ),
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
                            border: Border.all(color: const Color(0xFF3B4554)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Situational Context",
                                    style: TextStyle(
                                      color: textGrey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () => _speakInOutputLanguage(
                                      _contextData!['cultural_insight'],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.volume_up_rounded,
                                        size: 18,
                                        color: textGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.info_outline, color: textGrey),
                                  SizedBox(width: 8),
                                  Text(
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
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(
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
                                          style: const TextStyle(
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
                                    style: const TextStyle(
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
                            _contextData!['safety_note'] is String &&
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
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: accentDanger,
                                    ),
                                    SizedBox(width: 8),
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
                                  style: const TextStyle(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigTabButton(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[500],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets for Results
  Widget _buildTranslationCard(
    String original,
    String translated,
    Color cardColor,
    Color accentColor,
    Color textColor, {
    VoidCallback? onPlayAudio,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B4554).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section (Original Text)
          Container(
            padding: const EdgeInsets.all(20),
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
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  original,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Translation Body
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.translate, size: 16, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      "TRANSLATION",
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (onPlayAudio != null)
                      InkWell(
                        onTap: onPlayAudio,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: accentColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  translated,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
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
    VoidCallback? onPlayAudio,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccent
              ? iconColor.withValues(alpha: 0.3)
              : const Color(0xFF3B4554).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onPlayAudio != null)
                InkWell(
                  onTap: onPlayAudio,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
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

  void _speakInOutputLanguage(String? text) {
    if (text == null || text.isEmpty) return;

    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final langEntry = geminiService.getSupportedLanguages().firstWhere(
          (l) => l['name'] == _selectedOutputLanguage,
          orElse: () => {'code': 'en'},
        );
    final langCode = langEntry['code'] ?? 'en';

    Provider.of<VoiceTranslationService>(
      context,
      listen: false,
    ).speakText(text, langCode);
  }
}
