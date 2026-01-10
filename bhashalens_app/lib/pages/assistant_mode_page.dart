import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';

class AssistantModePage extends StatefulWidget {
  const AssistantModePage({super.key});

  @override
  State<AssistantModePage> createState() => _AssistantModePageState();
}

class _AssistantModePageState extends State<AssistantModePage> {
  int _selectedSituationIndex = 0;
  int _selectedGoalIndex = 0;
  bool _isSlowMode = false;

  // Context-Aware State
  Map<String, dynamic>? _basicGuide;
  bool _isLoadingGuide = false;
  bool _isListening = false;
  List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  final List<Map<String, dynamic>> _situations = [
    {
      'icon': Icons.local_hospital,
      'label': 'Hospital',
      'color': Color(0xFF136DEC),
    },
    {'icon': Icons.apartment, 'label': 'Public Office', 'color': Colors.grey},
    {'icon': Icons.shopping_cart, 'label': 'Shop', 'color': Colors.grey},
    {'icon': Icons.school, 'label': 'School', 'color': Colors.grey},
  ];

  final List<String> _goals = [
    'Ask for help',
    'Explain a problem',
    'Request leave',
    'Book appointment',
  ];

  // This will now be the initial state, but chat will be dynamic
  // Scenarios Data  // Scenarios Data
  final Map<String, Map<String, dynamic>> _scenarios = {
    'Hospital': {
      'user_lang_text': 'मुझे डॉक्टर से मिलना है।',
      'translation': '"I would like to see a doctor, please."',
      'confidence_tip':
          'This phrasing is polite and respectful for official use in professional environments.',
      'tone': 'Urgent',
    },
    'Public Office': {
      'user_lang_text': 'मुझे अपना आधार कार्ड अपडेट कराना है।',
      'translation': '"I need to update my Aadhar card details."',
      'confidence_tip': 'Be direct and have your documents ready.',
      'tone': 'Formal',
    },
    'Shop': {
      'user_lang_text': 'इसकी कीमत क्या है?',
      'translation': '"How much does this cost?"',
      'confidence_tip': 'It is okay to ask for a better price in some shops.',
      'tone': 'Casual',
    },
    'School': {
      'user_lang_text': 'मैं अपने बच्चे के प्रवेश के बारे में पूछना चाहता हूं।',
      'translation': '"I want to inquire about my child\'s admission."',
      'confidence_tip': 'Use a polite and inquiring tone with school staff.',
      'tone': 'Polite',
    },
  };

  late Map<String, dynamic> _currentScenario;

  @override
  void initState() {
    super.initState();
    _currentScenario = _scenarios['Hospital']!; // Default

    // Initialize with mock chat for demo, but enable dynamic chat
    _chatMessages = [
      {'role': 'me', 'text': 'I need leave for my appointment.'},
      {
        'role': 'other',
        'text': 'Please fill this form first, then we can process it.',
      },
    ];
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchBasicGuide() async {
    setState(() => _isLoadingGuide = true);
    try {
      final service = Provider.of<GeminiService>(context, listen: false);
      final situation = _situations[_selectedSituationIndex]['label'];
      final guide = await service.getBasicGuide(
        situation,
        'English',
      ); // Default to English for now

      if (mounted) {
        setState(() => _basicGuide = guide);
        _showGuideModal();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load guide: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoadingGuide = false);
    }
  }

  void _showGuideModal() {
    if (_basicGuide == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => GuideSheet(
          initialGuide: _basicGuide!,
          situation: _situations[_selectedSituationIndex]['label'],
          scrollController: scrollController,
        ),
      ),
    );
  }

  Future<void> _startRoleplay() async {
    final service = Provider.of<GeminiService>(context, listen: false);
    final situation = _situations[_selectedSituationIndex]['label'];
    final goalText = _goals[_selectedGoalIndex];

    // Add loading state message
    setState(() {
      _chatMessages = [
        {'role': 'other', 'text': 'Thinking...'},
      ];
    });

    try {
      final greeting = await service.startRoleplay(
        situation,
        goalText,
        'English',
      );

      if (mounted) {
        setState(() {
          _chatMessages = [
            {'role': 'other', 'text': greeting},
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages = [
            {
              'role': 'other',
              'text': 'Failed to start roleplay. Please try again.',
            },
          ];
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _startListening() async {
    final service = Provider.of<VoiceTranslationService>(
      context,
      listen: false,
    );
    try {
      if (_isListening) {
        await service.stopListening();
        setState(() => _isListening = false);
      } else {
        setState(() => _isListening = true);
        await service.listenOnce((text) {
          if (mounted) {
            setState(() {
              _chatController.text = text;
            });
          }
        });
        if (mounted) {
          setState(() => _isListening = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Voice Input Failed: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'me', 'text': text});
      _chatController.clear();
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final service = Provider.of<GeminiService>(context, listen: false);
      // Helper to ensure initialized?
      // Assuming context is valid

      final response = await service.chatWithAssistant(text);
      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'other', 'text': response});
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors from mockup
    const Color bgDark = Color(0xFF101822);
    const Color cardDark = Color(0xFF1C2027);
    const Color primaryBlue = Color(0xFF136DEC);
    const Color textGrey = Color(0xFF9DA8B9);

    final voiceService = Provider.of<VoiceTranslationService>(context);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: cardDark, shape: BoxShape.circle),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Assistant Mode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Situations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Situation",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isLoadingGuide ? null : _fetchBasicGuide,
                  icon: _isLoadingGuide
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF136DEC),
                        ),
                  label: Text(
                    _isLoadingGuide ? "Loading..." : "Basic Guide",
                    style: const TextStyle(color: Color(0xFF136DEC)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _situations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = _selectedSituationIndex == index;
                  final situation = _situations[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSituationIndex = index;
                        final label = _situations[index]['label'];
                        if (_scenarios.containsKey(label)) {
                          _currentScenario = _scenarios[label]!;
                        }
                        // Reset Chat and Guide
                        _basicGuide = null;
                        _chatMessages = [];
                      });
                    },
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1C2027)
                            : const Color(0xFF1C2027).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24), // Squircle
                        border: isSelected
                            ? Border.all(color: primaryBlue, width: 2)
                            : Border.all(color: Colors.transparent),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            situation['icon'],
                            color: isSelected ? primaryBlue : textGrey,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            situation['label'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSelected ? "Active" : "Select",
                            style: TextStyle(
                              color: isSelected ? primaryBlue : textGrey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Goals
            const Text(
              "What is your goal?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_goals.length, (index) {
                final isSelected = _selectedGoalIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGoalIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue : cardDark,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? primaryBlue : Colors.white12,
                      ),
                    ),
                    child: Text(
                      _goals[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Recommendation Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "PRIMARY RECOMMENDATION",
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your language",
                    style: TextStyle(color: textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentScenario['user_lang_text'],
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Translation",
                    style: TextStyle(color: primaryBlue, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentScenario['translation'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Confidence Tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // Darker blueish
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "CONFIDENCE TIP",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentScenario['confidence_tip'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
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
            ),
            const SizedBox(height: 20),

            // Audio Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Play Button
                      GestureDetector(
                        onTap: () {
                          String textToSpeak = _currentScenario['translation'];
                          // Remove quotes if present
                          textToSpeak = textToSpeak.replaceAll('"', '');
                          voiceService.speakText(
                            textToSpeak,
                            'en',
                            slow: _isSlowMode,
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Listen",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Natural AI voice",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Slow Toggle
                  Row(
                    children: [
                      Text(
                        "Slow",
                        style: TextStyle(
                          color: _isSlowMode ? Colors.white : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isSlowMode,
                        onChanged: (val) => setState(() => _isSlowMode = val),
                        activeThumbColor: primaryBlue,
                        activeTrackColor: primaryBlue.withValues(alpha: 0.2),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.white10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Practice Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startRoleplay,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  foregroundColor: primaryBlue,
                ),
                icon: const Icon(Icons.mic),
                label: const Text(
                  "Practice Speaking (Start Coaching)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Live Coaching Chat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "LIVE COACHING",
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 400, // Fixed height for chat area
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151A22), // Dark Chat bg
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _chatScrollController,
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        return _buildChatBubble(msg, msg['role'] == 'me');
                      },
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : primaryBlue,
                        ),
                        onPressed: _startListening,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Type or speak...",
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: primaryBlue),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe) {
    const Color primaryBlue = Color(0xFF136DEC);
    final text = msg['text'] as String;
    final translation = msg['translation'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "ME",
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            // Translate Icon
            GestureDetector(
              onTap: () async {
                if (!mounted) return;
                final service = Provider.of<VoiceTranslationService>(
                  context,
                  listen: false,
                );
                // Translate to 'Hindi' (hardcoded for now as requested)
                final translated = await service.translateText(text, 'hi');

                if (mounted) {
                  setState(() {
                    msg['translation'] = translated;
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.translate,
                  size: 16,
                  color: primaryBlue,
                ),
              ),
            ),
            // Speaker Icon for AI
            GestureDetector(
              onTap: () {
                final voiceService = Provider.of<VoiceTranslationService>(
                  context,
                  listen: false,
                );
                voiceService.speakText(text, 'en');
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up,
                  size: 16,
                  color: primaryBlue,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF333A44) : primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomRight: isMe ? const Radius.circular(20) : Radius.zero,
                  bottomLeft: isMe ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                  if (translation != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      translation,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuideSheet extends StatefulWidget {
  final Map<String, dynamic> initialGuide;
  final String situation;
  final ScrollController? scrollController;

  const GuideSheet({
    super.key,
    required this.initialGuide,
    required this.situation,
    this.scrollController,
  });

  @override
  State<GuideSheet> createState() => _GuideSheetState();
}

class _GuideSheetState extends State<GuideSheet> {
  late Map<String, dynamic> _guide;
  String _currentLanguage = 'English';
  bool _isLoading = false;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Spanish',
    'French',
    'German',
    'Japanese',
    'Arabic',
  ];

  @override
  void initState() {
    super.initState();
    _guide = widget.initialGuide;
  }

  Future<void> _changeLanguage(String? newLang) async {
    if (newLang == null || newLang == _currentLanguage) return;

    setState(() {
      _isLoading = true;
      _currentLanguage = newLang;
    });

    try {
      final service = Provider.of<GeminiService>(context, listen: false);
      final newGuide = await service.getBasicGuide(widget.situation, newLang);
      if (mounted) {
        setState(() => _guide = newGuide);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to translate guide: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Basic Guide: ${widget.situation}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Language Dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currentLanguage,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: _changeLanguage,
                    items: _languages.map((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildGuideSection(
              "Opening Phrase",
              _guide['opening_phrase'],
              Icons.chat_bubble_outline,
            ),
            _buildGuideSection(
              "Etiquette",
              _guide['etiquette'],
              Icons.diversity_3,
            ),
            _buildGuideSection(
              "Documents Needed",
              _guide['documents'],
              Icons.folder_copy_outlined,
            ),
            _buildGuideSection(
              "Steps",
              _guide['steps'],
              Icons.format_list_numbered,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, dynamic content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF136DEC), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF136DEC),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (content is String)
            Text(
              content,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            )
          else if (content is List)
            ...content.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        e.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
