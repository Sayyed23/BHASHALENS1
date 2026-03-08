# Encrypted Local Storage Implementation

## Overview

This implementation provides a secure, encrypted local storage layer for BhashaLens using SQLCipher with AES-256 encryption and Flutter Secure Storage for key management.

## Architecture

### Components

1. **EncryptedLocalStorage** (`lib/services/encrypted_local_storage.dart`)
   - Main service class providing encrypted database operations
   - Uses SQLCipher for AES-256 encrypted SQLite database
   - Manages encryption keys via Flutter Secure Storage (Android Keystore)

2. **Data Models**
   - `TranslationHistoryEntry` - Translation history records
   - `CachedTranslation` - Cached translation results
   - `ConversationMessage` - LLM conversation history
   - Supporting enums: `Language`, `TranslationMode`, `ProcessingBackend`, `MessageRole`

### Database Schema

The encrypted database includes five tables:

#### 1. translation_history
Stores user translation history with metadata.
```sql
CREATE TABLE translation_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_text TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  source_lang TEXT NOT NULL,
  target_lang TEXT NOT NULL,
  mode TEXT NOT NULL,
  backend TEXT NOT NULL,
  confidence REAL,
  timestamp INTEGER NOT NULL,
  is_favorite INTEGER DEFAULT 0
)
```

#### 2. user_preferences
Stores user preferences and settings.
```sql
CREATE TABLE user_preferences (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)
```

#### 3. translation_cache
Caches translation results for offline access.
```sql
CREATE TABLE translation_cache (
  source_text TEXT NOT NULL,
  source_lang TEXT NOT NULL,
  target_lang TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  confidence REAL,
  cached_at INTEGER NOT NULL,
  PRIMARY KEY (source_text, source_lang, target_lang)
)
```

#### 4. conversation_history
Stores LLM conversation history for context.
```sql
CREATE TABLE conversation_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  language TEXT NOT NULL,
  timestamp INTEGER NOT NULL
)
```

#### 5. language_pack_metadata
Tracks installed language pack metadata.
```sql
CREATE TABLE language_pack_metadata (
  language_pair TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  installed_at INTEGER NOT NULL,
  last_used INTEGER
)
```

### Indexes

Performance indexes are created for:
- `translation_history.timestamp DESC` - Fast history retrieval
- `conversation_history(session_id, timestamp)` - Fast conversation lookup

## Security Features

### Encryption

1. **AES-256 Encryption**: All data at rest is encrypted using SQLCipher with AES-256
2. **Secure Key Storage**: Encryption keys are stored in Flutter Secure Storage, which uses:
   - **Android**: Android Keystore System (hardware-backed when available)
   - **iOS**: Keychain Services
   - **Other platforms**: Platform-specific secure storage

3. **Key Generation**: 256-bit encryption keys are generated on first use and stored securely

### Privacy Compliance

- **No Voice Recording Storage**: Raw voice data is NOT stored (Requirement 9.3)
- **Permanent Deletion**: Data deletion is permanent and complete (Requirement 9.4)
- **User Control**: Users can clear all data via `clearAllData()` method (Requirement 9.5)

## API Reference

### Translation History

```dart
// Save a translation
await storage.saveTranslation(TranslationHistoryEntry(...));

// Get history (newest first, paginated)
final history = await storage.getTranslationHistory(limit: 100, offset: 0);

// Search history
final results = await storage.searchTranslationHistory('query');

// Delete old history
await storage.deleteTranslationHistory(beforeTimestamp: timestamp);
```

### User Preferences

```dart
// Save preference
await storage.savePreference('key', 'value');

// Get preference
final value = await storage.getPreference('key');
```

### Translation Cache

```dart
// Cache translation
await storage.cacheTranslation(
  sourceText: 'Hello',
  sourceLang: Language.english,
  targetLang: Language.hindi,
  translatedText: 'नमस्ते',
  confidence: 0.95,
);

// Get cached translation
final cached = await storage.getCachedTranslation(
  sourceText: 'Hello',
  sourceLang: Language.english,
  targetLang: Language.hindi,
);
```

### Conversation History

```dart
// Save message
await storage.saveConversationMessage(ConversationMessage(...));

// Get conversation history
final messages = await storage.getConversationHistory(
  sessionId: 'session_id',
  limit: 10,
);
```

### Language Pack Metadata

```dart
// Save metadata
await storage.saveLanguagePackMetadata(
  languagePair: 'en-hi',
  version: '1.0.0',
  sizeBytes: 25000000,
  installedAt: DateTime.now().millisecondsSinceEpoch,
);

// Get metadata
final metadata = await storage.getLanguagePackMetadata('en-hi');

// Get all packs
final allPacks = await storage.getAllLanguagePacks();
```

### Data Management

```dart
// Clear all data
await storage.clearAllData();

// Close database
await storage.close();
```

## Requirements Validation

This implementation satisfies the following requirements:

- **9.1**: SQLite database with encryption ✓
- **9.2**: AES-256 encryption for all persistent data ✓
- **9.3**: No permanent storage of raw voice recordings ✓
- **9.4**: Permanent data deletion capability ✓
- **9.5**: User option to clear all local data ✓
- **9.6**: Secure key storage using Android Keystore ✓
- **9.7**: Data removal on app uninstall (handled by OS) ✓
- **15.6**: Translation history ordered by timestamp descending ✓

## Dependencies

```yaml
dependencies:
  sqflite_sqlcipher: ^3.1.1  # Encrypted SQLite
  flutter_secure_storage: ^9.0.0  # Secure key storage
  path: ^1.8.3  # Path utilities
```

## Platform Support

- ✅ Android (primary target)
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux
- ❌ Web (SQLCipher not supported, gracefully handled)

## Usage Example

See `lib/services/encrypted_local_storage_example.dart` for comprehensive usage examples.

## Testing

To test the encrypted storage:

1. **Unit Tests**: Test individual methods with mock data
2. **Integration Tests**: Test complete workflows
3. **Security Tests**: Verify encryption and key storage
4. **Performance Tests**: Benchmark query performance

## Migration from Existing Storage

If migrating from the existing `LocalStorageService`:

1. Export data from old database
2. Transform to new schema format
3. Import into encrypted database
4. Verify data integrity
5. Delete old database

## Troubleshooting

### Database Not Opening
- Check if encryption key is accessible in secure storage
- Verify SQLCipher is properly installed
- Check platform compatibility

### Performance Issues
- Ensure indexes are created
- Use pagination for large datasets
- Consider cache cleanup for old data

### Key Management Issues
- Verify Flutter Secure Storage permissions
- Check platform-specific keystore access
- Ensure app has proper security permissions

## Future Enhancements

1. **Automatic Cache Cleanup**: Implement TTL for cached translations
2. **Data Compression**: Compress large text fields
3. **Backup/Restore**: Export/import encrypted backups
4. **Multi-User Support**: Separate databases per user
5. **Cloud Sync**: Sync encrypted data to cloud storage

## References

- [SQLCipher Documentation](https://www.zetetic.net/sqlcipher/)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Android Keystore System](https://developer.android.com/training/articles/keystore)
- BhashaLens Design Document: `.kiro/specs/bhashalens-production-ready/design.md`
- BhashaLens Requirements: `.kiro/specs/bhashalens-production-ready/requirements.md`
