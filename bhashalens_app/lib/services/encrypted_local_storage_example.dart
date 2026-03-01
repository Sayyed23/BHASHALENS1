/// Example usage of EncryptedLocalStorage
/// 
/// This file demonstrates how to use the encrypted local storage service
/// for storing translation history, preferences, cached translations, and
/// conversation history with AES-256 encryption.

import 'encrypted_local_storage.dart';
import '../models/translation_history_entry.dart';
import '../models/cached_translation.dart';
import '../models/conversation_message.dart';

/// Example: Save and retrieve translation history
Future<void> exampleTranslationHistory() async {
  final storage = EncryptedLocalStorage();

  // Save a translation
  final translation = TranslationHistoryEntry(
    sourceText: 'Hello',
    translatedText: 'नमस्ते',
    sourceLang: Language.english,
    targetLang: Language.hindi,
    mode: TranslationMode.text,
    backend: ProcessingBackend.onDevice,
    confidence: 0.95,
    timestamp: DateTime.now().millisecondsSinceEpoch,
    isFavorite: false,
  );
  await storage.saveTranslation(translation);

  // Get translation history (newest first)
  final history = await storage.getTranslationHistory(limit: 50);
  print('Found ${history.length} translations');

  // Search translation history
  final searchResults = await storage.searchTranslationHistory('Hello');
  print('Found ${searchResults.length} matching translations');

  // Delete old translations (older than 30 days)
  final thirtyDaysAgo = DateTime.now()
      .subtract(const Duration(days: 30))
      .millisecondsSinceEpoch;
  await storage.deleteTranslationHistory(beforeTimestamp: thirtyDaysAgo);
}

/// Example: Save and retrieve user preferences
Future<void> exampleUserPreferences() async {
  final storage = EncryptedLocalStorage();

  // Save preferences
  await storage.savePreference('default_source_lang', 'english');
  await storage.savePreference('default_target_lang', 'hindi');
  await storage.savePreference('offline_mode', 'true');

  // Get preferences
  final sourceLang = await storage.getPreference('default_source_lang');
  final targetLang = await storage.getPreference('default_target_lang');
  final offlineMode = await storage.getPreference('offline_mode');

  print('Source: $sourceLang, Target: $targetLang, Offline: $offlineMode');
}

/// Example: Cache and retrieve translations
Future<void> exampleTranslationCache() async {
  final storage = EncryptedLocalStorage();

  // Cache a translation
  await storage.cacheTranslation(
    sourceText: 'Good morning',
    sourceLang: Language.english,
    targetLang: Language.hindi,
    translatedText: 'सुप्रभात',
    confidence: 0.98,
  );

  // Retrieve cached translation
  final cached = await storage.getCachedTranslation(
    sourceText: 'Good morning',
    sourceLang: Language.english,
    targetLang: Language.hindi,
  );

  if (cached != null) {
    print('Cached translation: ${cached.translatedText}');
    print('Confidence: ${cached.confidence}');
    print('Cached at: ${DateTime.fromMillisecondsSinceEpoch(cached.cachedAt)}');
  }
}

/// Example: Save and retrieve conversation history
Future<void> exampleConversationHistory() async {
  final storage = EncryptedLocalStorage();
  final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

  // Save conversation messages
  await storage.saveConversationMessage(
    ConversationMessage(
      sessionId: sessionId,
      role: MessageRole.user,
      content: 'How do you say hello in Hindi?',
      language: Language.english,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  );

  await storage.saveConversationMessage(
    ConversationMessage(
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: 'In Hindi, you say "नमस्ते" (Namaste) for hello.',
      language: Language.english,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  );

  // Retrieve conversation history
  final conversation = await storage.getConversationHistory(
    sessionId: sessionId,
    limit: 10,
  );

  print('Conversation has ${conversation.length} messages');
  for (final message in conversation) {
    print('${message.role.name}: ${message.content}');
  }
}

/// Example: Manage language pack metadata
Future<void> exampleLanguagePackMetadata() async {
  final storage = EncryptedLocalStorage();

  // Save language pack metadata
  await storage.saveLanguagePackMetadata(
    languagePair: 'en-hi',
    version: '1.0.0',
    sizeBytes: 25 * 1024 * 1024, // 25 MB
    installedAt: DateTime.now().millisecondsSinceEpoch,
  );

  // Get language pack metadata
  final metadata = await storage.getLanguagePackMetadata('en-hi');
  if (metadata != null) {
    print('Language pack: ${metadata['language_pair']}');
    print('Version: ${metadata['version']}');
    print('Size: ${metadata['size_bytes'] / (1024 * 1024)} MB');
  }

  // Get all installed language packs
  final allPacks = await storage.getAllLanguagePacks();
  print('Installed language packs: ${allPacks.length}');
}

/// Example: Clear all data (for privacy/security)
Future<void> exampleClearAllData() async {
  final storage = EncryptedLocalStorage();

  // Clear all data from the database
  await storage.clearAllData();
  print('All data cleared');
}

/// Example: Complete workflow
Future<void> exampleCompleteWorkflow() async {
  final storage = EncryptedLocalStorage();

  // 1. Check if user has set preferences
  final sourceLang = await storage.getPreference('default_source_lang');
  if (sourceLang == null) {
    // First time user, set defaults
    await storage.savePreference('default_source_lang', 'english');
    await storage.savePreference('default_target_lang', 'hindi');
  }

  // 2. Check cache before translating
  final cached = await storage.getCachedTranslation(
    sourceText: 'Hello',
    sourceLang: Language.english,
    targetLang: Language.hindi,
  );

  if (cached != null) {
    print('Using cached translation: ${cached.translatedText}');
  } else {
    // 3. Perform translation (simulated)
    const translatedText = 'नमस्ते';

    // 4. Cache the result
    await storage.cacheTranslation(
      sourceText: 'Hello',
      sourceLang: Language.english,
      targetLang: Language.hindi,
      translatedText: translatedText,
      confidence: 0.95,
    );

    // 5. Save to history
    await storage.saveTranslation(
      TranslationHistoryEntry(
        sourceText: 'Hello',
        translatedText: translatedText,
        sourceLang: Language.english,
        targetLang: Language.hindi,
        mode: TranslationMode.text,
        backend: ProcessingBackend.onDevice,
        confidence: 0.95,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    print('Translation completed and saved');
  }

  // 6. Get recent history
  final history = await storage.getTranslationHistory(limit: 10);
  print('Recent translations: ${history.length}');
}
