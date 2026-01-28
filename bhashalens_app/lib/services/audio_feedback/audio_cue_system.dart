import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../models/audio_feedback_config.dart';
import 'audio_feedback_service.dart';

/// Audio cue generator for creating system sounds
class AudioCueGenerator {
  static const double _baseFrequency = 440.0; // A4 note
  
  /// Generate a simple beep tone
  static List<int> generateBeep({
    double frequency = _baseFrequency,
    int durationMs = 200,
    double volume = 0.5,
    int sampleRate = 44100,
  }) {
    final samples = (sampleRate * durationMs / 1000).round();
    final data = <int>[];
    
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      final sample = (sin(2 * pi * frequency * t) * volume * 32767).round();
      data.add(sample);
    }
    
    return data;
  }
  
  /// Generate a success chime (ascending notes)
  static List<int> generateSuccessChime({
    int durationMs = 600,
    double volume = 0.7,
    int sampleRate = 44100,
  }) {
    final frequencies = [_baseFrequency, _baseFrequency * 1.25, _baseFrequency * 1.5]; // C-E-G chord
    final noteDuration = durationMs ~/ frequencies.length;
    final data = <int>[];
    
    for (final frequency in frequencies) {
      final noteData = generateBeep(
        frequency: frequency,
        durationMs: noteDuration,
        volume: volume,
        sampleRate: sampleRate,
      );
      data.addAll(noteData);
    }
    
    return data;
  }
  
  /// Generate an error beep (descending notes)
  static List<int> generateErrorBeep({
    int durationMs = 400,
    double volume = 0.8,
    int sampleRate = 44100,
  }) {
    final frequencies = [_baseFrequency * 1.5, _baseFrequency]; // High to low
    final noteDuration = durationMs ~/ frequencies.length;
    final data = <int>[];
    
    for (final frequency in frequencies) {
      final noteData = generateBeep(
        frequency: frequency,
        durationMs: noteDuration,
        volume: volume,
        sampleRate: sampleRate,
      );
      data.addAll(noteData);
    }
    
    return data;
  }
  
  /// Generate a navigation click sound
  static List<int> generateClickSound({
    int durationMs = 100,
    double volume = 0.6,
    int sampleRate = 44100,
  }) {
    return generateBeep(
      frequency: _baseFrequency * 2,
      durationMs: durationMs,
      volume: volume,
      sampleRate: sampleRate,
    );
  }
  
  /// Generate a focus sound (soft tone)
  static List<int> generateFocusSound({
    int durationMs = 150,
    double volume = 0.4,
    int sampleRate = 44100,
  }) {
    return generateBeep(
      frequency: _baseFrequency * 0.75,
      durationMs: durationMs,
      volume: volume,
      sampleRate: sampleRate,
    );
  }
}

/// Audio cue player interface
abstract class AudioCuePlayer {
  /// Play an audio cue
  Future<void> playCue(AudioCueType cueType);
  
  /// Play a custom audio cue
  Future<void> playCustomCue(AudioCue cue);
  
  /// Set volume for audio cues
  Future<void> setVolume(double volume);
  
  /// Check if audio cues are enabled
  bool get isEnabled;
  
  /// Enable or disable audio cues
  void setEnabled(bool enabled);
}

/// System audio cue player using platform channels
class SystemAudioCuePlayer implements AudioCuePlayer {
  static const MethodChannel _channel = MethodChannel('bhashalens/audio_cues');
  
  bool _isEnabled = true;
  double _volume = 1.0;
  
  @override
  bool get isEnabled => _isEnabled;
  
  @override
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
  }
  
  @override
  Future<void> playCue(AudioCueType cueType) async {
    if (!_isEnabled) return;
    
    try {
      await _channel.invokeMethod('playCue', {
        'type': cueType.toString(),
        'volume': _volume,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play audio cue: $e');
      }
    }
  }
  
  @override
  Future<void> playCustomCue(AudioCue cue) async {
    if (!_isEnabled) return;
    
    try {
      await _channel.invokeMethod('playCustomCue', {
        'soundPath': cue.soundPath,
        'volume': cue.volume * _volume,
        'duration': cue.duration,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play custom audio cue: $e');
      }
    }
  }
}

/// Fallback audio cue player using system sounds
class FallbackAudioCuePlayer implements AudioCuePlayer {
  bool _isEnabled = true;
  double _volume = 1.0;
  
  @override
  bool get isEnabled => _isEnabled;
  
  @override
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
  }
  
  @override
  Future<void> playCue(AudioCueType cueType) async {
    if (!_isEnabled) return;
    
    try {
      // Use system feedback for basic audio cues
      switch (cueType) {
        case AudioCueType.buttonPress:
        case AudioCueType.navigation:
          await SystemSound.play(SystemSoundType.click);
          break;
        case AudioCueType.success:
          // No direct system sound for success, use click as fallback
          await SystemSound.play(SystemSoundType.click);
          break;
        case AudioCueType.error:
          await SystemSound.play(SystemSoundType.alert);
          break;
        case AudioCueType.focus:
          // Soft click for focus
          await SystemSound.play(SystemSoundType.click);
          break;
        case AudioCueType.warning:
          await SystemSound.play(SystemSoundType.alert);
          break;
        case AudioCueType.information:
          await SystemSound.play(SystemSoundType.click);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play system sound: $e');
      }
    }
  }
  
  @override
  Future<void> playCustomCue(AudioCue cue) async {
    // Fallback to type-based cue
    await playCue(cue.type);
  }
}

/// Enhanced audio feedback service with audio cue support
class AudioCueSystem {
  final AudioFeedbackService _audioFeedbackService;
  final AudioCuePlayer _cuePlayer;
  final Map<AudioCueType, AudioCue> _cueMap;
  
  bool _backgroundTtsEnabled = false;
  Timer? _backgroundNotificationTimer;
  final List<String> _backgroundNotifications = [];
  
  AudioCueSystem({
    required AudioFeedbackService audioFeedbackService,
    AudioCuePlayer? cuePlayer,
    Map<AudioCueType, AudioCue>? customCues,
  }) : _audioFeedbackService = audioFeedbackService,
       _cuePlayer = cuePlayer ?? FallbackAudioCuePlayer(),
       _cueMap = customCues ?? _defaultCueMap;
  
  /// Default audio cue mapping
  static final Map<AudioCueType, AudioCue> _defaultCueMap = {
    AudioCueType.navigation: AudioCue.navigationSound,
    AudioCueType.success: AudioCue.successChime,
    AudioCueType.error: AudioCue.errorBeep,
    AudioCueType.buttonPress: AudioCue.clickSound,
    AudioCueType.focus: AudioCue.focusSound,
    AudioCueType.warning: const AudioCue(
      type: AudioCueType.warning,
      soundPath: 'warning_beep',
      volume: 0.9,
      duration: 350,
    ),
    AudioCueType.information: const AudioCue(
      type: AudioCueType.information,
      soundPath: 'info_chime',
      volume: 0.7,
      duration: 300,
    ),
  };
  
  /// Initialize the audio cue system
  Future<void> initialize() async {
    _startBackgroundNotificationTimer();
    
    if (kDebugMode) {
      print('AudioCueSystem initialized');
    }
  }
  
  /// Dispose the audio cue system
  Future<void> dispose() async {
    _backgroundNotificationTimer?.cancel();
    
    if (kDebugMode) {
      print('AudioCueSystem disposed');
    }
  }
  
  /// Enable or disable background TTS notifications
  void setBackgroundTtsEnabled(bool enabled) {
    _backgroundTtsEnabled = enabled;
    
    if (!enabled) {
      _backgroundNotifications.clear();
    }
    
    if (kDebugMode) {
      print('Background TTS ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Play audio cue for interaction type
  Future<void> playInteractionCue(AudioCueType cueType) async {
    try {
      await _cuePlayer.playCue(cueType);
      
      if (kDebugMode) {
        print('Played audio cue: $cueType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play interaction cue: $e');
      }
    }
  }
  
  /// Play audio cue and provide TTS feedback
  Future<void> playInteractionWithFeedback(
    AudioCueType cueType,
    String feedbackText, {
    FeedbackPriority priority = FeedbackPriority.normal,
  }) async {
    // Play audio cue first
    await playInteractionCue(cueType);
    
    // Then provide TTS feedback
    await _audioFeedbackService.speak(
      feedbackText,
      priority: priority,
    );
  }
  
  /// Handle navigation with audio cue and announcement
  Future<void> handleNavigation(String destination, {String? description}) async {
    await playInteractionCue(AudioCueType.navigation);
    await _audioFeedbackService.announcePageChange(destination, description: description);
  }
  
  /// Handle button press with audio cue and announcement
  Future<void> handleButtonPress(String buttonId, {String? customDescription}) async {
    await playInteractionCue(AudioCueType.buttonPress);
    await _audioFeedbackService.announceButtonAction(buttonId, customDescription: customDescription);
  }
  
  /// Handle success action with audio cue and announcement
  Future<void> handleSuccess(String successType, {String? customMessage}) async {
    await playInteractionCue(AudioCueType.success);
    await _audioFeedbackService.announceSuccess(successType, customMessage: customMessage);
  }
  
  /// Handle error with audio cue and announcement
  Future<void> handleError(String errorType, {String? customMessage}) async {
    await playInteractionCue(AudioCueType.error);
    await _audioFeedbackService.announceError(errorType, customMessage: customMessage);
  }
  
  /// Handle focus change with audio cue
  Future<void> handleFocusChange(String elementDescription) async {
    await playInteractionCue(AudioCueType.focus);
    await _audioFeedbackService.announceUIElement(
      elementDescription,
      priority: FeedbackPriority.low,
    );
  }
  
  /// Handle translation completion with audio cue and announcement
  Future<void> handleTranslationComplete(
    String originalText,
    String translatedText, {
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    await playInteractionCue(AudioCueType.success);
    await _audioFeedbackService.announceTranslation(
      originalText,
      translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }
  
  /// Add background notification for later announcement
  void addBackgroundNotification(String notification) {
    if (!_backgroundTtsEnabled) return;
    
    _backgroundNotifications.add(notification);
    
    // Limit background notifications to prevent memory issues
    if (_backgroundNotifications.length > 10) {
      _backgroundNotifications.removeAt(0);
    }
    
    if (kDebugMode) {
      print('Added background notification: $notification');
    }
  }
  
  /// Announce pending background notifications
  Future<void> announceBackgroundNotifications() async {
    if (!_backgroundTtsEnabled || _backgroundNotifications.isEmpty) return;
    
    final notifications = List<String>.from(_backgroundNotifications);
    _backgroundNotifications.clear();
    
    for (final notification in notifications) {
      await _audioFeedbackService.announceSystemMessage(
        notification,
        priority: FeedbackPriority.low,
      );
      
      // Small delay between notifications
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
  
  /// Set audio cue volume
  Future<void> setCueVolume(double volume) async {
    await _cuePlayer.setVolume(volume);
  }
  
  /// Enable or disable audio cues
  void setAudioCuesEnabled(bool enabled) {
    _cuePlayer.setEnabled(enabled);
  }
  
  /// Check if audio cues are enabled
  bool get areAudioCuesEnabled => _cuePlayer.isEnabled;
  
  /// Get current background notification count
  int get backgroundNotificationCount => _backgroundNotifications.length;
  
  /// Coordinate with voice navigation to avoid conflicts
  Future<void> coordinateWithVoiceNavigation(bool voiceNavigationActive) async {
    if (voiceNavigationActive) {
      // Reduce audio cue volume when voice navigation is active
      await setCueVolume(0.3);
      
      // Pause TTS if it's currently speaking
      if (_audioFeedbackService.isSpeaking) {
        await _audioFeedbackService.pauseSpeech();
      }
    } else {
      // Restore normal audio cue volume
      await setCueVolume(1.0);
      
      // Resume TTS if it was paused
      await _audioFeedbackService.resumeSpeech();
    }
    
    if (kDebugMode) {
      print('Audio cue coordination: voice navigation ${voiceNavigationActive ? 'active' : 'inactive'}');
    }
  }
  
  /// Start background notification timer
  void _startBackgroundNotificationTimer() {
    _backgroundNotificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (_backgroundTtsEnabled && _backgroundNotifications.isNotEmpty) {
          announceBackgroundNotifications();
        }
      },
    );
  }
  
  /// Create audio cue system with default configuration
  static AudioCueSystem createDefault(AudioFeedbackService audioFeedbackService) {
    return AudioCueSystem(
      audioFeedbackService: audioFeedbackService,
      cuePlayer: FallbackAudioCuePlayer(),
    );
  }
  
  /// Create audio cue system with system audio support
  static AudioCueSystem createWithSystemAudio(AudioFeedbackService audioFeedbackService) {
    return AudioCueSystem(
      audioFeedbackService: audioFeedbackService,
      cuePlayer: SystemAudioCuePlayer(),
    );
  }
}

/// Audio cue system factory
class AudioCueSystemFactory {
  static AudioCueSystem create({
    required AudioFeedbackService audioFeedbackService,
    bool useSystemAudio = false,
    Map<AudioCueType, AudioCue>? customCues,
  }) {
    final cuePlayer = useSystemAudio 
        ? SystemAudioCuePlayer() 
        : FallbackAudioCuePlayer();
    
    return AudioCueSystem(
      audioFeedbackService: audioFeedbackService,
      cuePlayer: cuePlayer,
      customCues: customCues,
    );
  }
}