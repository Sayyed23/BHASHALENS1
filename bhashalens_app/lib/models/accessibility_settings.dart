import 'dart:convert';

/// Comprehensive accessibility settings model
class AccessibilitySettings {
  // Voice navigation settings
  final bool voiceNavigationEnabled;
  final String voiceNavigationLanguage;
  final double voiceCommandTimeout;
  
  // Audio feedback settings
  final bool audioFeedbackEnabled;
  final double speechRate;
  final double speechPitch;
  final String preferredVoice;
  final bool autoReadTranslations;
  final bool autoReadErrors;
  
  // Visual accessibility settings
  final bool highContrastEnabled;
  final double textScale;
  final bool boldTextEnabled;
  final bool simplifiedUIEnabled;
  final bool focusIndicatorsEnabled;
  final bool colorBlindSupportEnabled;
  final bool reducedMotionEnabled;
  final double touchTargetSize;
  
  const AccessibilitySettings({
    this.voiceNavigationEnabled = false,
    this.voiceNavigationLanguage = 'en-US',
    this.voiceCommandTimeout = 3.0,
    this.audioFeedbackEnabled = false,
    this.speechRate = 1.0,
    this.speechPitch = 1.0,
    this.preferredVoice = 'default',
    this.autoReadTranslations = true,
    this.autoReadErrors = true,
    this.highContrastEnabled = false,
    this.textScale = 1.0,
    this.boldTextEnabled = false,
    this.simplifiedUIEnabled = false,
    this.focusIndicatorsEnabled = false,
    this.colorBlindSupportEnabled = false,
    this.reducedMotionEnabled = false,
    this.touchTargetSize = 48.0,
  });
  
  /// Create a copy with modified values
  AccessibilitySettings copyWith({
    bool? voiceNavigationEnabled,
    String? voiceNavigationLanguage,
    double? voiceCommandTimeout,
    bool? audioFeedbackEnabled,
    double? speechRate,
    double? speechPitch,
    String? preferredVoice,
    bool? autoReadTranslations,
    bool? autoReadErrors,
    bool? highContrastEnabled,
    double? textScale,
    bool? boldTextEnabled,
    bool? simplifiedUIEnabled,
    bool? focusIndicatorsEnabled,
    bool? colorBlindSupportEnabled,
    bool? reducedMotionEnabled,
    double? touchTargetSize,
  }) {
    return AccessibilitySettings(
      voiceNavigationEnabled: voiceNavigationEnabled ?? this.voiceNavigationEnabled,
      voiceNavigationLanguage: voiceNavigationLanguage ?? this.voiceNavigationLanguage,
      voiceCommandTimeout: voiceCommandTimeout ?? this.voiceCommandTimeout,
      audioFeedbackEnabled: audioFeedbackEnabled ?? this.audioFeedbackEnabled,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      preferredVoice: preferredVoice ?? this.preferredVoice,
      autoReadTranslations: autoReadTranslations ?? this.autoReadTranslations,
      autoReadErrors: autoReadErrors ?? this.autoReadErrors,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      textScale: textScale ?? this.textScale,
      boldTextEnabled: boldTextEnabled ?? this.boldTextEnabled,
      simplifiedUIEnabled: simplifiedUIEnabled ?? this.simplifiedUIEnabled,
      focusIndicatorsEnabled: focusIndicatorsEnabled ?? this.focusIndicatorsEnabled,
      colorBlindSupportEnabled: colorBlindSupportEnabled ?? this.colorBlindSupportEnabled,
      reducedMotionEnabled: reducedMotionEnabled ?? this.reducedMotionEnabled,
      touchTargetSize: touchTargetSize ?? this.touchTargetSize,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'voiceNavigationEnabled': voiceNavigationEnabled,
      'voiceNavigationLanguage': voiceNavigationLanguage,
      'voiceCommandTimeout': voiceCommandTimeout,
      'audioFeedbackEnabled': audioFeedbackEnabled,
      'speechRate': speechRate,
      'speechPitch': speechPitch,
      'preferredVoice': preferredVoice,
      'autoReadTranslations': autoReadTranslations,
      'autoReadErrors': autoReadErrors,
      'highContrastEnabled': highContrastEnabled,
      'textScale': textScale,
      'boldTextEnabled': boldTextEnabled,
      'simplifiedUIEnabled': simplifiedUIEnabled,
      'focusIndicatorsEnabled': focusIndicatorsEnabled,
      'colorBlindSupportEnabled': colorBlindSupportEnabled,
      'reducedMotionEnabled': reducedMotionEnabled,
      'touchTargetSize': touchTargetSize,
    };
  }
  
  /// Create from JSON map
  factory AccessibilitySettings.fromMap(Map<String, dynamic> map) {
    return AccessibilitySettings(
      voiceNavigationEnabled: map['voiceNavigationEnabled'] ?? false,
      voiceNavigationLanguage: map['voiceNavigationLanguage'] ?? 'en-US',
      voiceCommandTimeout: (map['voiceCommandTimeout'] ?? 3.0).toDouble(),
      audioFeedbackEnabled: map['audioFeedbackEnabled'] ?? false,
      speechRate: (map['speechRate'] ?? 1.0).toDouble(),
      speechPitch: (map['speechPitch'] ?? 1.0).toDouble(),
      preferredVoice: map['preferredVoice'] ?? 'default',
      autoReadTranslations: map['autoReadTranslations'] ?? true,
      autoReadErrors: map['autoReadErrors'] ?? true,
      highContrastEnabled: map['highContrastEnabled'] ?? false,
      textScale: (map['textScale'] ?? 1.0).toDouble(),
      boldTextEnabled: map['boldTextEnabled'] ?? false,
      simplifiedUIEnabled: map['simplifiedUIEnabled'] ?? false,
      focusIndicatorsEnabled: map['focusIndicatorsEnabled'] ?? false,
      colorBlindSupportEnabled: map['colorBlindSupportEnabled'] ?? false,
      reducedMotionEnabled: map['reducedMotionEnabled'] ?? false,
      touchTargetSize: (map['touchTargetSize'] ?? 48.0).toDouble(),
    );
  }
  
  /// Convert to JSON string
  String toJson() => json.encode(toMap());
  
  /// Create from JSON string
  factory AccessibilitySettings.fromJson(String source) => 
      AccessibilitySettings.fromMap(json.decode(source));
  
  @override
  String toString() {
    return 'AccessibilitySettings('
        'voiceNavigationEnabled: $voiceNavigationEnabled, '
        'voiceNavigationLanguage: $voiceNavigationLanguage, '
        'voiceCommandTimeout: $voiceCommandTimeout, '
        'audioFeedbackEnabled: $audioFeedbackEnabled, '
        'speechRate: $speechRate, '
        'speechPitch: $speechPitch, '
        'preferredVoice: $preferredVoice, '
        'autoReadTranslations: $autoReadTranslations, '
        'autoReadErrors: $autoReadErrors, '
        'highContrastEnabled: $highContrastEnabled, '
        'textScale: $textScale, '
        'boldTextEnabled: $boldTextEnabled, '
        'simplifiedUIEnabled: $simplifiedUIEnabled, '
        'focusIndicatorsEnabled: $focusIndicatorsEnabled, '
        'colorBlindSupportEnabled: $colorBlindSupportEnabled, '
        'reducedMotionEnabled: $reducedMotionEnabled, '
        'touchTargetSize: $touchTargetSize'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AccessibilitySettings &&
        other.voiceNavigationEnabled == voiceNavigationEnabled &&
        other.voiceNavigationLanguage == voiceNavigationLanguage &&
        other.voiceCommandTimeout == voiceCommandTimeout &&
        other.audioFeedbackEnabled == audioFeedbackEnabled &&
        other.speechRate == speechRate &&
        other.speechPitch == speechPitch &&
        other.preferredVoice == preferredVoice &&
        other.autoReadTranslations == autoReadTranslations &&
        other.autoReadErrors == autoReadErrors &&
        other.highContrastEnabled == highContrastEnabled &&
        other.textScale == textScale &&
        other.boldTextEnabled == boldTextEnabled &&
        other.simplifiedUIEnabled == simplifiedUIEnabled &&
        other.focusIndicatorsEnabled == focusIndicatorsEnabled &&
        other.colorBlindSupportEnabled == colorBlindSupportEnabled &&
        other.reducedMotionEnabled == reducedMotionEnabled &&
        other.touchTargetSize == touchTargetSize;
  }
  
  @override
  int get hashCode {
    return voiceNavigationEnabled.hashCode ^
        voiceNavigationLanguage.hashCode ^
        voiceCommandTimeout.hashCode ^
        audioFeedbackEnabled.hashCode ^
        speechRate.hashCode ^
        speechPitch.hashCode ^
        preferredVoice.hashCode ^
        autoReadTranslations.hashCode ^
        autoReadErrors.hashCode ^
        highContrastEnabled.hashCode ^
        textScale.hashCode ^
        boldTextEnabled.hashCode ^
        simplifiedUIEnabled.hashCode ^
        focusIndicatorsEnabled.hashCode ^
        colorBlindSupportEnabled.hashCode ^
        reducedMotionEnabled.hashCode ^
        touchTargetSize.hashCode;
  }
}