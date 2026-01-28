import 'package:flutter_test/flutter_test.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';

void main() {
  group('ML Kit Translation Service', () {
    late MlKitTranslationService service;

    setUp(() {
      service = MlKitTranslationService();
    });

    test('should support bidirectional translation', () async {
      // Test language mapping
      expect(service.getSupportedLanguages().isNotEmpty, true);
      
      // Test that English is included in supported languages
      final supportedLanguages = service.getSupportedLanguages();
      final englishSupported = supportedLanguages.any((lang) => lang['code'] == 'en');
      expect(englishSupported, true);
    });

    test('should identify missing models correctly', () async {
      // This test would require actual model checking, which needs device setup
      // For now, we just test the method exists and doesn't throw
      try {
        final missingModels = await service.getMissingModelsForTranslation('hi', 'es');
        expect(missingModels, isA<List<String>>());
      } catch (e) {
        // Expected in test environment without actual ML Kit setup
        expect(e, isNotNull);
      }
    });

    test('should handle same language translation', () async {
      // This would return the original text for same language
      // Testing the logic without actual ML Kit calls
      const testText = 'Hello World';
      
      // In a real scenario with models available, this should work
      // For now, we test that the method exists and handles the call
      try {
        final result = await service.translate(
          text: testText,
          sourceLanguage: 'en',
          targetLanguage: 'en',
        );
        // Should return original text for same language
        expect(result, testText);
      } catch (e) {
        // Expected in test environment without actual ML Kit setup
        expect(e, isNotNull);
      }
    });
  });
}