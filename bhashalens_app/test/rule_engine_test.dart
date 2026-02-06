import 'package:flutter_test/flutter_test.dart';
import 'package:bhashalens_app/services/rule_engine.dart';
import 'package:bhashalens_app/models/detected_intent.dart';

void main() {
  late RuleEngine ruleEngine;

  setUp(() {
    ruleEngine = RuleEngine();
  });

  group('Intent Detection', () {
    test('should detect question from question mark', () {
      final result = ruleEngine.analyze('What is this?');
      expect(result.intent, IntentType.question);
    });

    test('should detect question from "how" prefix', () {
      final result = ruleEngine.analyze('how do I use this');
      expect(result.intent, IntentType.question);
    });

    test('should detect request from "please"', () {
      final result = ruleEngine.analyze('Please help me with this');
      expect(result.intent, IntentType.request);
    });

    test('should detect request from "kindly"', () {
      final result = ruleEngine.analyze('Kindly assist me');
      expect(result.intent, IntentType.request);
    });

    test('should detect warning from "not allowed"', () {
      final result = ruleEngine.analyze('Parking is not allowed here');
      expect(result.intent, IntentType.warning);
    });

    test('should detect warning from "prohibited"', () {
      final result = ruleEngine.analyze('Smoking is prohibited in this area');
      expect(result.intent, IntentType.warning);
    });

    test('should default to statement', () {
      final result = ruleEngine.analyze('The meeting is at 3 PM');
      expect(result.intent, IntentType.statement);
    });
  });

  group('Tone Detection', () {
    test('should detect urgent tone', () {
      final result = ruleEngine.analyze('Come immediately, this is urgent');
      expect(result.tone, ToneType.urgent);
    });

    test('should detect polite tone', () {
      final result = ruleEngine.analyze('Thank you for your help');
      expect(result.tone, ToneType.polite);
    });

    test('should detect formal tone', () {
      final result = ruleEngine
          .analyze('Regarding your application, we hereby inform you');
      expect(result.tone, ToneType.formal);
    });

    test('should detect casual tone', () {
      final result = ruleEngine.analyze('Hey, wanna grab lunch?');
      expect(result.tone, ToneType.casual);
    });

    test('should default to neutral tone', () {
      final result = ruleEngine.analyze('The document is ready');
      expect(result.tone, ToneType.neutral);
    });
  });

  group('Context Detection', () {
    test('should detect hospital context', () {
      final result = ruleEngine.analyze('The doctor will see you now');
      expect(result.context, ContextType.hospital);
    });

    test('should detect office context', () {
      final result = ruleEngine.analyze('The meeting deadline is tomorrow');
      expect(result.context, ContextType.office);
    });

    test('should detect travel context', () {
      final result = ruleEngine.analyze('Your flight departs from terminal 3');
      expect(result.context, ContextType.travel);
    });

    test('should detect legal context', () {
      final result = ruleEngine.analyze('You have the right to an attorney');
      expect(result.context, ContextType.legal);
    });

    test('should default to daily life context', () {
      final result = ruleEngine.analyze('Hello, good morning');
      expect(result.context, ContextType.dailyLife);
    });

    test('should use user-provided context when available', () {
      final result = ruleEngine.analyze(
        'Please wait here',
        userContext: ContextType.hospital,
      );
      expect(result.context, ContextType.hospital);
    });
  });

  group('Sensitivity Detection', () {
    test('should detect medical sensitivity', () {
      final result = ruleEngine.analyze('Your diagnosis shows improvement');
      expect(result.sensitivity, SensitivityLevel.medical);
    });

    test('should detect legal sensitivity', () {
      final result = ruleEngine.analyze('The court will hear your case');
      expect(result.sensitivity, SensitivityLevel.legal);
    });

    test('should default to general sensitivity', () {
      final result = ruleEngine.analyze('The weather is nice today');
      expect(result.sensitivity, SensitivityLevel.general);
    });
  });

  group('Confidence Calculation', () {
    test('should have high confidence for clear question', () {
      final result = ruleEngine.analyze('What time is the appointment?');
      expect(result.isHighConfidence, true);
    });

    test('should have lower confidence for short text', () {
      final result = ruleEngine.analyze('ok');
      expect(result.isLowConfidence, true);
    });

    test('should have higher confidence for longer text with multiple markers',
        () {
      final result = ruleEngine.analyze(
        'Please come to the hospital immediately for your urgent diagnosis',
      );
      expect(result.confidence, greaterThan(0.6));
    });
  });
}
