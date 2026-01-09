import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AssistantModePage extends StatefulWidget {
  const AssistantModePage({super.key});

  @override
  State<AssistantModePage> createState() => _AssistantModePageState();
}

class _AssistantModePageState extends State<AssistantModePage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _refinedText = '';
  bool _isRefining = false;
  String _selectedTone = 'Auto';
  final List<String> _tones = [
    'Auto',
    'Confident',
    'Professional',
    'Polite',
    'Direct',
  ];

  @override
  void initState() {
    super.initState();
    // Listen to voice service for real-time transcription
    final voiceService = Provider.of<VoiceTranslationService>(
      context,
      listen: false,
    );
    voiceService.addListener(_onVoiceUpdate);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
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
    if (voiceService.isListening &&
        voiceService.currentTranscript.isNotEmpty &&
        voiceService.currentSpeaker == 'Assistant') {
      setState(() {
        _inputController.text = voiceService.currentTranscript;
      });
    }
  }

  Future<void> _refineText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

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
      _isRefining = true;
      _refinedText = '';
    });

    FocusScope.of(context).unfocus();

    // Add mounted check after async navigation/unfocus if needed,
    // though unfocus is usually synchronous in effect on widget tree state.
    // However, the previous async gap was checkConnectivity.

    if (!mounted) return; // Add check before using context for Provider

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final result = await geminiService.refineText(
        text,
        style: _selectedTone.toLowerCase(),
      );

      if (mounted) {
        setState(() {
          _refinedText = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to refine text: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefining = false;
        });
      }
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
      // Use 'Assistant' as a special speaker ID
      await voiceService.startListening('Assistant');
    }
  }

  void _copyToClipboard() {
    if (_refinedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _refinedText));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  Future<void> _speakRefinedText() async {
    if (_refinedText.isNotEmpty) {
      final voiceService = Provider.of<VoiceTranslationService>(
        context,
        listen: false,
      );
      await voiceService.speakText(_refinedText, 'en');
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = Provider.of<VoiceTranslationService>(context);
    final isListening =
        voiceService.isListening && voiceService.currentSpeaker == 'Assistant';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Speak Confidently',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro
              Text(
                'Turn your thoughts into polished, professional speech.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 24),

              // Tone Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _tones.map((tone) {
                    final isSelected = _selectedTone == tone;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(tone),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTone = tone;
                            });
                          }
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Input Area
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Type or speak what you want to say...",
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isListening ? Icons.mic : Icons.mic_none,
                                color: isListening
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _toggleListening,
                            ),
                            if (isListening)
                              const Text(
                                'Listening...',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRefining ? null : _refineText,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          icon: _isRefining
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(_isRefining ? 'Refining...' : 'Refine'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Output Area
              if (_refinedText.isNotEmpty) ...[
                Text(
                  'Polished Version:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.05),
                          Theme.of(
                            context,
                          ).colorScheme.tertiary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Text(
                              _refinedText,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontSize: 18,
                                    height: 1.5,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded),
                              onPressed: _speakRefinedText,
                              tooltip: 'Listen',
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded),
                              onPressed: _copyToClipboard,
                              tooltip: 'Copy',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(child: SizedBox()), // Spacer
              ],
            ],
          ),
        ),
      ),
    );
  }
}
