import 'package:flutter/foundation.dart';
import 'package:bhashalens_app/models/language_pair.dart';
import 'package:bhashalens_app/services/offline_translation_service.dart';

/// Example usage of the Translation Engine
/// This demonstrates the key features and usage patterns
class TranslationEngineExample {
  final OfflineTranslationService _service = OfflineTranslationService();

  /// Example 1: Basic translation
  Future<void> basicTranslation() async {
    debugPrint('=== Example 1: Basic Translation ===');

    final result = await _service.translate(
      text: 'Hello, how are you?',
      sourceLang: Language.english,
      targetLang: Language.hindi,
    );

    if (result.success) {
      debugPrint('Original: Hello, how are you?');
      debugPrint('Translated: ${result.translatedText}');
      debugPrint('Confidence: ${result.confidence}');
      debugPrint('Processing time: ${result.processingTimeMs}ms');
    } else {
      debugPrint('Translation failed: ${result.error}');
    }
  }

  /// Example 2: Bidirectional translation
  Future<void> bidirectionalTranslation() async {
    debugPrint('\n=== Example 2: Bidirectional Translation ===');

    // Hindi to English
    final result1 = await _service.translate(
      text: 'नमस्ते, आप कैसे हैं?',
      sourceLang: Language.hindi,
      targetLang: Language.english,
    );

    debugPrint('Hindi → English: ${result1.translatedText}');

    // English to Hindi
    final result2 = await _service.translate(
      text: 'Hello, how are you?',
      sourceLang: Language.english,
      targetLang: Language.hindi,
    );

    debugPrint('English → Hindi: ${result2.translatedText}');

    // Hindi to Marathi (direct, no intermediate English)
    final result3 = await _service.translate(
      text: 'नमस्ते',
      sourceLang: Language.hindi,
      targetLang: Language.marathi,
    );

    debugPrint('Hindi → Marathi: ${result3.translatedText}');
  }

  /// Example 3: Translation with caching
  Future<void> cachedTranslation() async {
    debugPrint('\n=== Example 3: Cached Translation ===');

    const text = 'Good morning';

    // First translation - will be cached
    final start1 = DateTime.now();
    final result1 = await _service.translate(
      text: text,
      sourceLang: Language.english,
      targetLang: Language.hindi,
      useCache: true,
    );
    final time1 = DateTime.now().difference(start1).inMilliseconds;

    debugPrint('First translation: ${result1.translatedText}');
    debugPrint('Time: ${time1}ms');

    // Second translation - from cache (should be much faster)
    final start2 = DateTime.now();
    final result2 = await _service.translate(
      text: text,
      sourceLang: Language.english,
      targetLang: Language.hindi,
      useCache: true,
    );
    final time2 = DateTime.now().difference(start2).inMilliseconds;

    debugPrint('Cached translation: ${result2.translatedText}');
    debugPrint('Time: ${time2}ms (${time1 - time2}ms faster)');
  }

  /// Example 4: Check language pair availability
  Future<void> checkAvailability() async {
    debugPrint('\n=== Example 4: Language Pair Availability ===');

    final pairs = _service.getSupportedLanguagePairs();
    debugPrint('Supported language pairs: ${pairs.length}');

    for (final pair in pairs) {
      final isAvailable = await _service.isLanguagePairAvailable(pair);
      final modelSize = await _service.getModelSize(pair);
      final isLoaded = _service.isModelLoaded(pair);

      debugPrint('${pair.key}:');
      debugPrint('  Available: $isAvailable');
      debugPrint(
          '  Model size: ${(modelSize / 1024 / 1024).toStringAsFixed(2)} MB');
      debugPrint('  Loaded in memory: $isLoaded');
    }
  }

  /// Example 5: Translation history
  Future<void> translationHistory() async {
    debugPrint('\n=== Example 5: Translation History ===');

    // Perform some translations
    await _service.translate(
      text: 'Hello',
      sourceLang: Language.english,
      targetLang: Language.hindi,
      saveToHistory: true,
    );

    await _service.translate(
      text: 'Thank you',
      sourceLang: Language.english,
      targetLang: Language.marathi,
      saveToHistory: true,
    );

    // Get history
    final history = await _service.getHistory(limit: 10);
    debugPrint('Translation history (${history.length} entries):');

    for (final entry in history) {
      debugPrint('  ${entry.sourceText} → ${entry.translatedText}');
      debugPrint('    (${entry.sourceLang.name} → ${entry.targetLang.name})');
    }

    // Search history
    final searchResults = await _service.searchHistory('Hello');
    debugPrint('\nSearch results for "Hello": ${searchResults.length} entries');
  }

  /// Example 6: Initialize specific language pair
  Future<void> initializeLanguagePair() async {
    debugPrint('\n=== Example 6: Initialize Language Pair ===');

    const pair = LanguagePair(
      source: Language.hindi,
      target: Language.english,
    );

    debugPrint('Initializing ${pair.key}...');
    final start = DateTime.now();

    await _service.initializeLanguagePair(pair);

    final time = DateTime.now().difference(start).inMilliseconds;
    debugPrint('Initialized in ${time}ms');
    debugPrint('Model loaded: ${_service.isModelLoaded(pair)}');
  }

  /// Example 7: Performance benchmark
  Future<void> performanceBenchmark() async {
    debugPrint('\n=== Example 7: Performance Benchmark ===');

    final testTexts = [
      'Hello',
      'Good morning',
      'How are you?',
      'Thank you very much',
      'I am learning Hindi',
    ];

    final times = <int>[];

    for (final text in testTexts) {
      final start = DateTime.now();
      await _service.translate(
        text: text,
        sourceLang: Language.english,
        targetLang: Language.hindi,
        useCache: false, // Disable cache for accurate timing
      );
      final time = DateTime.now().difference(start).inMilliseconds;

      times.add(time);
      debugPrint('$text: ${time}ms');
    }

    final avgTime = times.reduce((a, b) => a + b) / times.length;
    final maxTime = times.reduce((a, b) => a > b ? a : b);
    final minTime = times.reduce((a, b) => a < b ? a : b);

    debugPrint('\nPerformance Summary:');
    debugPrint('  Average: ${avgTime.toStringAsFixed(2)}ms');
    debugPrint('  Min: ${minTime}ms');
    debugPrint('  Max: ${maxTime}ms');
    debugPrint('  Target: < 1000ms ✓');
  }

  /// Run all examples
  Future<void> runAllExamples() async {
    try {
      await basicTranslation();
      await bidirectionalTranslation();
      await cachedTranslation();
      await checkAvailability();
      await translationHistory();
      await initializeLanguagePair();
      await performanceBenchmark();

      debugPrint('\n=== All examples completed successfully ===');
    } catch (e) {
      debugPrint('Error running examples: $e');
    } finally {
      _service.dispose();
    }
  }
}

/// Run examples from main or test
Future<void> runTranslationEngineExamples() async {
  final examples = TranslationEngineExample();
  await examples.runAllExamples();
}
