import 'package:bhashalens_app/models/detected_intent.dart';

/// Rule-based engine for detecting intent, tone, context, and sensitivity
/// from text input. Works entirely offline with deterministic rules.
class RuleEngine {
  // Intent detection keywords
  static const List<String> _requestKeywords = [
    'please',
    'kindly',
    'request',
    'could you',
    'would you',
    'can you',
    'may i',
    'help me',
    'assist'
  ];

  static const List<String> _warningKeywords = [
    'not allowed',
    'prohibited',
    'no entry',
    'forbidden',
    'restricted',
    'do not',
    'don\'t',
    'must not',
    'warning',
    'danger',
    'caution',
    'illegal',
    'unauthorized',
    'violation',
    'penalty'
  ];

  // Tone detection keywords
  static const List<String> _urgentKeywords = [
    'urgent',
    'immediately',
    'now',
    'asap',
    'emergency',
    'critical',
    'right away',
    'at once',
    'hurry',
    'quick',
    'fast'
  ];

  static const List<String> _politeKeywords = [
    'please',
    'kindly',
    'thank you',
    'thanks',
    'appreciate',
    'grateful',
    'would you mind',
    'excuse me',
    'sorry'
  ];

  static const List<String> _formalKeywords = [
    'hereby',
    'therefore',
    'pursuant',
    'accordingly',
    'whereas',
    'regarding',
    'concerning',
    'with respect to',
    'dear sir',
    'dear madam'
  ];

  // Context detection keywords
  static const Map<ContextType, List<String>> _contextKeywords = {
    ContextType.hospital: [
      'doctor',
      'hospital',
      'medicine',
      'prescription',
      'patient',
      'treatment',
      'diagnosis',
      'nurse',
      'emergency',
      'clinic',
      'surgery',
      'admit',
      'discharge',
      'ward',
      'icu'
    ],
    ContextType.office: [
      'office',
      'meeting',
      'deadline',
      'project',
      'manager',
      'employee',
      'report',
      'presentation',
      'conference',
      'workplace',
      'colleague',
      'boss',
      'supervisor',
      'email',
      'schedule'
    ],
    ContextType.travel: [
      'airport',
      'flight',
      'train',
      'bus',
      'ticket',
      'passport',
      'visa',
      'hotel',
      'booking',
      'reservation',
      'departure',
      'arrival',
      'terminal',
      'platform',
      'station'
    ],
    ContextType.publicPlace: [
      'mall',
      'market',
      'shop',
      'store',
      'bank',
      'atm',
      'queue',
      'counter',
      'entrance',
      'exit',
      'parking',
      'public',
      'crowd'
    ],
    ContextType.legal: [
      'court',
      'legal',
      'rights',
      'lawyer',
      'attorney',
      'judge',
      'law',
      'police',
      'complaint',
      'fir',
      'contract',
      'agreement',
      'witness',
      'hearing',
      'verdict'
    ],
  };

  // Sensitivity detection keywords
  static const List<String> _medicalKeywords = [
    'diagnosis',
    'prescription',
    'symptom',
    'treatment',
    'medicine',
    'dosage',
    'side effect',
    'condition',
    'disease',
    'illness',
    'surgery',
    'operation',
    'therapy',
    'medication'
  ];

  static const List<String> _legalKeywords = [
    'court',
    'legal',
    'rights',
    'law',
    'attorney',
    'lawyer',
    'contract',
    'agreement',
    'sue',
    'liability',
    'prosecution',
    'verdict',
    'sentence',
    'bail',
    'appeal'
  ];

  /// Analyze text and return detected intent with confidence score
  DetectedIntent analyze(String text, {ContextType? userContext}) {
    final lowerText = text.toLowerCase().trim();

    // 1. Detect intent
    final intentResult = _detectIntent(lowerText);

    // 2. Detect tone
    final toneResult = _detectTone(lowerText);

    // 3. Detect context (use user-provided if available)
    final contextResult = userContext ?? _detectContext(lowerText);

    // 4. Detect sensitivity
    final sensitivityResult = _detectSensitivity(lowerText);

    // 5. Calculate overall confidence
    final confidence = _calculateConfidence(
      lowerText,
      intentResult,
      toneResult,
      contextResult,
    );

    return DetectedIntent(
      intent: intentResult,
      tone: toneResult,
      context: contextResult,
      sensitivity: sensitivityResult,
      confidence: confidence,
    );
  }

  IntentType _detectIntent(String text) {
    // Check for question
    if (text.endsWith('?') ||
        text.startsWith('what') ||
        text.startsWith('how') ||
        text.startsWith('why') ||
        text.startsWith('when') ||
        text.startsWith('where') ||
        text.startsWith('who') ||
        text.startsWith('is ') ||
        text.startsWith('are ') ||
        text.startsWith('can ') ||
        text.startsWith('do ')) {
      return IntentType.question;
    }

    // Check for warning
    for (final keyword in _warningKeywords) {
      if (text.contains(keyword)) {
        return IntentType.warning;
      }
    }

    // Check for request
    for (final keyword in _requestKeywords) {
      if (text.contains(keyword)) {
        return IntentType.request;
      }
    }

    // Default to statement
    return IntentType.statement;
  }

  ToneType _detectTone(String text) {
    // Check for urgent tone first (takes precedence)
    for (final keyword in _urgentKeywords) {
      if (text.contains(keyword)) {
        return ToneType.urgent;
      }
    }

    // Check for formal tone
    for (final keyword in _formalKeywords) {
      if (text.contains(keyword)) {
        return ToneType.formal;
      }
    }

    // Check for polite tone
    for (final keyword in _politeKeywords) {
      if (text.contains(keyword)) {
        return ToneType.polite;
      }
    }

    // Check for casual markers
    if (text.contains('hey') ||
        text.contains('hi ') ||
        text.contains('gonna') ||
        text.contains('wanna')) {
      return ToneType.casual;
    }

    return ToneType.neutral;
  }

  ContextType _detectContext(String text) {
    int maxMatches = 0;
    ContextType bestContext = ContextType.dailyLife;

    for (final entry in _contextKeywords.entries) {
      int matches = 0;
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestContext = entry.key;
      }
    }

    // Only return specific context if we have at least 1 match
    return maxMatches > 0 ? bestContext : ContextType.dailyLife;
  }

  SensitivityLevel _detectSensitivity(String text) {
    // Check for medical sensitivity
    for (final keyword in _medicalKeywords) {
      if (text.contains(keyword)) {
        return SensitivityLevel.medical;
      }
    }

    // Check for legal sensitivity
    for (final keyword in _legalKeywords) {
      if (text.contains(keyword)) {
        return SensitivityLevel.legal;
      }
    }

    return SensitivityLevel.general;
  }

  double _calculateConfidence(
    String text,
    IntentType intent,
    ToneType tone,
    ContextType context,
  ) {
    double confidence = 0.5; // Base confidence

    // Boost for clear intent markers
    if (intent == IntentType.question && text.endsWith('?')) {
      confidence += 0.2;
    }
    if (intent == IntentType.warning) {
      confidence += 0.15;
    }
    if (intent == IntentType.request) {
      confidence += 0.1;
    }

    // Boost for tone detection
    if (tone != ToneType.neutral) {
      confidence += 0.1;
    }

    // Boost for specific context
    if (context != ContextType.dailyLife && context != ContextType.unknown) {
      confidence += 0.1;
    }

    // Reduce confidence for very short text
    if (text.length < 20) {
      confidence -= 0.2;
    }

    // Cap confidence between 0 and 1
    return confidence.clamp(0.0, 1.0);
  }
}
