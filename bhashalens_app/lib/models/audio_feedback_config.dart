import 'dart:convert';

/// Audio feedback configuration for TTS announcements
class AudioFeedbackConfig {
  final Map<String, String> pageAnnouncements;
  final Map<String, String> buttonDescriptions;
  final Map<String, String> errorMessages;
  final Map<String, String> successMessages;
  
  const AudioFeedbackConfig({
    required this.pageAnnouncements,
    required this.buttonDescriptions,
    required this.errorMessages,
    required this.successMessages,
  });
  
  /// Default configuration with predefined announcements
  static AudioFeedbackConfig get defaultConfig => const AudioFeedbackConfig(
    pageAnnouncements: {
      '/': 'Home page. Choose translation method: camera, voice, or text.',
      '/camera': 'Camera translation page. Point camera at text to translate.',
      '/voice': 'Voice translation page. Speak to translate your words.',
      '/text': 'Text translation page. Type text to translate.',
      '/settings': 'Settings page. Adjust app preferences and accessibility options.',
      '/history': 'Translation history page. View your saved translations.',
      '/emergency': 'Emergency page. Quick access to essential phrases.',
      '/help': 'Help and support page. Get assistance with using the app.',
    },
    buttonDescriptions: {
      'camera_capture': 'Take photo for translation',
      'voice_record': 'Start voice recording for translation',
      'text_translate': 'Translate entered text',
      'settings_accessibility': 'Open accessibility settings',
      'back_button': 'Go to previous page',
      'home_button': 'Go to home page',
      'history_button': 'View translation history',
      'emergency_button': 'Access emergency phrases',
      'help_button': 'Get help and support',
      'language_selector': 'Select translation language',
      'save_translation': 'Save this translation',
      'share_translation': 'Share this translation',
      'play_audio': 'Play audio of translation',
      'copy_text': 'Copy translation to clipboard',
    },
    errorMessages: {
      'no_internet': 'No internet connection. Please check your network and try again.',
      'translation_failed': 'Translation failed. Please try again.',
      'voice_recognition_failed': 'Could not understand speech. Please try speaking again.',
      'camera_permission_denied': 'Camera permission required for photo translation.',
      'microphone_permission_denied': 'Microphone permission required for voice translation.',
      'storage_permission_denied': 'Storage permission required to save translations.',
      'invalid_language': 'Selected language is not supported for this translation method.',
      'text_too_long': 'Text is too long. Please try with shorter text.',
      'no_text_detected': 'No text detected in the image. Please try with clearer text.',
      'service_unavailable': 'Translation service is temporarily unavailable.',
    },
    successMessages: {
      'translation_complete': 'Translation completed successfully.',
      'settings_saved': 'Settings saved successfully.',
      'voice_command_executed': 'Voice command executed.',
      'translation_saved': 'Translation saved to history.',
      'translation_shared': 'Translation shared successfully.',
      'text_copied': 'Translation copied to clipboard.',
      'audio_played': 'Audio playback started.',
      'language_changed': 'Translation language updated.',
      'permissions_granted': 'Permissions granted successfully.',
      'backup_created': 'Settings backup created.',
    },
  );
  
  /// Create a copy with modified values
  AudioFeedbackConfig copyWith({
    Map<String, String>? pageAnnouncements,
    Map<String, String>? buttonDescriptions,
    Map<String, String>? errorMessages,
    Map<String, String>? successMessages,
  }) {
    return AudioFeedbackConfig(
      pageAnnouncements: pageAnnouncements ?? this.pageAnnouncements,
      buttonDescriptions: buttonDescriptions ?? this.buttonDescriptions,
      errorMessages: errorMessages ?? this.errorMessages,
      successMessages: successMessages ?? this.successMessages,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'pageAnnouncements': pageAnnouncements,
      'buttonDescriptions': buttonDescriptions,
      'errorMessages': errorMessages,
      'successMessages': successMessages,
    };
  }
  
  /// Create from JSON map
  factory AudioFeedbackConfig.fromMap(Map<String, dynamic> map) {
    return AudioFeedbackConfig(
      pageAnnouncements: Map<String, String>.from(map['pageAnnouncements'] ?? {}),
      buttonDescriptions: Map<String, String>.from(map['buttonDescriptions'] ?? {}),
      errorMessages: Map<String, String>.from(map['errorMessages'] ?? {}),
      successMessages: Map<String, String>.from(map['successMessages'] ?? {}),
    );
  }
  
  /// Convert to JSON string
  String toJson() => json.encode(toMap());
  
  /// Create from JSON string
  factory AudioFeedbackConfig.fromJson(String source) => 
      AudioFeedbackConfig.fromMap(json.decode(source));
  
  /// Get page announcement for a route
  String? getPageAnnouncement(String route) {
    return pageAnnouncements[route];
  }
  
  /// Get button description for a button ID
  String? getButtonDescription(String buttonId) {
    return buttonDescriptions[buttonId];
  }
  
  /// Get error message for an error type
  String? getErrorMessage(String errorType) {
    return errorMessages[errorType];
  }
  
  /// Get success message for a success type
  String? getSuccessMessage(String successType) {
    return successMessages[successType];
  }
  
  @override
  String toString() {
    return 'AudioFeedbackConfig('
        'pageAnnouncements: ${pageAnnouncements.length} entries, '
        'buttonDescriptions: ${buttonDescriptions.length} entries, '
        'errorMessages: ${errorMessages.length} entries, '
        'successMessages: ${successMessages.length} entries'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AudioFeedbackConfig &&
        _mapEquals(other.pageAnnouncements, pageAnnouncements) &&
        _mapEquals(other.buttonDescriptions, buttonDescriptions) &&
        _mapEquals(other.errorMessages, errorMessages) &&
        _mapEquals(other.successMessages, successMessages);
  }
  
  @override
  int get hashCode {
    return pageAnnouncements.hashCode ^
        buttonDescriptions.hashCode ^
        errorMessages.hashCode ^
        successMessages.hashCode;
  }
  
  /// Helper method to compare maps
  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Audio cue types for different interactions
enum AudioCueType {
  navigation,
  success,
  error,
  buttonPress,
  focus,
  warning,
  information,
}

/// Audio cue configuration
class AudioCue {
  final AudioCueType type;
  final String soundPath;
  final double volume;
  final int duration;
  
  const AudioCue({
    required this.type,
    required this.soundPath,
    this.volume = 1.0,
    this.duration = 500,
  });
  
  /// Predefined audio cues
  static const AudioCue navigationSound = AudioCue(
    type: AudioCueType.navigation,
    soundPath: 'navigation_beep',
    volume: 0.8,
    duration: 300,
  );
  
  static const AudioCue successChime = AudioCue(
    type: AudioCueType.success,
    soundPath: 'success_chime',
    volume: 0.9,
    duration: 600,
  );
  
  static const AudioCue errorBeep = AudioCue(
    type: AudioCueType.error,
    soundPath: 'error_beep',
    volume: 1.0,
    duration: 400,
  );
  
  static const AudioCue clickSound = AudioCue(
    type: AudioCueType.buttonPress,
    soundPath: 'click_sound',
    volume: 0.7,
    duration: 200,
  );
  
  static const AudioCue focusSound = AudioCue(
    type: AudioCueType.focus,
    soundPath: 'focus_sound',
    volume: 0.6,
    duration: 250,
  );
  
  @override
  String toString() {
    return 'AudioCue('
        'type: $type, '
        'soundPath: $soundPath, '
        'volume: $volume, '
        'duration: $duration'
        ')';
  }
}