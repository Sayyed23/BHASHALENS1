import 'package:bhashalens_app/models/detected_intent.dart';

/// Predefined explanation templates for offline use.
/// All templates are safe, simple, and deterministic.
class ExplanationTemplates {
  // ============ MEANING TEMPLATES ============

  static const Map<IntentType, String> meaningTemplates = {
    IntentType.question:
        'This is a question asking for information or clarification.',
    IntentType.request:
        'This is a polite request asking someone to do something.',
    IntentType.warning:
        'This is a warning or restriction. It tells you something is not allowed or must be followed.',
    IntentType.statement:
        'This is a statement providing information or instructions.',
    IntentType.unknown: 'This text conveys a message or information.',
  };

  // ============ USAGE TEMPLATES ============

  static const Map<IntentType, String> usageTemplates = {
    IntentType.question:
        'Questions like this are used when you need to understand something or get help.',
    IntentType.request:
        'Requests like this are used when asking for help or action from others.',
    IntentType.warning:
        'You may see this in public places, official spaces, or safety notices.',
    IntentType.statement:
        'Statements like this are used to share information or give instructions.',
    IntentType.unknown:
        'This type of text can appear in various everyday situations.',
  };

  // ============ TONE TEMPLATES ============

  static const Map<ToneType, String> toneTemplates = {
    ToneType.urgent:
        'The tone is urgent. This requires immediate attention or action.',
    ToneType.polite: 'The tone is polite and respectful.',
    ToneType.formal: 'The tone is formal and professional.',
    ToneType.casual: 'The tone is casual and informal.',
    ToneType.neutral: 'The tone is neutral and straightforward.',
  };

  // ============ CONTEXT-SPECIFIC TEMPLATES ============

  static const Map<ContextType, Map<String, String>> contextTemplates = {
    ContextType.hospital: {
      'meaning': 'This is related to healthcare or medical services.',
      'usage':
          'You may hear or read this in hospitals, clinics, or when dealing with health matters.',
      'note':
          'For medical advice, please consult a qualified healthcare professional.',
    },
    ContextType.office: {
      'meaning': 'This is related to work or professional settings.',
      'usage':
          'You may encounter this in offices, meetings, or workplace communications.',
      'note':
          'Workplace norms may vary. Follow your organization\'s guidelines.',
    },
    ContextType.travel: {
      'meaning': 'This is related to travel or transportation.',
      'usage':
          'You may see this at airports, train stations, hotels, or during travel.',
      'note': 'Always check with official sources for travel regulations.',
    },
    ContextType.publicPlace: {
      'meaning': 'This is related to public spaces or services.',
      'usage':
          'You may encounter this in malls, banks, markets, or public buildings.',
      'note': 'Public place rules help ensure safety and order for everyone.',
    },
    ContextType.legal: {
      'meaning': 'This is related to legal or official matters.',
      'usage':
          'You may encounter this in legal documents, court proceedings, or official notices.',
      'note':
          'For legal advice, please consult a qualified legal professional.',
    },
    ContextType.dailyLife: {
      'meaning': 'This is general everyday communication.',
      'usage':
          'You may encounter this in daily conversations or common situations.',
      'note': '',
    },
    ContextType.unknown: {
      'meaning': 'This text conveys a message or information.',
      'usage': 'This type of text can appear in various situations.',
      'note': '',
    },
  };

  // ============ SENSITIVITY DISCLAIMERS ============

  static const Map<SensitivityLevel, String?> sensitivityNotes = {
    SensitivityLevel.medical:
        'This appears to be health-related. For medical advice, please consult a qualified healthcare professional.',
    SensitivityLevel.legal:
        'This appears to be legally related. For legal advice, please consult a qualified legal professional.',
    SensitivityLevel.general: null,
  };

  // ============ GENERIC FALLBACK TEMPLATES ============

  static const Map<String, String> genericTemplates = {
    'meaning': 'This text is sharing information or a message with you.',
    'usage': 'You may encounter text like this in everyday situations.',
    'tone': 'The tone appears to be neutral.',
  };

  // ============ SUGGESTED QUESTIONS BY INTENT ============

  static const Map<IntentType, List<String>> suggestedQuestions = {
    IntentType.question: [
      'How should I respond to this?',
      'What information do they need?',
    ],
    IntentType.request: [
      'How do I fulfill this request?',
      'What if I cannot do this?',
    ],
    IntentType.warning: [
      'What happens if I ignore this?',
      'Are there exceptions to this rule?',
    ],
    IntentType.statement: [
      'What should I do with this information?',
      'Is there anything I need to respond to?',
    ],
    IntentType.unknown: [
      'What does this mean for me?',
      'Should I take any action?',
    ],
  };

  // ============ CONTEXT-SPECIFIC SUGGESTIONS ============

  static const Map<ContextType, List<String>> contextSuggestions = {
    ContextType.hospital: [
      'Should I bring any documents?',
      'What should I tell the doctor?',
    ],
    ContextType.office: [
      'How should I respond professionally?',
      'Is this urgent?',
    ],
    ContextType.travel: [
      'What documents do I need?',
      'Where should I go next?',
    ],
    ContextType.publicPlace: [
      'Where can I get help?',
      'Who should I ask?',
    ],
    ContextType.legal: [
      'Should I consult a lawyer?',
      'What are my options?',
    ],
    ContextType.dailyLife: [
      'What should I do next?',
      'Is this important?',
    ],
    ContextType.unknown: [
      'What does this mean?',
      'How should I respond?',
    ],
  };
}
