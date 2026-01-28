import 'dart:convert';

/// Enumeration of voice command types
enum CommandType {
  navigation,
  translation,
  settings,
  help,
  control,
}

/// Voice command model for processing spoken commands
class VoiceCommand {
  final String originalText;
  final CommandType type;
  final Map<String, dynamic> parameters;
  final double confidence;
  final DateTime timestamp;
  
  const VoiceCommand({
    required this.originalText,
    required this.type,
    required this.parameters,
    required this.confidence,
    required this.timestamp,
  });
  
  /// Create a copy with modified values
  VoiceCommand copyWith({
    String? originalText,
    CommandType? type,
    Map<String, dynamic>? parameters,
    double? confidence,
    DateTime? timestamp,
  }) {
    return VoiceCommand(
      originalText: originalText ?? this.originalText,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'originalText': originalText,
      'type': type.name,
      'parameters': parameters,
      'confidence': confidence,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  /// Create from JSON map
  factory VoiceCommand.fromMap(Map<String, dynamic> map) {
    return VoiceCommand(
      originalText: map['originalText'] ?? '',
      type: CommandType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CommandType.control,
      ),
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
  
  /// Convert to JSON string
  String toJson() => json.encode(toMap());
  
  /// Create from JSON string
  factory VoiceCommand.fromJson(String source) => 
      VoiceCommand.fromMap(json.decode(source));
  
  @override
  String toString() {
    return 'VoiceCommand('
        'originalText: $originalText, '
        'type: $type, '
        'parameters: $parameters, '
        'confidence: $confidence, '
        'timestamp: $timestamp'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VoiceCommand &&
        other.originalText == originalText &&
        other.type == type &&
        _mapEquals(other.parameters, parameters) &&
        other.confidence == confidence &&
        other.timestamp == timestamp;
  }
  
  @override
  int get hashCode {
    return originalText.hashCode ^
        type.hashCode ^
        parameters.hashCode ^
        confidence.hashCode ^
        timestamp.hashCode;
  }
  
  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Navigation action enumeration for voice commands
enum NavigationAction {
  cameraTranslation,
  voiceTranslation,
  textTranslation,
  settings,
  back,
  home,
  startTranslation,
  showHelp,
  repeat,
}

/// Voice command result after processing
class VoiceCommandResult {
  final VoiceCommand command;
  final NavigationAction? action;
  final bool success;
  final String? errorMessage;
  final int executionTime;
  
  const VoiceCommandResult({
    required this.command,
    this.action,
    required this.success,
    this.errorMessage,
    required this.executionTime,
  });
  
  /// Create a successful result
  factory VoiceCommandResult.success({
    required VoiceCommand command,
    NavigationAction? action,
    required int executionTime,
  }) {
    return VoiceCommandResult(
      command: command,
      action: action,
      success: true,
      executionTime: executionTime,
    );
  }
  
  /// Create a failed result
  factory VoiceCommandResult.failure({
    required VoiceCommand command,
    required String errorMessage,
    required int executionTime,
  }) {
    return VoiceCommandResult(
      command: command,
      success: false,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }
  
  @override
  String toString() {
    return 'VoiceCommandResult('
        'command: $command, '
        'action: $action, '
        'success: $success, '
        'errorMessage: $errorMessage, '
        'executionTime: $executionTime'
        ')';
  }
}