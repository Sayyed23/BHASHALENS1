import 'dart:convert';
import 'package:bhashalens_app/models/translation_history_entry.dart';
import 'package:bhashalens_app/services/hybrid_translation_service.dart';
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
  bool _isAILoading = false;

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
    _chatMessages = [
      {
        'role': 'other',
        'text':
            'Hello! How can I help you today? Choose a category above or just ask me anything.',
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
    final service =
        Provider.of<VoiceTranslationService>(context, listen: false);
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
      _isAILoading = true;
    });

    _scrollToBottom();

    try {
      final service =
          Provider.of<HybridTranslationService>(context, listen: false);
      final situation = _situations[_selectedSituationIndex]['label'];

      final result = await service.orchestrate(
        text: text,
        mode: 'assist',
        language: 'English', // Could be dynamic
        situationalContext: situation,
      );

      if (mounted) {
        setState(() {
          _isAILoading = false;
          _lastChatBackend = result.backend;

          try {
            // Parse the JSON assistant response
            final Map<String, dynamic> data = jsonDecode(result.response);
            
            // 1. Primary Response
            _chatMessages.add({
              'role': 'other',
              'text': data['response'] ?? '...',
            });

            // 2. Better Way (if available)
            if (data['better_way'] != null && data['better_way'].toString().isNotEmpty) {
              _chatMessages.add({
                'role': 'system',
                'type': 'better_way',
                'text': data['better_way'],
              });
            }

            // 3. Cultural Note (if available)
            if (data['cultural_note'] != null && data['cultural_note'].toString().isNotEmpty) {
              _chatMessages.add({
                'role': 'system',
                'type': 'cultural_note',
                'text': data['cultural_note'],
              });
            }

            // 4. Suggested Replies (UI enhancement)
            // We can store them on the last message or as a separate state
            // For now, let's keep it simple

          } catch (e) {
            // Fallback if not JSON
            _chatMessages.add({'role': 'other', 'text': result.response});
          }
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
        setState(() => _isAILoading = false);
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
    // Dark Premium Theme
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);
    const Color primaryBlue = Color(0xFF3B82F6);
    const Color textLight = Color(0xFFF1F5F9);
    const Color textGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            color: textLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.history, color: textGrey),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 4),
      body: wrapWithWebMaxWidth(
        context,
        child: Column(
          children: [
            // Situational Category Selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SITUATIONAL CONTEXT",
                    style: TextStyle(
                        color: textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _situations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedSituationIndex == index;
                        final situation = _situations[index];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedSituationIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 76,
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue : cardDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? primaryBlue
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: primaryBlue
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4))
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  situation['icon'],
                                  color: isSelected ? Colors.white : textGrey,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  situation['label'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : textGrey,
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _chatMessages.length + (_isAILoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatMessages.length && _isAILoading) {
                      return _buildTypingIndicator();
                    }
                    final msg = _chatMessages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: cardDark,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    if (_lastChatBackend != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BackendIndicatorWidget(backend: _lastChatBackend),
                      ),
                    Row(
                      children: [
                        // Large Mic Button
                        GestureDetector(
                          onTap: _startListening,
                          child: Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(Icons.mic,
                                color: primaryBlue, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text Input
                        Expanded(
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: bgDark,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatController,
                                    style: const TextStyle(color: textLight),
                                    decoration: const InputDecoration(
                                      hintText: "How do I ask for help?",
                                      hintStyle: TextStyle(color: textGrey),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _sendMessage,
                                  icon: const Icon(Icons.send_rounded,
                                      color: primaryBlue),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final role = msg['role'];
    final text = msg['text'] ?? '';
    final type = msg['type'];

    if (role == 'me') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 40),
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    } else if (role == 'system') {
      final isBetterWay = type == 'better_way';
      return Container(
        margin: const EdgeInsets.only(bottom: 16, right: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isBetterWay
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBetterWay
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isBetterWay ? Icons.auto_awesome : Icons.info_outline,
              size: 20,
              color: isBetterWay ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBetterWay ? "BETTER WAY TO SAY" : "CULTURAL NOTE",
                    style: TextStyle(
                      color: isBetterWay ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // AI Bubble
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 40),
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 15),
          ),
        ),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }
}
