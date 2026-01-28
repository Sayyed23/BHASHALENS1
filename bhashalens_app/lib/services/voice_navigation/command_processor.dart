import 'dart:math';
import '../../models/voice_command.dart';

/// Voice command processor that handles recognition and fuzzy matching
class CommandProcessor {
  // Command variations mapping for natural language processing
  final Map<String, List<String>> _commandVariations = {
    'navigate_camera': [
      'go to camera',
      'camera translation',
      'open camera',
      'camera mode',
      'take photo',
      'photo translation',
      'camera translate',
      'picture translate',
    ],
    'navigate_voice': [
      'go to voice',
      'voice translation',
      'speak to translate',
      'voice mode',
      'talk to translate',
      'speech translation',
      'voice translate',
      'speak translate',
    ],
    'navigate_text': [
      'go to text',
      'text translation',
      'type to translate',
      'text mode',
      'typing mode',
      'text translate',
      'type translate',
      'keyboard translate',
    ],
    'navigate_settings': [
      'go to settings',
      'open settings',
      'preferences',
      'settings menu',
      'app settings',
      'configuration',
      'options',
    ],
    'navigate_back': [
      'go back',
      'previous',
      'return',
      'back',
      'go previous',
      'previous page',
      'back button',
    ],
    'navigate_home': [
      'go home',
      'main menu',
      'home screen',
      'home page',
      'main page',
      'start page',
      'homepage',
    ],
    'start_translation': [
      'translate this',
      'start translation',
      'translate',
      'begin translation',
      'translate now',
      'do translation',
    ],
    'show_help': [
      'help',
      'what can I say',
      'voice commands',
      'commands',
      'help me',
      'show commands',
      'available commands',
      'what commands',
    ],
    'repeat_last': [
      'repeat',
      'say that again',
      'repeat last',
      'say again',
      'repeat message',
      'what did you say',
    ],
    'stop_voice_control': [
      'stop voice control',
      'turn off voice',
      'disable voice',
      'stop listening',
      'voice off',
      'stop voice navigation',
    ],
  };

  // Page-specific commands mapping
  final Map<String, List<String>> _pageSpecificCommands = {
    '/camera': [
      'take photo',
      'capture image',
      'snap picture',
      'take picture',
      'capture',
      'shoot',
    ],
    '/voice': [
      'start recording',
      'begin recording',
      'record voice',
      'start speaking',
      'speak now',
      'record',
    ],
    '/text': [
      'clear text',
      'delete text',
      'paste text',
      'copy text',
      'select all',
    ],
    '/settings': [
      'accessibility settings',
      'voice settings',
      'audio settings',
      'visual settings',
      'theme settings',
    ],
  };

  // Confidence threshold for command recognition
  static const double _confidenceThreshold = 0.6;

  /// Process spoken text and return a voice command if recognized
  VoiceCommand? processSpokenText(String spokenText) {
    if (spokenText.trim().isEmpty) return null;

    final normalizedText = _normalizeText(spokenText);
    final bestMatch = _findBestMatch(normalizedText);

    if (bestMatch == null || bestMatch.confidence < _confidenceThreshold) {
      return null;
    }

    return VoiceCommand(
      originalText: spokenText,
      type: _getCommandType(bestMatch.commandKey),
      parameters: {
        'action': bestMatch.commandKey,
        'matchedVariation': bestMatch.matchedText,
      },
      confidence: bestMatch.confidence,
      timestamp: DateTime.now(),
    );
  }

  /// Get contextual commands for a specific page
  List<String> getContextualCommands(String currentPage) {
    final globalCommands = _commandVariations.values
        .expand((variations) => variations)
        .toList();
    
    final pageCommands = _pageSpecificCommands[currentPage] ?? [];
    
    return [...globalCommands, ...pageCommands];
  }

  /// Get available command categories for help system
  Map<String, List<String>> getCommandCategories() {
    return Map.from(_commandVariations);
  }

  /// Get page-specific commands for help system
  Map<String, List<String>> getPageSpecificCommands() {
    return Map.from(_pageSpecificCommands);
  }

  /// Suggest similar commands for unrecognized input
  List<String> suggestSimilarCommands(String spokenText, {int maxSuggestions = 3}) {
    final normalizedText = _normalizeText(spokenText);
    final suggestions = <_CommandMatch>[];

    // Check all command variations for partial matches
    for (final entry in _commandVariations.entries) {
      for (final variation in entry.value) {
        final similarity = _calculateSimilarity(normalizedText, variation);
        if (similarity > 0.3) { // Lower threshold for suggestions
          suggestions.add(_CommandMatch(
            commandKey: entry.key,
            matchedText: variation,
            confidence: similarity,
          ));
        }
      }
    }

    // Sort by confidence and return top suggestions
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions
        .take(maxSuggestions)
        .map((match) => match.matchedText)
        .toList();
  }

  /// Check if a command is valid for the current page context
  bool isValidForContext(String commandKey, String currentPage) {
    // Global commands are always valid
    if (_commandVariations.containsKey(commandKey)) {
      return true;
    }

    // Check page-specific commands
    final pageCommands = _pageSpecificCommands[currentPage] ?? [];
    return pageCommands.any((cmd) => 
        _normalizeText(cmd) == _normalizeText(commandKey));
  }

  /// Normalize text for better matching
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Find the best matching command for the input text
  _CommandMatch? _findBestMatch(String normalizedText) {
    _CommandMatch? bestMatch;
    double highestConfidence = 0.0;

    for (final entry in _commandVariations.entries) {
      for (final variation in entry.value) {
        final confidence = _calculateSimilarity(normalizedText, variation);
        if (confidence > highestConfidence) {
          highestConfidence = confidence;
          bestMatch = _CommandMatch(
            commandKey: entry.key,
            matchedText: variation,
            confidence: confidence,
          );
        }
      }
    }

    return bestMatch;
  }

  /// Calculate similarity between two strings using fuzzy matching
  double _calculateSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Exact match gets highest score
    if (text1 == text2) return 1.0;

    // Contains match gets high score
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
      return (matchingWords / max(words1.length, words2.length)) * 0.8;
    }

    // Levenshtein distance for character-level similarity
    return _levenshteinSimilarity(text1, text2);
  }

  /// Calculate similarity using Levenshtein distance
  double _levenshteinSimilarity(String s1, String s2) {
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = max(s1.length, s2.length);
    if (maxLength == 0) return 1.0;
    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    // Fill the matrix
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Get command type based on command key
  CommandType _getCommandType(String commandKey) {
    if (commandKey.startsWith('navigate_')) {
      return CommandType.navigation;
    } else if (commandKey.startsWith('start_')) {
      return CommandType.translation;
    } else if (commandKey.contains('settings')) {
      return CommandType.settings;
    } else if (commandKey.contains('help')) {
      return CommandType.help;
    } else {
      return CommandType.control;
    }
  }
}

/// Internal class for command matching results
class _CommandMatch {
  final String commandKey;
  final String matchedText;
  final double confidence;

  const _CommandMatch({
    required this.commandKey,
    required this.matchedText,
    required this.confidence,
  });

  @override
  String toString() {
    return '_CommandMatch(commandKey: $commandKey, matchedText: $matchedText, confidence: $confidence)';
  }
}