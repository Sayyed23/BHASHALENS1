import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/voice_command.dart';
import 'command_processor.dart';
import 'context_aware_commands.dart';

/// Abstract interface for voice navigation service
abstract class VoiceNavigationService {
  // Voice command processing
  Stream<VoiceCommand> get commandStream;
  bool get isListening;
  bool get isEnabled;
  
  // Voice navigation control
  Future<void> startListening();
  Future<void> stopListening();
  Future<void> enableVoiceNavigation();
  Future<void> disableVoiceNavigation();
  
  // Navigation commands
  Future<VoiceCommandResult> executeNavigationCommand(VoiceCommand command);
  Future<VoiceCommandResult> executePageSpecificCommand(VoiceCommand command, String currentPage);
  
  // Command feedback and help
  Future<void> provideCommandFeedback(String message);
  Future<void> listAvailableCommands(String context);
  List<String> getContextualCommands(String currentPage);
  List<String> suggestSimilarCommands(String spokenText);
  
  // Settings and configuration
  Future<void> setLanguage(String languageCode);
  Future<void> setTimeout(double timeoutSeconds);
  String get currentLanguage;
  double get timeoutDuration;
}

/// Voice navigation service implementation
class VoiceNavigationController extends ChangeNotifier implements VoiceNavigationService {
  final SpeechToText _speechToText = SpeechToText();
  final CommandProcessor _commandProcessor = CommandProcessor();
  final ContextAwareCommandManager _contextManager = ContextAwareCommandManager();
  final VoiceCommandHelpSystem _helpSystem = VoiceCommandHelpSystem();
  final StreamController<VoiceCommand> _commandStreamController = StreamController<VoiceCommand>.broadcast();
  
  // Navigation callback - will be set by the app
  Function(NavigationAction, Map<String, dynamic>)? _navigationCallback;
  
  // Audio feedback callback - will be set by the app
  Function(String, {String? language})? _audioFeedbackCallback;
  
  // State management
  bool _isListening = false;
  bool _isEnabled = false;
  bool _isInitialized = false;
  String _currentLanguage = 'en-US';
  double _timeoutDuration = 3.0;
  String _currentPage = '/';
  String _lastAudioMessage = '';
  Timer? _timeoutTimer;
  
  // Error handling
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;
  
  @override
  Stream<VoiceCommand> get commandStream => _commandStreamController.stream;
  
  @override
  bool get isListening => _isListening;
  
  @override
  bool get isEnabled => _isEnabled;
  
  @override
  String get currentLanguage => _currentLanguage;
  
  @override
  double get timeoutDuration => _timeoutDuration;

  /// Set navigation callback for executing navigation actions
  void setNavigationCallback(Function(NavigationAction, Map<String, dynamic>) callback) {
    _navigationCallback = callback;
  }

  /// Set audio feedback callback for providing voice feedback
  void setAudioFeedbackCallback(Function(String, {String? language}) callback) {
    _audioFeedbackCallback = callback;
  }

  /// Set current page for context-aware commands
  void setCurrentPage(String page) {
    _currentPage = page;
  }

  @override
  Future<void> enableVoiceNavigation() async {
    try {
      if (!_isInitialized) {
        final available = await _speechToText.initialize(
          onError: _handleSpeechError,
          onStatus: _handleSpeechStatus,
        );
        
        if (!available) {
          throw Exception('Speech recognition not available on this device');
        }
        
        _isInitialized = true;
      }
      
      _isEnabled = true;
      _consecutiveErrors = 0;
      await provideCommandFeedback('Voice navigation enabled. Say "help" to hear available commands.');
      notifyListeners();
    } catch (e) {
      debugPrint('Error enabling voice navigation: $e');
      await provideCommandFeedback('Failed to enable voice navigation. Please check your microphone permissions.');
      rethrow;
    }
  }

  @override
  Future<void> disableVoiceNavigation() async {
    _isEnabled = false;
    if (_isListening) {
      await stopListening();
    }
    await provideCommandFeedback('Voice navigation disabled.');
    notifyListeners();
  }

  @override
  Future<void> startListening() async {
    if (!_isEnabled || !_isInitialized) {
      throw Exception('Voice navigation not enabled or initialized');
    }

    if (_isListening) {
      return; // Already listening
    }

    try {
      final available = await _speechToText.listen(
        onResult: _handleSpeechResult,
        listenFor: Duration(seconds: _timeoutDuration.toInt()),
        pauseFor: Duration(seconds: (_timeoutDuration / 2).toInt()),
        partialResults: false,
        localeId: _currentLanguage,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      if (available) {
        _isListening = true;
        _startTimeoutTimer();
        notifyListeners();
      } else {
        throw Exception('Failed to start speech recognition');
      }
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      await _handleError('Failed to start listening. Please try again.');
      rethrow;
    }
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _cancelTimeoutTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  @override
  Future<VoiceCommandResult> executeNavigationCommand(VoiceCommand command) async {
    final startTime = DateTime.now();
    
    try {
      final action = _getNavigationAction(command.parameters['action'] as String);
      if (action == null) {
        return VoiceCommandResult.failure(
          command: command,
          errorMessage: 'Unknown navigation command',
          executionTime: DateTime.now().difference(startTime).inMilliseconds,
        );
      }

      // Execute navigation through callback
      if (_navigationCallback != null) {
        _navigationCallback!(action, command.parameters);
        
        // Provide audio feedback
        final actionDescription = _getActionDescription(action);
        await provideCommandFeedback(actionDescription);
        
        _consecutiveErrors = 0; // Reset error count on success
        
        return VoiceCommandResult.success(
          command: command,
          action: action,
          executionTime: DateTime.now().difference(startTime).inMilliseconds,
        );
      } else {
        return VoiceCommandResult.failure(
          command: command,
          errorMessage: 'Navigation callback not set',
          executionTime: DateTime.now().difference(startTime).inMilliseconds,
        );
      }
    } catch (e) {
      debugPrint('Error executing navigation command: $e');
      await _handleError('Failed to execute command: ${command.originalText}');
      
      return VoiceCommandResult.failure(
        command: command,
        errorMessage: e.toString(),
        executionTime: DateTime.now().difference(startTime).inMilliseconds,
      );
    }
  }

  @override
  Future<VoiceCommandResult> executePageSpecificCommand(VoiceCommand command, String currentPage) async {
    final startTime = DateTime.now();
    
    try {
      // Handle page-specific commands based on current page
      final success = await _handlePageSpecificCommand(command, currentPage);
      
      if (success) {
        await provideCommandFeedback('Command executed successfully');
        return VoiceCommandResult.success(
          command: command,
          executionTime: DateTime.now().difference(startTime).inMilliseconds,
        );
      } else {
        return VoiceCommandResult.failure(
          command: command,
          errorMessage: 'Page-specific command not supported on this page',
          executionTime: DateTime.now().difference(startTime).inMilliseconds,
        );
      }
    } catch (e) {
      debugPrint('Error executing page-specific command: $e');
      await _handleError('Failed to execute page command: ${command.originalText}');
      
      return VoiceCommandResult.failure(
        command: command,
        errorMessage: e.toString(),
        executionTime: DateTime.now().difference(startTime).inMilliseconds,
      );
    }
  }

  @override
  Future<void> provideCommandFeedback(String message) async {
    _lastAudioMessage = message;
    if (_audioFeedbackCallback != null) {
      await _audioFeedbackCallback!(message, language: _currentLanguage);
    } else {
      debugPrint('Audio feedback: $message');
    }
  }

  @override
  Future<void> listAvailableCommands(String context) async {
    // Use the help system to generate contextual help
    final helpMessage = _helpSystem.generatePageHelp(context);
    await provideCommandFeedback(helpMessage);
  }

  @override
  List<String> getContextualCommands(String currentPage) {
    final globalCommands = _commandProcessor.getContextualCommands(currentPage);
    final pageCommands = _contextManager.getPageCommands(currentPage);
    return [...globalCommands, ...pageCommands];
  }

  @override
  List<String> suggestSimilarCommands(String spokenText) {
    // First try global command suggestions
    final globalSuggestions = _commandProcessor.suggestSimilarCommands(spokenText);
    
    // Then try page-specific suggestions
    final pageSuggestions = _contextManager.getErrorSuggestions(_currentPage, spokenText);
    
    // Combine and deduplicate
    final allSuggestions = [...globalSuggestions, ...pageSuggestions];
    return allSuggestions.toSet().take(3).toList();
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    
    // Restart listening if currently active to apply new language
    if (_isListening) {
      await stopListening();
      await startListening();
    }
    
    await provideCommandFeedback('Voice language changed to $_currentLanguage');
    notifyListeners();
  }

  @override
  Future<void> setTimeout(double timeoutSeconds) async {
    _timeoutDuration = timeoutSeconds.clamp(1.0, 10.0); // Reasonable bounds
    await provideCommandFeedback('Voice timeout set to ${_timeoutDuration.toInt()} seconds');
    notifyListeners();
  }

  /// Handle speech recognition results
  void _handleSpeechResult(result) {
    if (!result.finalResult) return;
    
    final spokenText = result.recognizedWords as String;
    debugPrint('Speech recognized: $spokenText');
    
    // Process the command
    final command = _commandProcessor.processSpokenText(spokenText);
    
    if (command != null) {
      _commandStreamController.add(command);
      _processCommand(command);
    } else {
      _handleUnrecognizedCommand(spokenText);
    }
    
    // Stop listening after processing
    stopListening();
  }

  /// Handle speech recognition errors
  void _handleSpeechError(error) {
    debugPrint('Speech recognition error: $error');
    _isListening = false;
    _cancelTimeoutTimer();
    notifyListeners();
    
    _handleError('Speech recognition error. Please try again.');
  }

  /// Handle speech recognition status changes
  void _handleSpeechStatus(String status) {
    debugPrint('Speech recognition status: $status');
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _cancelTimeoutTimer();
      notifyListeners();
    }
  }

  /// Process recognized voice command
  Future<void> _processCommand(VoiceCommand command) async {
    try {
      VoiceCommandResult result;
      
      if (command.type == CommandType.navigation) {
        result = await executeNavigationCommand(command);
      } else if (command.type == CommandType.help) {
        await _handleHelpCommand(command);
        return;
      } else if (command.type == CommandType.control) {
        await _handleControlCommand(command);
        return;
      } else {
        result = await executePageSpecificCommand(command, _currentPage);
      }
      
      if (!result.success) {
        await _handleError(result.errorMessage ?? 'Command execution failed');
      }
    } catch (e) {
      debugPrint('Error processing command: $e');
      await _handleError('Failed to process voice command');
    }
  }

  /// Handle unrecognized voice commands with context-aware suggestions
  Future<void> _handleUnrecognizedCommand(String spokenText) async {
    // Try to find page-specific command first
    final pageCommand = _contextManager.createPageCommand(_currentPage, spokenText);
    if (pageCommand != null) {
      _commandStreamController.add(pageCommand);
      await _processCommand(pageCommand);
      return;
    }
    
    // Generate contextual error message with suggestions
    final errorMessage = _helpSystem.generateErrorHelp(_currentPage, spokenText);
    await provideCommandFeedback(errorMessage);
  }

  /// Handle help commands
  Future<void> _handleHelpCommand(VoiceCommand command) async {
    final action = command.parameters['action'] as String;
    
    if (action == 'show_help') {
      await listAvailableCommands(_currentPage);
    } else if (action == 'repeat_last') {
      if (_lastAudioMessage.isNotEmpty) {
        await provideCommandFeedback(_lastAudioMessage);
      } else {
        await provideCommandFeedback('No previous message to repeat');
      }
    }
  }

  /// Handle control commands
  Future<void> _handleControlCommand(VoiceCommand command) async {
    final action = command.parameters['action'] as String;
    
    if (action == 'stop_voice_control') {
      await disableVoiceNavigation();
    }
  }

  /// Handle page-specific commands with context awareness
  Future<bool> _handlePageSpecificCommand(VoiceCommand command, String currentPage) async {
    final action = command.parameters['action'] as String?;
    if (action == null) return false;
    
    // Handle page-specific commands based on current page and action
    switch (currentPage) {
      case '/camera':
        return await _handleCameraCommands(action, command.parameters);
      case '/voice':
        return await _handleVoiceCommands(action, command.parameters);
      case '/text':
        return await _handleTextCommands(action, command.parameters);
      case '/settings':
        return await _handleSettingsCommands(action, command.parameters);
      case '/history':
        return await _handleHistoryCommands(action, command.parameters);
      case '/emergency':
        return await _handleEmergencyCommands(action, command.parameters);
      default:
        return false;
    }
  }

  /// Handle camera page specific commands
  Future<bool> _handleCameraCommands(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'take_photo':
        await provideCommandFeedback('Taking photo for translation');
        // Trigger camera capture through callback
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'capture'});
        }
        return true;
      case 'switch_camera':
        await provideCommandFeedback('Switching camera');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'switch_camera'});
        }
        return true;
      case 'flash_toggle':
        await provideCommandFeedback('Toggling camera flash');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'toggle_flash'});
        }
        return true;
      case 'translate_photo':
        await provideCommandFeedback('Translating photo');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'translate'});
        }
        return true;
      default:
        return false;
    }
  }

  /// Handle voice page specific commands
  Future<bool> _handleVoiceCommands(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'start_recording':
        await provideCommandFeedback('Starting voice recording');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'start_recording'});
        }
        return true;
      case 'stop_recording':
        await provideCommandFeedback('Stopping recording');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'stop_recording'});
        }
        return true;
      case 'play_translation':
        await provideCommandFeedback('Playing translation');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'play_audio'});
        }
        return true;
      case 'clear_recording':
        await provideCommandFeedback('Clearing recording');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'clear'});
        }
        return true;
      default:
        return false;
    }
  }

  /// Handle text page specific commands
  Future<bool> _handleTextCommands(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'clear_text':
        await provideCommandFeedback('Clearing text');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'clear_text'});
        }
        return true;
      case 'paste_text':
        await provideCommandFeedback('Pasting text');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'paste'});
        }
        return true;
      case 'translate_text':
        await provideCommandFeedback('Translating text');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'translate'});
        }
        return true;
      case 'copy_translation':
        await provideCommandFeedback('Copying translation');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'copy'});
        }
        return true;
      default:
        return false;
    }
  }

  /// Handle settings page specific commands
  Future<bool> _handleSettingsCommands(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'accessibility_settings':
        await provideCommandFeedback('Opening accessibility settings');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.settings, {'section': 'accessibility'});
        }
        return true;
      case 'language_settings':
        await provideCommandFeedback('Opening language settings');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.settings, {'section': 'languages'});
        }
        return true;
      case 'theme_settings':
        await provideCommandFeedback('Opening theme settings');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.settings, {'section': 'theme'});
        }
        return true;
      default:
        return false;
    }
  }

  /// Handle history page specific commands
  Future<bool> _handleHistoryCommands(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'clear_history':
        await provideCommandFeedback('Clearing translation history');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'clear_history'});
        }
        return true;
      case 'search_history':
        await provideCommandFeedback('Searching translation history');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'search'});
        }
        return true;
      default:
        return false;
    }
  }

  /// Handle emergency page specific commands
  Future<bool> _handleEmergencyCommands(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'medical_help':
        await provideCommandFeedback('Showing medical emergency phrases');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'medical'});
        }
        return true;
      case 'police_help':
        await provideCommandFeedback('Showing police emergency phrases');
        if (_navigationCallback != null) {
          _navigationCallback!(NavigationAction.startTranslation, {'action': 'police'});
        }
        return true;
      default:
        return false;
    }
  }

  /// Provide tutorial for new users on page entry
  Future<void> provideTutorial(String page) async {
    final tutorialMessage = _helpSystem.generateTutorial(page);
    await provideCommandFeedback(tutorialMessage);
  }

  /// Provide quick help for experienced users
  Future<void> provideQuickHelp(String page) async {
    final quickHelp = _helpSystem.generateQuickHelp(page);
    await provideCommandFeedback(quickHelp);
  }

  /// Get navigation action from command key
  NavigationAction? _getNavigationAction(String commandKey) {
    switch (commandKey) {
      case 'navigate_camera':
        return NavigationAction.cameraTranslation;
      case 'navigate_voice':
        return NavigationAction.voiceTranslation;
      case 'navigate_text':
        return NavigationAction.textTranslation;
      case 'navigate_settings':
        return NavigationAction.settings;
      case 'navigate_back':
        return NavigationAction.back;
      case 'navigate_home':
        return NavigationAction.home;
      case 'start_translation':
        return NavigationAction.startTranslation;
      default:
        return null;
    }
  }

  /// Get description for navigation action
  String _getActionDescription(NavigationAction action) {
    switch (action) {
      case NavigationAction.cameraTranslation:
        return 'Opening camera translation';
      case NavigationAction.voiceTranslation:
        return 'Opening voice translation';
      case NavigationAction.textTranslation:
        return 'Opening text translation';
      case NavigationAction.settings:
        return 'Opening settings';
      case NavigationAction.back:
        return 'Going back';
      case NavigationAction.home:
        return 'Going to home page';
      case NavigationAction.startTranslation:
        return 'Starting translation';
      default:
        return 'Command executed';
    }
  }

  /// Start timeout timer for voice recognition
  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(Duration(seconds: _timeoutDuration.toInt()), () {
      if (_isListening) {
        stopListening();
        provideCommandFeedback('Voice command timeout. Please try again.');
      }
    });
  }

  /// Cancel timeout timer
  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Handle errors with consecutive error tracking
  Future<void> _handleError(String message) async {
    _consecutiveErrors++;
    
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      await provideCommandFeedback('Multiple voice recognition errors. Voice navigation will be disabled temporarily.');
      await disableVoiceNavigation();
      _consecutiveErrors = 0;
    } else {
      await provideCommandFeedback(message);
    }
  }

  @override
  void dispose() {
    _commandStreamController.close();
    _cancelTimeoutTimer();
    if (_isListening) {
      _speechToText.stop();
    }
    super.dispose();
  }
}