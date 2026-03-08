# Translation Engine Implementation

## Overview

The Translation Engine provides offline-first, bidirectional translation using quantized neural machine translation models. This implementation supports Hindi, Marathi, and English with true bidirectional translation (no intermediate English step required).

## Architecture

### Components

1. **TranslationEngine** (Interface)
   - Abstract interface defining translation operations
   - Location: `lib/services/translation_engine.dart`

2. **TFLiteTranslationEngine** (Implementation)
   - TensorFlow Lite-based implementation
   - Uses quantized NLLB or Marian NMT models (INT8)
   - Location: `lib/services/tflite_translation_engine.dart`

3. **OfflineTranslationService** (Service Layer)
   - High-level service with caching and history
   - Integrates with LocalStorage
   - Location: `lib/services/offline_translation_service.dart`

### Data Models

- **Language**: Enum for Hindi, Marathi, English
- **LanguagePair**: Source and target language combination
- **TranslationResult**: Translation output with metadata
- **TranslationHistoryEntry**: Persisted translation record

## Supported Language Pairs

The engine supports 6 bidirectional translation pairs:

1. Hindi ↔ English (hi-en, en-hi)
2. Marathi ↔ English (mr-en, en-mr)
3. Hindi ↔ Marathi (hi-mr, mr-hi)

## Model Requirements

### Model Format
- **Format**: TensorFlow Lite (.tflite)
- **Quantization**: INT8 quantized
- **Size**: ~80MB per language pair (quantized from ~300MB)
- **Architecture**: Distilled NLLB-200 or Marian NMT

### Model Files Structure

```
app_documents/language_packs/
├── hi-en/
│   ├── translation_model.tflite
│   ├── vocab.txt
│   ├── metadata.json
│   └── checksum.sha256
├── en-hi/
│   ├── translation_model.tflite
│   ├── vocab.txt
│   ├── metadata.json
│   └── checksum.sha256
└── ... (other language pairs)
```

### Bundled Models (Optional)

For immediate offline use, models can be bundled in assets:

```
assets/models/
├── hi-en/
│   ├── translation_model.tflite
│   └── vocab.txt
└── ... (other language pairs)
```

## Usage

### Basic Translation

```dart
import 'package:bhashalens_app/services/offline_translation_service.dart';
import 'package:bhashalens_app/models/language_pair.dart';

final translationService = OfflineTranslationService();

// Translate text
final result = await translationService.translate(
  text: 'Hello, how are you?',
  sourceLang: Language.english,
  targetLang: Language.hindi,
);

if (result.success) {
  print('Translation: ${result.translatedText}');
  print('Confidence: ${result.confidence}');
  print('Processing time: ${result.processingTimeMs}ms');
}
```

### Initialize Language Pair

```dart
final pair = LanguagePair(
  source: Language.hindi,
  target: Language.english,
);

// Initialize (loads model into memory)
await translationService.initializeLanguagePair(pair);

// Check if available
final isAvailable = await translationService.isLanguagePairAvailable(pair);
```

### Translation with Caching

```dart
// First call - performs translation and caches result
final result1 = await translationService.translate(
  text: 'नमस्ते',
  sourceLang: Language.hindi,
  targetLang: Language.english,
  useCache: true,
);

// Second call - returns cached result (instant)
final result2 = await translationService.translate(
  text: 'नमस्ते',
  sourceLang: Language.hindi,
  targetLang: Language.english,
  useCache: true,
);
```

### Translation History

```dart
// Get recent translations
final history = await translationService.getHistory(limit: 50);

// Search history
final searchResults = await translationService.searchHistory('hello');

// Clear old history
await translationService.clearHistory(
  beforeTimestamp: DateTime.now()
    .subtract(Duration(days: 30))
    .millisecondsSinceEpoch,
);
```

## Performance Targets

### Latency Requirements
- **Text Translation**: < 1 second for texts under 500 characters
- **Model Loading**: < 2 seconds per language pair
- **Cache Lookup**: < 50ms

### Quality Targets
- **BLEU Score**: > 25 for offline models
- **Confidence Score**: Reported for each translation
- **Accuracy**: Comparable to online services for common phrases

## Integration with Existing Services

### LocalStorage Integration

The Translation Engine integrates with the existing LocalStorage service for:
- **Translation Cache**: Stores recent translations for instant retrieval
- **Translation History**: Persists all translations with metadata
- **Encryption**: All data encrypted with AES-256

### Hybrid Translation Service

The engine can be integrated with the existing HybridTranslationService:

```dart
// In hybrid_translation_service.dart
final offlineEngine = OfflineTranslationService();

// Use offline engine instead of ML Kit
final result = await offlineEngine.translate(
  text: sourceText,
  sourceLang: Language.fromCode(sourceLang),
  targetLang: Language.fromCode(targetLang),
);
```

## Model Download and Management

### Language Pack Manager

The Language Pack Manager (to be implemented in Task 4) will handle:
- Downloading models from S3/CDN
- Verifying checksums
- Managing storage
- Updating models

### Model Download Flow

1. User requests translation for unavailable language pair
2. App prompts to download language pack
3. Download progress displayed
4. Checksum verification
5. Model ready for use

## Testing

### Unit Tests

```dart
// Test translation
test('should translate Hindi to English', () async {
  final service = OfflineTranslationService();
  final result = await service.translate(
    text: 'नमस्ते',
    sourceLang: Language.hindi,
    targetLang: Language.english,
  );
  
  expect(result.success, true);
  expect(result.translatedText, isNotEmpty);
  expect(result.processingTimeMs, lessThan(1000));
});
```

### Property-Based Tests

Property tests will validate:
- **Property 1**: Offline translation availability
- **Property 2**: Translation latency < 1 second
- **Property 3**: Language pair bidirectionality
- **Property 5**: Translation cache consistency

## Migration from ML Kit

### Differences from ML Kit

| Feature | ML Kit | TFLite Engine |
|---------|--------|---------------|
| Bidirectional | Via English | Direct |
| Model Source | Google proprietary | Open-source NLLB/Marian |
| Model Size | ~30MB | ~80MB (quantized) |
| Offline | Yes | Yes |
| Customizable | No | Yes |
| Quality | Good | Better for Indic languages |

### Migration Steps

1. Keep ML Kit as fallback for unsupported languages
2. Use TFLite engine for Hindi/Marathi/English
3. Gradually phase out ML Kit as more models are added

## Future Enhancements

### Phase 2 Improvements
- Add more language pairs (Tamil, Telugu, Bengali)
- Implement streaming translation for long texts
- Add translation quality estimation
- Support offline language detection

### Phase 3 Optimizations
- Model quantization to 4-bit for smaller size
- GPU acceleration for faster inference
- Batch translation for multiple texts
- Adaptive model loading based on usage patterns

## Troubleshooting

### Common Issues

**Issue**: Model not found
- **Solution**: Ensure language pack is downloaded or bundled in assets

**Issue**: Translation too slow
- **Solution**: Check model is loaded in memory, not loading on each request

**Issue**: Low translation quality
- **Solution**: Verify model file integrity, check BLEU scores

**Issue**: Out of memory
- **Solution**: Release unused models, implement LRU cache for model loading

## Dependencies

```yaml
dependencies:
  tflite_flutter: ^0.10.4
  tflite_flutter_helper: ^0.3.1
  path_provider: ^2.0.0
```

## References

- [NLLB-200 Model](https://github.com/facebookresearch/fairseq/tree/nllb)
- [Marian NMT](https://marian-nmt.github.io/)
- [TensorFlow Lite](https://www.tensorflow.org/lite)
- [Model Quantization Guide](https://www.tensorflow.org/lite/performance/post_training_quantization)
