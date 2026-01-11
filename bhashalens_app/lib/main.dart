import 'package:bhashalens_app/services/firestore_service.dart'; // Import FirestoreService
import 'package:bhashalens_app/services/firebase_auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/saved_translations_page.dart';
import 'package:bhashalens_app/pages/onboarding_page.dart';
import 'package:bhashalens_app/pages/auth/login_page.dart';
import 'package:bhashalens_app/pages/auth/signup_page.dart';
import 'package:bhashalens_app/pages/auth/forgot_password_page.dart';
import 'package:bhashalens_app/pages/home_page.dart';
import 'package:bhashalens_app/pages/camera_translate_page.dart';
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
import 'package:bhashalens_app/pages/history_saved_page.dart';
import 'package:bhashalens_app/pages/splash_screen.dart';

import 'package:bhashalens_app/firebase_options.dart';

import 'package:bhashalens_app/services/db_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabaseFactory();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Failed to load .env file: $e");
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Warning: Failed to initialize Firebase: $e");
  }
  FirebaseAnalytics.instance;

  final localStorageService = LocalStorageService(); // Initialize service
  // Initialize Auth Service to trigger anonymous login if needed
  final authService = FirebaseAuthService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AccessibilityService()),
        Provider<FirebaseAuthService>(create: (_) => authService),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<LocalStorageService>.value(value: localStorageService),
        Provider<GeminiService>(
          create: (_) => GeminiService(
            apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
            localStorageService: localStorageService,
          ),
        ),
        ChangeNotifierProvider<VoiceTranslationService>(
          create: (_) => VoiceTranslationService(
            localStorageService: localStorageService,
            geminiApiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
          ),
        ),
        ChangeNotifierProvider(create: (_) => SavedTranslationsProvider()),
      ],
      child: const BhashaLensApp(),
    ),
  );
}

class BhashaLensApp extends StatefulWidget {
  const BhashaLensApp({super.key});

  @override
  State<BhashaLensApp> createState() => _BhashaLensAppState();
}

class _BhashaLensAppState extends State<BhashaLensApp> {
  bool _showSplash = true;
  bool _isOnboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // 1. Check Auth (Async)
    _checkAuth();

    // 2. Check Onboarding (Async)
    try {
      final localStorage = Provider.of<LocalStorageService>(
        context,
        listen: false,
      );
      final completed = await localStorage.isOnboardingCompleted();
      if (mounted) {
        setState(() {
          _isOnboardingCompleted = completed;
        });
      }
    } catch (e) {
      debugPrint("Failed to check onboarding status: $e");
    }
  }

  Future<void> _checkAuth() async {
    final authService = Provider.of<FirebaseAuthService>(
      context,
      listen: false,
    );
    if (authService.currentUser == null) {
      try {
        await authService.signInAnonymously();
      } catch (e) {
        debugPrint('Failed to sign in anonymously: $e');
      }
    }
  }

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
      home: _showSplash
          ? SplashScreen(
              onComplete: () {
                setState(() {
                  _showSplash = false;
                });
              },
            )
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                // If user is logged in (including anonymous), show HomePage
                // If not, show Onboarding or Login (which should also allow skipping)
                if (snapshot.hasData) {
                  return const HomePage();
                }
                // Even if not logged in yet (auth failure?), fallback to Onboarding/Login
                // Ideally, signInAnonymously above should have handled it or is in progress.
                return _isOnboardingCompleted
                    ? const LoginPage()
                    : const OnboardingPage();
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
        '/history_saved': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as int? ?? 0;
          return HistorySavedPage(initialIndex: args);
        },
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
