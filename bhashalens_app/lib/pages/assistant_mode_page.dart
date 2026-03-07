import 'package:bhashalens_app/services/hybrid_translation_service.dart';
import 'package:bhashalens_app/services/smart_hybrid_router.dart';
import 'package:flutter/material.dart';
import 'package:bhashalens_app/widgets/common_bottom_nav_bar.dart';
import 'package:bhashalens_app/widgets/backend_indicator_widget.dart';
import 'package:bhashalens_app/widgets/web_constrained_body.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';

class AssistantModePage extends StatefulWidget {
  const AssistantModePage({super.key});

  @override
  State<AssistantModePage> createState() => _AssistantModePageState();
}

class _AssistantModePageState extends State<AssistantModePage> {
  int _selectedSituationIndex = 0;
  List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  ProcessingBackend? _lastChatBackend;

  final List<Map<String, dynamic>> _situations = const [
    {
      'icon': Icons.business_center,
      'label': 'Office',
    },
    {
      'icon': Icons.medical_services,
      'label': 'Hospital',
    },
    {
      'icon': Icons.security,
      'label': 'Police',
    },
    {
      'icon': Icons.flight,
      'label': 'Travel',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate with a welcome message or empty
    _chatMessages = [
      {
        'role': 'other',
        'text': 'Hello! How can I help you today? Choose a category above or just ask me anything.',
      },
    ];
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final service = Provider.of<VoiceTranslationService>(context, listen: false);
    try {
      if (service.isListening) {
        await service.stopListening();
      } else {
        await service.listenOnce((text) {
          if (mounted) {
            setState(() {
              _chatController.text = text;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
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

    _scrollToBottom();

    try {
      final service = Provider.of<HybridTranslationService>(context, listen: false);
      final situation = _situations[_selectedSituationIndex]['label'];
      
      final result = await service.orchestrate(
        text: text,
        mode: 'assist',
        language: 'English', // Target language
        situationalContext: situation,
      );
      
      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'other', 'text': result.response});
          _lastChatBackend = result.backend;
        });

        if (!result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Service error occurred.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message could not be sent.')),
        );
      }
    }
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF8FAFC);
    const Color cardWhite = Colors.white;
    const Color primaryBlue = Color(0xFF136DEC);
    const Color textDark = Color(0xFF1E293B);
    const Color textGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Assist Mode',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: textDark),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 4),
      body: wrapWithWebMaxWidth(
        context,
        child: Column(
          children: [
            // Top Categories & Settings
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Categories
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _situations.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedSituationIndex == index;
                        final situation = _situations[index];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSituationIndex = index),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  situation['icon'],
                                  color: isSelected ? Colors.white : textDark,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                situation['label'],
                                style: TextStyle(
                                  color: isSelected ? primaryBlue : textGrey,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Language Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildLangCol("INPUT", "Hindi (Auto)", textGrey, textDark, primaryBlue),
                            Container(height: 30, width: 1, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                            _buildLangCol("TARGET", "English", textGrey, primaryBlue, primaryBlue),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        Row(
                          children: [
                            const Icon(Icons.volume_up, size: 20),
                            const SizedBox(width: 8),
                            const Text("Voice Output", style: TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Switch(
                              value: true,
                              onChanged: (v) {},
                              activeThumbColor: Colors.white,
                              activeTrackColor: primaryBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatMessages[index];
                  final isMe = msg['role'] == 'me';
                  if (isMe) {
                    return _buildUserBubble(msg['text'], primaryBlue);
                  } else {
                    return _buildBotBubble(msg['text'], cardWhite, textDark, primaryBlue);
                  }
                },
              ),
            ),

            // Voice & Input Area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_lastChatBackend != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: BackendIndicatorWidget(backend: _lastChatBackend),
                    ),
                  // Waveform Mock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => Container(
                      width: 3, height: i == 2 ? 24 : 12, margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(2)),
                    )),
                  ),
                  const SizedBox(height: 4),
                  const Text("LISTENING...", style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  // Large Mic
                  GestureDetector(
                    onTap: _startListening,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.mic, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Chat Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: "Ask something like: How do I ask for help?",
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, color: primaryBlue, size: 20),
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
    );
  }

  Widget _buildLangCol(String label, String value, Color labelColor, Color valColor, Color iconColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(value, style: TextStyle(color: valColor, fontSize: 14, fontWeight: FontWeight.bold)),
              Icon(Icons.keyboard_arrow_down, size: 16, color: iconColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text, Color bg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildBotBubble(String text, Color bg, Color textPlain, Color primary) {
    final isSuggestion = text.contains('"');
    if (isSuggestion) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, decoration: BoxDecoration(color: primary, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: primary),
                          const SizedBox(width: 6),
                          Text("SUGGESTED SENTENCE", style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(text, style: TextStyle(color: textPlain, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFFEDF2F7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(text, style: TextStyle(color: textPlain, fontSize: 14)),
      ),
    );
  }
}
