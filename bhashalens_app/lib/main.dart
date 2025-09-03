import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:bhashalens_app/pages/onboarding_page.dart';
import 'package:bhashalens_app/pages/auth/login_page.dart';
import 'package:bhashalens_app/pages/auth/signup_page.dart';
import 'package:bhashalens_app/pages/auth/forgot_password_page.dart';
import 'package:bhashalens_app/pages/auth/reset_password_page.dart';
import 'package:bhashalens_app/pages/home_page.dart';
import 'package:bhashalens_app/pages/camera_translate_page.dart';
import 'package:bhashalens_app/pages/voice_translate_page.dart';
import 'package:bhashalens_app/pages/offline_mode_page.dart';
import 'package:bhashalens_app/pages/saved_translations_page.dart';
import 'package:bhashalens_app/pages/settings_page.dart';
import 'package:bhashalens_app/pages/help_support_page.dart';
import 'package:bhashalens_app/pages/emergency_page.dart';
import 'package:bhashalens_app/services/accessibility_service.dart';
import 'package:bhashalens_app/services/supabase_auth_service.dart';
import 'package:bhashalens_app/services/local_storage_service.dart'; // Import LocalStorageService
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:bhashalens_app/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // TODO: Replace with your actual Supabase URL and anon key
  await Supabase.initialize(
    url: 'https://fpxczbnluwmxsdpkyddl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZweGN6Ym5sdXdteHNkcGt5ZGRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3MjkzNjQsImV4cCI6MjA3MjMwNTM2NH0.apU_DKxDUB5Ion8DI6nQNZUJ-uVu_emULzWdve-PPNg',
  );

  final localStorageService = LocalStorageService(); // Initialize service
  final isOnboardingCompleted = await localStorageService
      .isOnboardingCompleted();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AccessibilityService()),
        Provider<SupabaseAuthService>(create: (_) => SupabaseAuthService()),
        Provider<LocalStorageService>.value(
          value: localStorageService,
        ), // Provide LocalStorageService
        Provider<GeminiService>(
          create: (_) => GeminiService(apiKey: dotenv.env['GEMINI_API_KEY']!),
        ),
        ChangeNotifierProvider<VoiceTranslationService>(
          create: (_) => VoiceTranslationService(),
        ),
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
  User? _user;
  final AppLinks _appLinks = AppLinks();
  // Removed unused declaration of _localStorageService

  @override
  void initState() {
    super.initState();
    // Removed unused assignment from Provider.of
    _getAuth();
    _initDeepLinking();
  }

  Future<void> _getAuth() async {
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
        });
      }
    });
  }

  void _initDeepLinking() {
    // Handle initial link if app was launched from a link
    // _appLinks.getInitialAppLink().then((link) {
    //   if (link != null) {
    //     _handleDeepLink(link);
    //   }
    // });

    // Handle links when app is already running
    // Temporarily disabled to fix Navigator context issues
    // _appLinks.uriLinkStream.listen((link) {
    //   if (mounted) {
    //     _handleDeepLink(link);
    //   }
    // });
  }

  void _handleDeepLink(Uri? link) {
    if (link != null && mounted) {
      final uri = link.toString();

      // Prioritize onboarding if not completed
      if (!widget.isOnboardingCompleted && !uri.contains('/onboarding')) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
        return;
      }

      if (uri.contains('/onboarding')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
        }
      } else if (uri.contains('/login')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else if (uri.contains('/signup')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signup', (route) => false);
        }
      } else if (uri.contains('/forgot_password')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/forgot_password', (route) => false);
        }
      } else if (uri.contains('/reset_password')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/reset_password', (route) => false);
        }
      } else if (uri.contains('/home')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else if (uri.contains('/camera_translate')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/camera_translate', (route) => false);
        }
      } else if (uri.contains('/voice_translate')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/voice_translate', (route) => false);
        }
      } else if (uri.contains('/offline_mode')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/offline_mode', (route) => false);
        }
      } else if (uri.contains('/saved_translations')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/saved_translations', (route) => false);
        }
      } else if (uri.contains('/settings')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/settings', (route) => false);
        }
      } else if (uri.contains('/help_support')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/help_support', (route) => false);
        }
      } else if (uri.contains('/emergency')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/emergency', (route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = Provider.of<AccessibilityService>(context);

    Widget initialRoute;
    if (!widget.isOnboardingCompleted) {
      initialRoute = const OnboardingPage();
    } else if (_user == null) {
      initialRoute = const LoginPage();
    } else {
      initialRoute = const HomePage();
    }

    return MaterialApp(
      title: 'BhashaLens',
      theme: accessibilityService.highContrastMode
          ? AppTheme.darkTheme.copyWith(
              textTheme: AppTheme.darkTheme.textTheme.apply(
                fontSizeFactor: accessibilityService.textSizeFactor,
              ),
            )
          : AppTheme.lightTheme.copyWith(
              textTheme: AppTheme.lightTheme.textTheme.apply(
                fontSizeFactor: accessibilityService.textSizeFactor,
              ),
            ),
      debugShowCheckedModeBanner: false,
      // Use a builder to listen to auth state and decide initial route
      home: initialRoute,
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/reset_password': (context) => const ResetPasswordPage(),
        '/home': (context) => const HomePage(),
        '/camera_translate': (context) => const CameraTranslatePage(),
        '/voice_translate': (context) => const VoiceTranslatePage(),
        '/offline_mode': (context) => const OfflineModePage(),
        '/saved_translations': (context) => const SavedTranslationsPage(),
        '/settings': (context) => const SettingsPage(),
        '/help_support': (context) => const HelpSupportPage(),
        '/emergency': (context) => const EmergencyPage(),
      },
    );
  }
}
