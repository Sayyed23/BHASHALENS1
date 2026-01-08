import 'package:bhashalens_app/services/firebase_auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/saved_translations_page.dart';
import 'package:bhashalens_app/pages/onboarding_page.dart';
import 'package:bhashalens_app/pages/auth/login_page.dart';
import 'package:bhashalens_app/pages/auth/signup_page.dart';
import 'package:bhashalens_app/pages/auth/forgot_password_page.dart';
import 'package:bhashalens_app/pages/home_page.dart';
import 'package:bhashalens_app/pages/camera_translate_page.dart';
// import 'package:bhashalens_app/pages/saved_translations_page.dart';
import 'package:bhashalens_app/pages/settings_page.dart';
import 'package:bhashalens_app/pages/help_support_page.dart';
import 'package:bhashalens_app/pages/emergency_page.dart';
import 'package:bhashalens_app/pages/offline_models_page.dart';
import 'package:bhashalens_app/services/accessibility_service.dart';
import 'package:bhashalens_app/services/local_storage_service.dart'; // Import LocalStorageService
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart'; // Import VoiceTranslationService
import 'package:bhashalens_app/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bhashalens_app/pages/voice_translate_page.dart';
import 'package:bhashalens_app/pages/text_translate_page.dart';
import 'package:bhashalens_app/pages/translation_mode_page.dart';
import 'package:bhashalens_app/pages/explain_mode_page.dart';
import 'package:bhashalens_app/pages/assistant_mode_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  final localStorageService = LocalStorageService(); // Initialize service
  final isOnboardingCompleted = await localStorageService
      .isOnboardingCompleted();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AccessibilityService()),
        Provider<FirebaseAuthService>(create: (_) => FirebaseAuthService()),
        Provider<LocalStorageService>.value(value: localStorageService),
        Provider<GeminiService>(
          create: (_) => GeminiService(apiKey: dotenv.env['GEMINI_API_KEY']!),
        ),
        ChangeNotifierProvider<VoiceTranslationService>(
          create: (_) => VoiceTranslationService(),
        ),
        ChangeNotifierProvider(create: (_) => SavedTranslationsProvider()),
      ],
      child: BhashaLensApp(isOnboardingCompleted: isOnboardingCompleted),
    ),
  );
}

class BhashaLensApp extends StatefulWidget {
  final bool isOnboardingCompleted;
  const BhashaLensApp({super.key, required this.isOnboardingCompleted});

  @override
  State<BhashaLensApp> createState() => _BhashaLensAppState();
}

class _BhashaLensAppState extends State<BhashaLensApp> {

  @override
  Widget build(BuildContext context) {
    final accessibilityService = Provider.of<AccessibilityService>(context);

    return MaterialApp(
      title: 'BhashaLens',
      theme: AppTheme.lightTheme.copyWith(
        textTheme: AppTheme.lightTheme.textTheme.apply(
          fontSizeFactor: accessibilityService.textSizeFactor,
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: AppTheme.darkTheme.textTheme.apply(
          fontSizeFactor: accessibilityService.textSizeFactor,
        ),
      ),
      themeMode: accessibilityService.themeMode,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return widget.isOnboardingCompleted ? const LoginPage() : const OnboardingPage();
        },
      ),
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/camera_translate': (context) => const CameraTranslatePage(),
        '/voice_translate': (context) => const VoiceTranslatePage(),
        '/saved_translations': (context) => const SavedTranslationsPage(),
        '/settings': (context) => const SettingsPage(),
        '/help_support': (context) => const HelpSupportPage(),
        '/emergency': (context) => const EmergencyPage(),
        '/offline_models': (context) => const OfflineModelsPage(),
        '/translation_mode': (context) => const TranslationModePage(),
        '/explain_mode': (context) => const ExplainModePage(),
        '/assistant_mode': (context) => const AssistantModePage(),
        '/text_translate': (context) => const TextTranslatePage(),
      },
    );
  }
}
