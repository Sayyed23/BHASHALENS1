import 'package:bhashalens_app/services/firestore_service.dart'; // Import FirestoreService
import 'package:bhashalens_app/services/firebase_auth_service.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
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
import 'package:bhashalens_app/pages/error_fallback_page.dart';
import 'package:bhashalens_app/services/accessibility_service.dart';
import 'package:bhashalens_app/services/local_storage_service.dart'; // Import LocalStorageService
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart'; // Import VoiceTranslationService
import 'package:bhashalens_app/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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

  // Initialize database factory
  initializeDatabaseFactory();

  // Load environment variables with error handling (non-blocking)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Failed to load .env file: $e");
    // Continue without .env - app should still work with google-services.json
  }

  // Initialize Firebase with error handling (non-blocking)
  bool firebaseInitialized = false;
  try {
    try {
      // First try with generated options (requires complete .env)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
      debugPrint("Firebase initialized successfully with options");
    } catch (e) {
      // Fallback: try without options (uses google-services.json on Android)
      debugPrint("Warning: Failed to initialize Firebase with options: $e");
      debugPrint("Attempting fallback initialization...");
      await Firebase.initializeApp();
      firebaseInitialized = true;
      debugPrint("Firebase initialized successfully via fallback");
    }
  } catch (e) {
    debugPrint("Warning: Failed to initialize Firebase (Final): $e");
    // Continue without Firebase - app should still work in offline mode
  }

  // Initialize services
  final localStorageService = LocalStorageService();

  // Create provider list with conditional Firebase services
  final providers = <SingleChildWidget>[
    ChangeNotifierProvider(create: (context) => AccessibilityService()),
    Provider<LocalStorageService>.value(value: localStorageService),
    Provider<GeminiService>(
      create: (_) => GeminiService(
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        localStorageService: localStorageService,
      )..initialize(),
    ),
    ChangeNotifierProvider<VoiceTranslationService>(
      create: (_) => VoiceTranslationService(
        localStorageService: localStorageService,
        geminiApiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      ),
    ),
    ChangeNotifierProvider(create: (_) => SavedTranslationsProvider()),
  ];

  // Only add Firebase services if initialization succeeded
  if (firebaseInitialized) {
    final authService = FirebaseAuthService();
    providers.addAll([
      Provider<FirebaseAuthService>(create: (_) => authService),
      Provider<FirestoreService>(create: (_) => FirestoreService()),
    ]);
  }

  runApp(
    MultiProvider(
      providers: providers,
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
  bool _isInitialized = false;
  bool _initCancelled = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Set a maximum timeout for the entire initialization
      await _performInitialization().timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint("Initialization failed or timed out: $e");
      // Cancel any ongoing initialization to prevent setState after timeout
      _initCancelled = true;

      // Continue with defaults (this should still run on timeout)
      if (mounted) {
        setState(() {
          _isOnboardingCompleted = false;
          _isInitialized = true;
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
      }
    }
  }

  Future<void> _performInitialization() async {
    // Quick initialization without blocking
    await Future.delayed(const Duration(milliseconds: 300));

    // Check if initialization was cancelled
    if (_initCancelled) return;

    bool completed = false;
    try {
      // Try to check onboarding status with timeout
      if (!mounted) return;
      final localStorage = Provider.of<LocalStorageService>(
        context,
        listen: false,
      );
      completed = await localStorage.isOnboardingCompleted();
    } catch (e) {
      debugPrint("Failed to check onboarding: $e");
      completed = false;
    }

    // Check cancellation before proceeding
    if (_initCancelled) return;

    // Initialize auth in background (don't wait for it)
    _checkAuth();

    if (!_initCancelled && mounted) {
      setState(() {
        _isOnboardingCompleted = completed;
        _isInitialized = true;
      });

      // Hide splash after short delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_initCancelled && mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    try {
      // Only try to access Firebase auth if the service is available
      // The provider is registered as non-nullable, so we must catch the exception
      // if Firebase wasn't initialized and the provider wasn't added.
      late final FirebaseAuthService authService;
      try {
        authService = Provider.of<FirebaseAuthService>(
          context,
          listen: false,
        );
      } catch (e) {
        debugPrint('FirebaseAuthService not available in provider tree: $e');
        return;
      }

      if (authService.currentUser == null) {
        await authService.signInAnonymously().timeout(
              const Duration(seconds: 3),
            );
      }
    } catch (e) {
      debugPrint('Failed to sign in anonymously: $e');
    }
  }

  Stream<User?> _getAuthStream() {
    try {
      // Check if Firebase is initialized before accessing FirebaseAuth
      Firebase.app();
      return FirebaseAuth.instance.authStateChanges();
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      // Return a stream that emits null (no user) if Firebase is not available
      return Stream.value(null);
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
                if (mounted) {
                  setState(() {
                    _showSplash = false;
                  });
                }
              },
            )
          : !_isInitialized
              ? const Scaffold(
                  backgroundColor: Color(0xFFFFF8F5),
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                    ),
                  ),
                )
              : StreamBuilder<User?>(
                  stream: _getAuthStream(),
                  builder: (context, snapshot) {
                    // Don't wait for auth - show app immediately
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _isOnboardingCompleted
                          ? const HomePage()
                          : const OnboardingPage();
                    }

                    // Handle errors gracefully
                    if (snapshot.hasError) {
                      debugPrint('Auth stream error: ${snapshot.error}');
                      return _isOnboardingCompleted
                          ? const HomePage()
                          : const OnboardingPage();
                    }

                    // If user is logged in, show HomePage
                    if (snapshot.hasData) {
                      return const HomePage();
                    }

                    // Fallback to onboarding or home
                    return _isOnboardingCompleted
                        ? const HomePage()
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
        '/error': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String? ??
              'Unknown error';
          return ErrorFallbackPage(error: args);
        },
      },
    );
  }
}
