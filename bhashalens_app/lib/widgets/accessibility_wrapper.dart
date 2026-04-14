import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/enhanced_accessibility_service.dart';
import 'package:flutter/services.dart';

class AccessibilityWrapper extends StatefulWidget {
  final Widget child;
  final String currentPage;

  const AccessibilityWrapper({
    super.key,
    required this.child,
    required this.currentPage,
  });

  @override
  State<AccessibilityWrapper> createState() => _AccessibilityWrapperState();
}

class _AccessibilityWrapperState extends State<AccessibilityWrapper> {
  @override
  void initState() {
    super.initState();
    // Set the current page context on the voice navigation service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePageContext();
    });
  }

  @override
  void didUpdateWidget(covariant AccessibilityWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _updatePageContext();
    }
  }

  void _updatePageContext() {
    try {
      final controller =
          Provider.of<AccessibilityController>(context, listen: false);
      final voiceNav = controller.voiceNavigation;
      if (voiceNav is VoiceNavigationController) {
        voiceNav.setCurrentPage(widget.currentPage);
      }
      // Announce page change via audio feedback
      if (controller.isAudioFeedbackEnabled) {
        controller.audioFeedback?.announcePageChange(widget.currentPage);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityController>(
      builder: (context, controller, _) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () async {
            HapticFeedback.heavyImpact();

            if (controller.isVoiceNavigationEnabled) {
              final voiceNav = controller.voiceNavigation;
              if (voiceNav != null) {
                if (voiceNav.isListening) {
                  await voiceNav.stopListening();
                } else {
                  try {
                    await voiceNav.startListening();
                  } catch (e) {
                    debugPrint('Voice navigation start failed: $e');
                    controller.audioFeedback?.announceError(
                      "voice_nav_start",
                      customMessage: "Could not start voice navigation. $e",
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Voice navigation error: $e',
                            style: const TextStyle(fontSize: 13),
                          ),
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              }
            } else {
              // Voice guidance is OFF — notify user
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Voice guidance is disabled. Enable it in Settings → Accessibility.',
                      style: TextStyle(fontSize: 13),
                    ),
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: widget.child,
        );
      },
    );
  }
}
