import 'package:bhashalens_app/services/firestore_service.dart';
import 'package:bhashalens_app/services/firebase_auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Removed unused import
import 'dart:async';

// Pages
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
import 'package:bhashalens_app/pages/voice_translate_page.dart';
import 'package:bhashalens_app/pages/text_translate_page.dart';
import 'package:bhashalens_app/pages/translation_mode_page.dart';
import 'package:bhashalens_app/pages/explain_mode_page.dart';
import 'package:bhashalens_app/pages/assistant_mode_page.dart';
import 'package:bhashalens_app/pages/history_saved_page.dart';
import 'package:bhashalens_app/pages/splash_screen.dart';
import 'package:bhashalens_app/pages/saved_translations_page.dart';
import 'package:bhashalens_app/pages/simplify_mode_page.dart';

// Services
import 'package:bhashalens_app/services/accessibility_service.dart';
import 'package:bhashalens_app/services/local_storage_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:bhashalens_app/services/db_initializer.dart';
import 'package:bhashalens_app/services/aws_api_gateway_client.dart';
import 'package:bhashalens_app/services/aws_cloud_service.dart';
import 'package:bhashalens_app/services/hybrid_translation_service.dart';
import 'package:bhashalens_app/services/history_service.dart';
import 'package:bhashalens_app/services/saved_translations_service.dart';
import 'package:bhashalens_app/services/preferences_service.dart';
import 'package:bhashalens_app/services/export_service.dart';
import 'package:bhashalens_app/services/monitoring_service.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/sarvam_service.dart';

// Other
import 'package:bhashalens_app/theme/app_theme.dart';
import 'package:bhashalens_app/firebase_options.dart';
// Removed unused import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabaseFactory();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Failed to load .env file: $e");
  }

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    firebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase init error: $e");
    try {
      await Firebase.initializeApp();
      firebaseInitialized = true;
    } catch (_) {}
  }

  final localStorageService = LocalStorageService();
  final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  final geminiService = GeminiService(
    apiKey: geminiApiKey,
    localStorageService: localStorageService,
  );
  await geminiService.initialize();

  final providers = <SingleChildWidget>[
    ChangeNotifierProvider(create: (context) => AccessibilityService()),
    Provider<LocalStorageService>.value(value: localStorageService),
    Provider<GeminiService>.value(value: geminiService),
    Provider<AwsApiGatewayClient>(create: (_) => AwsApiGatewayClient()),
    ProxyProvider<AwsApiGatewayClient, AwsCloudService>(
      update: (_, apiClient, __) => AwsCloudService(apiClient: apiClient),
    ),
    ChangeNotifierProxyProvider2<AwsApiGatewayClient, LocalStorageService,
        HistoryService>(
      create: (context) => HistoryService(
        apiClient: Provider.of<AwsApiGatewayClient>(context, listen: false),
        localStorageService:
            Provider.of<LocalStorageService>(context, listen: false),
      )..fetchHistory(),
      update: (_, apiClient, localStorage, history) => history!,
    ),
    ChangeNotifierProxyProvider2<AwsApiGatewayClient, LocalStorageService,
        SavedTranslationsService>(
      create: (context) => SavedTranslationsService(
        apiClient: Provider.of<AwsApiGatewayClient>(context, listen: false),
        localStorageService:
            Provider.of<LocalStorageService>(context, listen: false),
      )..fetchSavedTranslations(),
      update: (_, apiClient, localStorage, saved) => saved!,
    ),
    ChangeNotifierProxyProvider2<AwsApiGatewayClient, LocalStorageService,
        PreferencesService>(
      create: (context) => PreferencesService(
        apiClient: Provider.of<AwsApiGatewayClient>(context, listen: false),
        localStorageService:
            Provider.of<LocalStorageService>(context, listen: false),
      )..fetchPreferences(),
      update: (_, apiClient, localStorage, prefs) => prefs!,
    ),
    ChangeNotifierProxyProvider<AwsApiGatewayClient, ExportService>(
      create: (context) => ExportService(
        apiClient: Provider.of<AwsApiGatewayClient>(context, listen: false),
      ),
      update: (_, apiClient, export) => export!,
    ),
    Provider<MonitoringService>(
      create: (context) => MonitoringService(
        apiClient: Provider.of<AwsApiGatewayClient>(context, listen: false),
      ),
    ),
    ProxyProvider2<AwsCloudService, LocalStorageService,
        HybridTranslationService>(
      update: (_, awsCloud, localStorage, __) => HybridTranslationService(
        cloudService: awsCloud,
        localStorageService: localStorage,
        onDeviceTranslation: MlKitTranslationService(),
        onDeviceLLM: geminiService,
      ),
    ),
    ChangeNotifierProxyProvider<HybridTranslationService,
        VoiceTranslationService>(
      create: (context) => VoiceTranslationService(
        localStorageService: localStorageService,
      ),
      update: (context, hybrid, voice) => voice!..hybridService = hybrid,
    ),
    ChangeNotifierProvider(create: (_) => SavedTranslationsProvider()),
    Provider<SarvamService>(
      create: (_) => SarvamService(),
      dispose: (_, service) => service.dispose(),
    ),
  ];

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
// Removed unused _isInitialized field

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final localStorage =
        Provider.of<LocalStorageService>(context, listen: false);
    final completed = await localStorage.isOnboardingCompleted();

    if (mounted) {
      setState(() {
        _isOnboardingCompleted = completed;
      });
    }
  }

  String _normalizeRouteName(String? routeName) {
    if (routeName == null || routeName.isEmpty) return '/';
    var normalized = routeName.trim();
    if (!normalized.startsWith('/')) normalized = '/$normalized';
    return normalized;
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final routeName = _normalizeRouteName(settings.name);

    Widget builder;
    switch (routeName) {
      case '/':
        // The root route is now handled by the 'home' property for better reactivity
        builder = _isOnboardingCompleted
            ? const HomePage()
            : const OnboardingPage();
        break;
      case '/onboarding':
        builder = const OnboardingPage();
        break;
      case '/login':
        builder = const LoginPage();
        break;
      case '/signup':
        builder = const SignupPage();
        break;
      case '/forgot_password':
        builder = const ForgotPasswordPage();
        break;
      case '/home':
        builder = const HomePage();
        break;
      case '/camera_translate':
        builder = const CameraTranslatePage();
        break;
      case '/voice_translate':
        builder = const VoiceTranslatePage();
        break;
      case '/saved_translations':
        builder = const SavedTranslationsPage();
        break;
      case '/history_saved':
        builder =
            HistorySavedPage(initialIndex: settings.arguments as int? ?? 0);
        break;
      case '/settings':
        builder = const SettingsPage();
        break;
      case '/help_support':
        builder = const HelpSupportPage();
        break;
      case '/emergency':
        builder = const EmergencyPage();
        break;
      case '/offline_models':
        builder = const OfflineModelsPage();
        break;
      case '/translation_mode':
        builder = const TranslationModePage();
        break;
      case '/explain_mode':
        builder = const ExplainModePage();
        break;
      case '/assistant_mode':
        builder = const AssistantModePage();
        break;
      case '/text_translate':
        builder = const TextTranslatePage();
        break;
      case '/simplify_mode':
        builder = const SimplifyModePage();
        break;
      case '/error':
        builder = ErrorFallbackPage(
            error: settings.arguments as String? ?? 'Unknown error');
        break;
      default:
        builder = ErrorFallbackPage(error: 'Route not found: $routeName');
    }

    return MaterialPageRoute(builder: (_) => builder, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = Provider.of<AccessibilityService>(context);
    return MaterialApp(
      title: 'BhashaLens',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: accessibilityService.themeMode,
      debugShowCheckedModeBanner: false,
      home: _showSplash
          ? SplashScreen(onComplete: () => setState(() => _showSplash = false))
          : (_isOnboardingCompleted
              ? const HomePage()
              : const OnboardingPage()),
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
