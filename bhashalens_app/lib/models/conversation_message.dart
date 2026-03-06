import 'package:bhashalens_app/models/language_pair.dart';


/// Data model for conversation history messages
class ConversationMessage {
  final int? id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final Language language;
  final int timestamp;

  ConversationMessage({
    this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.language,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role.name,
      'content': content,
      'language': language.name,
      'timestamp': timestamp,
    };
  }

  factory ConversationMessage.fromMap(Map<String, dynamic> map) {
    return ConversationMessage(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      content: map['content'] as String,
      language: Language.values.firstWhere(
        (e) => e.name == map['language'],
        orElse: () => Language.english,
      ),
      timestamp: map['timestamp'] as int,
    );
  }
}

enum MessageRole {
  user,
  assistant,
}
