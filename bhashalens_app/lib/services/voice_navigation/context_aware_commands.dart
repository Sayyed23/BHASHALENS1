import '../../models/voice_command.dart';

/// Context-aware command manager for page-specific voice commands
class ContextAwareCommandManager {
  // Page-specific command definitions with detailed variations
  final Map<String, Map<String, List<String>>> _pageCommands = {
    '/': {
      'quick_camera': ['quick camera', 'fast camera', 'camera now'],
      'quick_voice': ['quick voice', 'fast voice', 'voice now'],
      'quick_text': ['quick text', 'fast text', 'text now'],
      'recent_translations': [
        'recent translations',
        'history',
        'my translations'
      ],
      'emergency_phrases': ['emergency', 'emergency phrases', 'help phrases'],
    },
    '/camera': {
      'take_photo': ['take photo', 'capture', 'snap', 'take picture', 'shoot'],
      'switch_camera': [
        'switch camera',
        'flip camera',
        'front camera',
        'back camera'
      ],
      'flash_toggle': [
        'flash on',
        'flash off',
        'toggle flash',
        'turn on flash'
      ],
      'gallery': ['gallery', 'photo gallery', 'saved photos'],
      'retake': ['retake', 'take again', 'retry photo'],
      'translate_photo': ['translate this', 'translate photo', 'read this'],
    },
    '/voice': {
      'start_recording': [
        'start recording',
        'begin recording',
        'record now',
        'listen'
      ],
      'stop_recording': ['stop recording', 'stop', 'finish recording'],
      'play_translation': [
        'play translation',
        'read translation',
        'speak translation'
      ],
      'change_language': [
        'change language',
        'switch language',
        'different language'
      ],
      'clear_recording': ['clear', 'delete', 'start over', 'clear recording'],
      'save_translation': ['save this', 'save translation', 'keep this'],
    },
    '/text': {
      'clear_text': ['clear text', 'delete all', 'erase text', 'start over'],
      'paste_text': ['paste', 'paste text', 'insert text'],
      'translate_text': ['translate', 'translate this', 'translate text'],
      'copy_translation': ['copy translation', 'copy result', 'copy this'],
      'share_translation': ['share', 'share this', 'send translation'],
      'save_translation': ['save', 'save this', 'keep translation'],
    },
    '/settings': {
      'accessibility_settings': [
        'accessibility',
        'accessibility settings',
        'voice settings'
      ],
      'language_settings': [
        'language settings',
        'translation languages',
        'languages'
      ],
      'theme_settings': ['theme', 'dark mode', 'light mode', 'appearance'],
      'audio_settings': ['audio settings', 'sound settings', 'voice settings'],
      'reset_settings': [
        'reset settings',
        'default settings',
        'restore defaults'
      ],
      'export_settings': [
        'export settings',
        'backup settings',
        'save settings'
      ],
    },
    '/history': {
      'clear_history': ['clear history', 'delete history', 'remove all'],
      'search_history': ['search', 'find translation', 'search history'],
      'export_history': [
        'export history',
        'backup translations',
        'save history'
      ],
      'favorite_translation': ['favorite', 'star this', 'mark favorite'],
      'delete_translation': [
        'delete this',
        'remove this',
        'delete translation'
      ],
    },
    '/emergency': {
      'medical_help': [
        'medical help',
        'doctor',
        'hospital',
        'emergency medical'
      ],
      'police_help': ['police', 'call police', 'emergency police'],
      'fire_help': ['fire department', 'fire emergency', 'call fire'],
      'location_help': ['where am I', 'my location', 'address'],
      'contact_help': ['call contact', 'emergency contact', 'call family'],
    },
  };

  // Command help descriptions for each page
  final Map<String, Map<String, String>> _commandDescriptions = {
    '/': {
      'quick_camera': 'Quickly open camera translation',
      'quick_voice': 'Quickly open voice translation',
      'quick_text': 'Quickly open text translation',
      'recent_translations': 'View your translation history',
      'emergency_phrases': 'Access emergency phrases',
    },
    '/camera': {
      'take_photo': 'Take a photo for translation',
      'switch_camera': 'Switch between front and back camera',
      'flash_toggle': 'Turn camera flash on or off',
      'gallery': 'Open photo gallery',
      'retake': 'Take another photo',
      'translate_photo': 'Translate the current photo',
    },
    '/voice': {
      'start_recording': 'Start voice recording for translation',
      'stop_recording': 'Stop the current recording',
      'play_translation': 'Play the translated audio',
      'change_language': 'Change translation language',
      'clear_recording': 'Clear the current recording',
      'save_translation': 'Save this translation',
    },
    '/text': {
      'clear_text': 'Clear all entered text',
      'paste_text': 'Paste text from clipboard',
      'translate_text': 'Translate the entered text',
      'copy_translation': 'Copy translation to clipboard',
      'share_translation': 'Share the translation',
      'save_translation': 'Save this translation',
    },
    '/settings': {
      'accessibility_settings': 'Open accessibility settings',
      'language_settings': 'Configure translation languages',
      'theme_settings': 'Change app theme and appearance',
      'audio_settings': 'Configure audio and voice settings',
      'reset_settings': 'Reset all settings to defaults',
      'export_settings': 'Export settings for backup',
    },
    '/history': {
      'clear_history': 'Clear all translation history',
      'search_history': 'Search through translation history',
      'export_history': 'Export translation history',
      'favorite_translation': 'Mark translation as favorite',
      'delete_translation': 'Delete selected translation',
    },
    '/emergency': {
      'medical_help': 'Get medical emergency phrases',
      'police_help': 'Get police emergency phrases',
      'fire_help': 'Get fire emergency phrases',
      'location_help': 'Get location and address phrases',
      'contact_help': 'Access emergency contact phrases',
    },
  };

  // Error suggestions for common mistakes
  final Map<String, List<String>> _errorSuggestions = {
    'camera_errors': [
      'Did you mean "take photo" or "capture"?',
      'Try saying "switch camera" to change cameras',
      'Say "translate photo" to translate the image',
    ],
    'voice_errors': [
      'Did you mean "start recording" or "record now"?',
      'Try saying "stop recording" to finish',
      'Say "play translation" to hear the result',
    ],
    'text_errors': [
      'Did you mean "translate text" or "translate this"?',
      'Try saying "clear text" to start over',
      'Say "copy translation" to copy the result',
    ],
    'navigation_errors': [
      'Did you mean "go to camera", "go to voice", or "go to text"?',
      'Try saying "go back" or "go home"',
      'Say "help" to hear all available commands',
    ],
  };

  /// Get all available commands for a specific page
  List<String> getPageCommands(String page) {
    final pageCommands = _pageCommands[page];
    if (pageCommands == null) return [];

    return pageCommands.values.expand((variations) => variations).toList();
  }

  /// Get command categories for a specific page
  Map<String, List<String>> getPageCommandCategories(String page) {
    return _pageCommands[page] ?? {};
  }

  /// Get help description for a specific command
  String? getCommandDescription(String page, String commandKey) {
    return _commandDescriptions[page]?[commandKey];
  }

  /// Get all command descriptions for a page
  Map<String, String> getPageDescriptions(String page) {
    return _commandDescriptions[page] ?? {};
  }

  /// Check if a command is valid for the current page
  bool isValidPageCommand(String page, String spokenText) {
    final pageCommands = _pageCommands[page];
    if (pageCommands == null) return false;

    final normalizedText = _normalizeText(spokenText);

    for (final variations in pageCommands.values) {
      for (final variation in variations) {
        if (_normalizeText(variation) == normalizedText) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get error suggestions for unrecognized commands
  List<String> getErrorSuggestions(String page, String spokenText) {
    // First, try to find similar commands on the current page
    final pageCommands = _pageCommands[page];
    if (pageCommands != null) {
      final suggestions = <String>[];

      for (final variations in pageCommands.values) {
        for (final variation in variations) {
          if (_calculateSimilarity(
                  _normalizeText(spokenText), _normalizeText(variation)) >
              0.4) {
            suggestions.add(variation);
          }
        }
      }

      if (suggestions.isNotEmpty) {
        return suggestions.take(3).toList();
      }
    }

    // Fall back to general error suggestions based on page type
    final errorType = _getErrorType(page);
    return _errorSuggestions[errorType] ??
        ['Say "help" to hear available commands'];
  }

  /// Generate helpful message listing available commands
  String generateHelpMessage(String page) {
    final pageCommands = _pageCommands[page];
    final descriptions = _commandDescriptions[page];

    if (pageCommands == null || descriptions == null) {
      return 'No specific commands available for this page. Use general navigation commands.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Available commands for this page:');

    for (final entry in pageCommands.entries) {
      final commandKey = entry.key;
      final variations = entry.value;
      final description = descriptions[commandKey];

      if (description != null && variations.isNotEmpty) {
        buffer.writeln('• ${variations.first}: $description');
      }
    }

    buffer.writeln(
        '\nYou can also use general navigation commands like "go back" or "go home".');

    return buffer.toString();
  }

  /// Find a matching page command
  PageCommandMatch? findPageCommand(String page, String spokenText) {
    if (!_pageCommands.containsKey(page)) return null;

    final normalizedSpoken = _normalizeText(spokenText);
    PageCommandMatch? bestMatch;
    double maxConfidence = 0.0;

    final categories = _pageCommands[page]!;
    for (var entry in categories.entries) {
      final key = entry.key;
      final variations = entry.value;

      for (var variation in variations) {
        final normalizedVariation = _normalizeText(variation);
        final similarity =
            _calculateSimilarity(normalizedSpoken, normalizedVariation);

        if (similarity > maxConfidence) {
          maxConfidence = similarity;
          bestMatch = PageCommandMatch(
              commandKey: key,
              matchedVariation: variation,
              confidence: similarity,
              page: page);
        }
      }
    }

    return bestMatch;
  }

  /// Create a voice command from page-specific input
  VoiceCommand? createPageCommand(String page, String spokenText) {
    final match = findPageCommand(page, spokenText);
    if (match == null || match.confidence < 0.6) return null;

    return VoiceCommand(
      originalText: spokenText,
      type: CommandType.control, // Page commands are control type
      parameters: {
        'page': page,
        'action': match.commandKey,
        'matchedVariation': match.matchedVariation,
      },
      confidence: match.confidence,
      timestamp: DateTime.now(),
    );
  }

  /// Get tutorial message for first-time users on a page
  String getTutorialMessage(String page) {
    switch (page) {
      case '/camera':
        return 'Welcome to camera translation! Say "take photo" to capture text, or "help" for more commands.';
      case '/voice':
        return 'Welcome to voice translation! Say "start recording" to begin, or "help" for more commands.';
      case '/text':
        return 'Welcome to text translation! Type your text or say "paste text", then say "translate" when ready.';
      case '/settings':
        return 'Welcome to settings! Say "accessibility settings" for voice options, or "help" for more commands.';
      default:
        return 'Welcome! Say "help" to hear available voice commands for this page.';
    }
  }

  /// Normalize text for comparison
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Calculate similarity between two strings
  double _calculateSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Exact match
    if (text1 == text2) return 1.0;

    // Contains match
    if (text1.contains(text2) || text2.contains(text1)) {
      final shorter = text1.length < text2.length ? text1 : text2;
      final longer = text1.length >= text2.length ? text1 : text2;
      return shorter.length / longer.length * 0.9;
    }

    // Word-based matching
    final words1 = text1.split(' ');
    final words2 = text2.split(' ');

    int matchingWords = 0;
    for (final word1 in words1) {
      if (words2.contains(word1)) {
        matchingWords++;
      }
    }

    if (matchingWords > 0) {
      return matchingWords /
          (words1.length > words2.length ? words1.length : words2.length) *
          0.8;
    }

    return 0.0;
  }

  /// Get error type based on page
  String _getErrorType(String page) {
    switch (page) {
      case '/camera':
        return 'camera_errors';
      case '/voice':
        return 'voice_errors';
      case '/text':
        return 'text_errors';
      default:
        return 'navigation_errors';
    }
  }
}

/// Result of page command matching
class PageCommandMatch {
  final String commandKey;
  final String matchedVariation;
  final double confidence;
  final String page;

  const PageCommandMatch({
    required this.commandKey,
    required this.matchedVariation,
    required this.confidence,
    required this.page,
  });

  @override
  String toString() {
    return 'PageCommandMatch(commandKey: $commandKey, matchedVariation: $matchedVariation, confidence: $confidence, page: $page)';
  }
}

/// Help system for voice commands
class VoiceCommandHelpSystem {
  final ContextAwareCommandManager _commandManager =
      ContextAwareCommandManager();

  /// Generate comprehensive help for a page
  String generatePageHelp(String page) {
    return _commandManager.generateHelpMessage(page);
  }

  /// Generate quick help with most common commands
  String generateQuickHelp(String page) {
    final pageCommands = _commandManager.getPageCommandCategories(page);

    if (pageCommands.isEmpty) {
      return 'Say "go to camera", "go to voice", or "go to text" to start translating.';
    }

    final topCommands = pageCommands.entries.take(3);
    final commandList =
        topCommands.map((entry) => entry.value.first).join(', ');

    return 'Quick commands: $commandList. Say "help" for more options.';
  }

  /// Generate tutorial for new users
  String generateTutorial(String page) {
    return _commandManager.getTutorialMessage(page);
  }

  /// Generate error help with suggestions
  String generateErrorHelp(String page, String spokenText) {
    final suggestions = _commandManager.getErrorSuggestions(page, spokenText);

    if (suggestions.isEmpty) {
      return 'Command not recognized. Say "help" to hear available commands.';
    }

    return 'Command not recognized. ${suggestions.join(' ')}';
  }
}
