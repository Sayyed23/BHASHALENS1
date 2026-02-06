import 'package:flutter_test/flutter_test.dart';
import 'package:bhashalens_app/services/template_service.dart';
import 'package:bhashalens_app/models/detected_intent.dart';

void main() {
  late TemplateService templateService;

  setUp(() {
    templateService = TemplateService();
  });

  group('Template Generation', () {
    test('should generate explanation for high confidence intent', () {
      const intent = DetectedIntent(
        intent: IntentType.warning,
        tone: ToneType.urgent,
        context: ContextType.hospital,
        sensitivity: SensitivityLevel.medical,
        confidence: 0.8,
      );

      final result = templateService.generate(intent);

      expect(result.meaning, isNotEmpty);
      expect(result.usage, isNotEmpty);
      expect(result.toneDescription, contains('urgent'));
      expect(result.safetyNote, isNotNull);
      expect(result.offlineGenerated, true);
    });

    test('should include medical safety note for medical sensitivity', () {
      const intent = DetectedIntent(
        intent: IntentType.statement,
        tone: ToneType.neutral,
        context: ContextType.hospital,
        sensitivity: SensitivityLevel.medical,
        confidence: 0.7,
      );

      final result = templateService.generate(intent);

      expect(result.safetyNote, contains('healthcare professional'));
    });

    test('should include legal safety note for legal sensitivity', () {
      const intent = DetectedIntent(
        intent: IntentType.statement,
        tone: ToneType.formal,
        context: ContextType.legal,
        sensitivity: SensitivityLevel.legal,
        confidence: 0.7,
      );

      final result = templateService.generate(intent);

      expect(result.safetyNote, contains('legal professional'));
    });

    test('should use blended templates for medium confidence', () {
      const intent = DetectedIntent(
        intent: IntentType.question,
        tone: ToneType.polite,
        context: ContextType.office,
        sensitivity: SensitivityLevel.general,
        confidence: 0.5,
      );

      final result = templateService.generate(intent);

      expect(result.meaning, isNotEmpty);
      // Medium confidence should have fewer suggestions
      expect(result.suggestions.length, lessThanOrEqualTo(2));
    });

    test('should use generic templates for low confidence', () {
      const intent = DetectedIntent(
        intent: IntentType.unknown,
        tone: ToneType.neutral,
        context: ContextType.unknown,
        sensitivity: SensitivityLevel.general,
        confidence: 0.3,
      );

      final result = templateService.generate(intent);

      expect(result.meaning, contains('sharing information'));
      expect(result.toneDescription, contains('neutral'));
    });

    test('should convert to context data map for UI compatibility', () {
      const intent = DetectedIntent(
        intent: IntentType.request,
        tone: ToneType.polite,
        context: ContextType.dailyLife,
        sensitivity: SensitivityLevel.general,
        confidence: 0.75,
      );

      final result = templateService.generate(intent);
      final map = result.toContextDataMap();

      expect(map['meaning'], isNotEmpty);
      expect(map['analysis'], equals(map['meaning']));
      expect(map['suggested_questions'], isA<List>());
    });
  });
}
