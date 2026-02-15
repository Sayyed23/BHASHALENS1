# Implementation Plan: BhashaLens Technical Specification

## Overview

This implementation plan tracks the BhashaLens Flutter application development status. The application uses a service-oriented architecture with offline-first principles, integrating Gemini AI for online translation and ML Kit for offline capabilities.

**Current Status**: Core application is implemented with Translation Mode, Voice Translation, Camera OCR, Explain Mode, and Assistant Mode functional. Firebase authentication and Firestore sync are integrated. Accessibility features are partially implemented.

**Note**: This application uses Gemini AI (not Sarvam AI as originally planned) for online translation services.

## Completed Tasks

### Phase 1: Foundation & Core Services ✅

- [x] 1. Set up project structure and dependencies
  - ✅ Created Flutter project with proper directory structure (lib/services, lib/models, lib/pages, lib/widgets, lib/theme, lib/data)
  - ✅ Added all required dependencies including provider, sqflite, firebase, ML Kit, camera, speech services
  - ✅ Configured Firebase with firebase_options.dart
  - ✅ Set up environment configuration with flutter_dotenv
  - ✅ Created comprehensive service architecture
  - **Location**: `pubspec.yaml`, `lib/main.dart`

- [x] 2. Implement data models
  - ✅ SavedTranslation model with Firestore and SQLite support
  - ✅ ConversationMessage model for voice translation
  - ✅ AccessibilitySettings model with comprehensive settings
  - ✅ VoiceCommand, AudioFeedbackConfig, ExplanationResult, DetectedIntent models
  - **Location**: `lib/models/`

- [x] 3. Implement Local Storage Service
  - ✅ SQLite database with translations and languagePacks tables
  - ✅ Database migrations (version 2)
  - ✅ Translation CRUD operations
  - ✅ SharedPreferences for app preferences
  - ✅ API usage tracking with thread-safe increment
  - ✅ Onboarding completion tracking
  - ✅ Web platform fallback (no-op for SQLite)
  - **Location**: `lib/services/local_storage_service.dart`

- [x] 4. Implement Firebase Services
  - ✅ FirebaseAuthService with email/password, Google Sign-In, anonymous auth
  - ✅ FirestoreService for cloud sync (implementation exists)
  - ✅ Graceful fallback when Firebase unavailable
  - **Location**: `lib/services/firebase_auth_service.dart`, `lib/services/firestore_service.dart`

- [x] 5. Implement ML Kit Translation Service
  - ✅ On-device translation using Google ML Kit
  - ✅ Model download and management
  - ✅ Bidirectional translation support
  - ✅ Two-step translation via English for non-English pairs
  - ✅ Text recognition from images (OCR)
  - ✅ Model availability checking
  - ✅ Missing model detection with user-friendly messages
  - **Location**: `lib/services/ml_kit_translation_service.dart`

- [x] 6. Implement Gemini AI Service
  - ✅ Text translation with Gemini 2.0 Flash
  - ✅ OCR (text extraction from images)
  - ✅ Language detection
  - ✅ Text explanation and simplification
  - ✅ Context-aware explanations with JSON output
  - ✅ Text refinement (confident, professional, polite styles)
  - ✅ Basic guides generation
  - ✅ Roleplay session for assistant mode
  - ✅ Chat functionality with conversation history
  - ✅ API usage limit tracking (20 calls limit)
  - **Location**: `lib/services/gemini_service.dart`

- [x] 7. Implement Voice Translation Service
  - ✅ Speech-to-text using speech_to_text package
  - ✅ Text-to-speech using flutter_tts package
  - ✅ Conversation mode with language alternation
  - ✅ Conversation history tracking
  - ✅ Offline/online mode detection
  - ✅ Automatic fallback to ML Kit when offline
  - ✅ Language detection integration
  - ✅ Support for 20+ languages
  - **Location**: `lib/services/voice_translation_service.dart`

- [x] 8. Implement Enhanced Accessibility Service
  - ✅ Abstract interfaces for voice navigation, audio feedback, visual accessibility
  - ✅ AccessibilityController with settings management
  - ✅ Dependency injection container
  - ✅ SharedPreferences integration for persistence
  - ✅ Voice navigation service interface
  - ✅ Audio feedback service interface
  - ✅ Visual accessibility controller interface
  - **Location**: `lib/services/enhanced_accessibility_service.dart`

- [x] 9. Implement Basic Accessibility Service
  - ✅ Theme management (light, dark modes)
  - ✅ Text size scaling
  - ✅ ThemeMode provider
  - **Location**: `lib/services/accessibility_service.dart`

### Phase 2: UI Implementation ✅

- [x] 10. Implement Authentication UI
  - ✅ Splash screen with initialization
  - ✅ Onboarding flow
  - ✅ Login page (email/password, Google Sign-In)
  - ✅ Signup page
  - ✅ Forgot password page
  - **Location**: `lib/pages/auth/`, `lib/pages/splash_screen.dart`, `lib/pages/onboarding_page.dart`

- [x] 11. Implement Home and Navigation
  - ✅ Home page with bottom navigation
  - ✅ Home content with quick access grid
  - ✅ Navigation to all modes
  - ✅ Connectivity indicator
  - ✅ Language swap button
  - ✅ Settings access
  - **Location**: `lib/pages/home_page.dart`, `lib/pages/home/home_content.dart`

- [x] 12. Implement Translation Mode UI
  - ✅ Translation mode selection page
  - ✅ Text translation page
  - ✅ Voice translation page with conversation mode
  - ✅ Camera translation page with OCR
  - ✅ Language selection
  - ✅ Offline mode indicators
  - ✅ Save, share, copy functionality
  - **Location**: `lib/pages/translation_mode_page.dart`, `lib/pages/text_translate_page.dart`, `lib/pages/voice_translate_page.dart`, `lib/pages/camera_translate_page.dart`

- [x] 13. Implement Camera OCR Mode
  - ✅ Camera preview with focus area
  - ✅ Image capture and gallery import
  - ✅ Flash control
  - ✅ OCR processing with Gemini (online) and ML Kit (offline)
  - ✅ Translation overlay
  - ✅ Result display with draggable sheet
  - ✅ Copy, save, share, explain actions
  - ✅ Language picker
  - ✅ Offline model checking
  - **Location**: `lib/pages/camera_translate_page.dart`

- [x] 14. Implement Explain Mode
  - ✅ Explain mode page with text input
  - ✅ Context-aware explanations
  - ✅ Simplification levels
  - ✅ Cultural insights
  - ✅ Situational examples
  - ✅ Follow-up questions
  - ✅ Safety notes
  - ✅ Basic guides for scenarios
  - **Location**: `lib/pages/explain_mode_page.dart`

- [x] 15. Implement Assistant Mode
  - ✅ Assistant mode page
  - ✅ Roleplay scenarios
  - ✅ Grammar correction
  - ✅ Pronunciation guidance
  - ✅ Chat interface
  - ✅ Voice input integration
  - **Location**: `lib/pages/assistant_mode_page.dart`

- [x] 16. Implement History and Saved Translations
  - ✅ History/Saved page with tabs
  - ✅ Translation history display
  - ✅ Favorites filtering
  - ✅ Search functionality
  - ✅ Delete and share actions
  - ✅ Category display
  - **Location**: `lib/pages/history_saved_page.dart`, `lib/pages/saved_translations_page.dart`

- [x] 17. Implement Settings
  - ✅ Settings page with categories
  - ✅ Profile management
  - ✅ Language preferences
  - ✅ Offline models management
  - ✅ Accessibility settings
  - ✅ Notifications preferences
  - ✅ Privacy and security
  - ✅ Help and support
  - ✅ Account management (logout, delete account)
  - **Location**: `lib/pages/settings_page.dart`, `lib/pages/offline_models_page.dart`

- [x] 18. Implement Additional Pages
  - ✅ Help and support page
  - ✅ Emergency page (SOS)
  - ✅ Error fallback page
  - ✅ Offline mode page
  - **Location**: `lib/pages/help_support_page.dart`, `lib/pages/emergency_page.dart`, `lib/pages/error_fallback_page.dart`, `lib/pages/offline_mode_page.dart`

### Phase 3: Theme and Styling ✅

- [x] 19. Implement Theme System
  - ✅ Dark theme with custom colors
  - ✅ Light theme
  - ✅ App colors configuration
  - ✅ Material Design 3 components
  - ✅ Responsive layouts
  - **Location**: `lib/theme/app_theme.dart`, `lib/theme/app_colors.dart`

- [x] 20. Implement Widgets
  - ✅ Home widgets (quick access cards, recent activity)
  - ✅ Responsive layout utilities
  - **Location**: `lib/widgets/`

### Phase 4: Advanced Features (Partial) ⚠️

- [x] 21. Implement Connectivity Management
  - ✅ Connectivity detection using connectivity_plus
  - ✅ Offline/online mode switching
  - ✅ Connectivity indicator in UI
  - ✅ Automatic service routing based on connectivity
  - **Location**: Integrated in `lib/services/voice_translation_service.dart`, `lib/pages/camera_translate_page.dart`, `lib/pages/home_page.dart`

- [x] 22. Implement Database Initialization
  - ✅ Platform-specific database factory initialization
  - ✅ IO platform support
  - ✅ Web platform stub
  - **Location**: `lib/services/db_initializer.dart`, `lib/services/db_initializer_io.dart`, `lib/services/db_initializer_web.dart`, `lib/services/db_initializer_stub.dart`

## Pending Tasks

### Phase 5: Advanced Accessibility Features 🔄

- [ ] 23. Complete Voice Navigation Implementation
  - [ ] 23.1 Implement voice command recognition
    - Create command parser for navigation commands
    - Implement context-aware command handling
    - Add command feedback system
    - **Location**: `lib/services/voice_navigation/`
  
  - [ ] 23.2 Implement page-specific commands
    - Add commands for each page/mode
    - Implement command execution
    - Add help command to list available commands
  
  - [ ] 23.3 Test voice navigation
    - Test all navigation commands
    - Test in noisy environments
    - Verify audio feedback

- [ ] 24. Complete Audio Feedback System
  - [ ] 24.1 Implement TTS engine
    - Complete TTS engine implementation
    - Add voice selection
    - Add speech rate and pitch control
    - **Location**: `lib/services/audio_feedback/tts_engine.dart`
  
  - [ ] 24.2 Implement audio cue system
    - Complete audio cue generation
    - Add configurable cues for different events
    - Implement volume control
    - **Location**: `lib/services/audio_feedback/audio_cue_system.dart`
  
  - [ ] 24.3 Implement audio feedback service
    - Complete service implementation
    - Add page change announcements
    - Add button action announcements
    - Add error/success announcements
    - **Location**: `lib/services/audio_feedback/audio_feedback_service.dart`

- [ ] 25. Implement Visual Accessibility Features
  - [ ] 25.1 Create high contrast theme
    - Design high contrast color scheme
    - Implement theme switching
    - Test contrast ratios (WCAG AA)
  
  - [ ] 25.2 Implement simplified UI mode
    - Create simplified layouts
    - Remove non-essential elements
    - Increase spacing
  
  - [ ] 25.3 Implement focus indicators
    - Add visible focus indicators
    - Ensure keyboard navigation works
  
  - [ ] 25.4 Implement color blind support
    - Add color blind friendly palettes
    - Use patterns in addition to colors

### Phase 6: Testing & Quality Assurance 📝

- [ ] 26. Write Unit Tests
  - [ ] 26.1 Test data models
    - Test serialization/deserialization
    - Test validation logic
  
  - [ ] 26.2 Test services
    - Test GeminiService methods
    - Test MlKitTranslationService methods
    - Test VoiceTranslationService methods
    - Test LocalStorageService methods
    - Test FirebaseAuthService methods
  
  - [ ] 26.3 Test providers
    - Test state management
    - Test notifyListeners calls

- [ ] 27. Write Widget Tests
  - [ ] 27.1 Test authentication screens
    - Test form validation
    - Test button interactions
  
  - [ ] 27.2 Test translation screens
    - Test input/output display
    - Test language selection
    - Test mode switching
  
  - [ ] 27.3 Test settings screens
    - Test preference updates
    - Test model management

- [ ] 28. Write Integration Tests
  - [ ] 28.1 Test end-to-end flows
    - Test text translation flow
    - Test voice translation flow
    - Test camera OCR flow
    - Test authentication flow
  
  - [ ] 28.2 Test offline-online transitions
    - Test service switching
    - Test data sync

- [ ] 29. Write Property-Based Tests
  - [ ] 29.1 Translation properties
    - Property 1: Language detection accuracy
    - Property 2: Offline routing with downloaded models
    - Property 3: Indian language pair routing
    - Property 4: Fallback chain execution
    - Property 5: Translation persistence
    - Property 6: Favorite marking
  
  - [ ] 29.2 Voice translation properties
    - Property 8: Speech to translation pipeline
    - Property 9: Translation to speech pipeline
    - Property 10: Conversation language alternation
    - Property 11: Conversation message persistence
    - Property 12: Conversation history completeness
  
  - [ ] 29.3 OCR properties
    - Property 13: Multi-block translation
    - Property 14: Translation overlay positioning
    - Property 15: OCR translation persistence
    - Property 16: Offline OCR routing
  
  - [ ] 29.4 Storage properties
    - Property 33: History timestamp ordering
    - Property 34: History search filtering
    - Property 35: Favorites filtering
    - Property 36: Deletion dual removal
    - Property 38: History archival with favorites preservation
  
  - [ ] 29.5 Authentication properties
    - Property 28: Authentication token provision
    - Property 29: Logout cleanup
    - Property 31: Anonymous account data migration
    - Property 32: Authentication error messaging
  
  - [ ] 29.6 Sync properties
    - Property 52: Initial sync download
    - Property 53: Online immediate upload
    - Property 54: Offline change queuing
    - Property 55: Reconnection sync execution
    - Property 56: Conflict resolution by timestamp
    - Property 57: Deletion propagation
    - Property 59: Sync retry with exponential backoff

### Phase 7: Performance & Optimization ⚡

- [ ] 30. Performance Optimization
  - [ ] 30.1 Optimize database queries
    - Add database indexes
    - Implement query result caching
    - Use batch operations
  
  - [ ] 30.2 Optimize image processing
    - Implement image compression
    - Add image caching
    - Use background isolates for OCR
  
  - [ ] 30.3 Optimize memory usage
    - Implement proper disposal
    - Clear caches when memory is low
    - Use lazy loading for large lists
  
  - [ ] 30.4 Run performance benchmarks
    - Measure app launch time
    - Measure translation latency
    - Measure memory usage
    - Measure battery usage

- [ ] 31. Accessibility Testing
  - [ ] 31.1 Test with screen readers
    - Test with TalkBack (Android)
    - Test with VoiceOver (iOS)
    - Verify semantic labels
  
  - [ ] 31.2 Test voice navigation
    - Test all voice commands
    - Verify audio feedback
  
  - [ ] 31.3 Test visual accessibility
    - Verify color contrast ratios
    - Test text scaling up to 200%
    - Test high contrast theme
    - Test touch target sizes

### Phase 8: Security & Privacy 🔒

- [ ] 32. Security Audit
  - [ ] 32.1 Review API key storage
    - Verify secure storage usage
    - Check for hardcoded keys
    - Test key rotation
  
  - [ ] 32.2 Review data transmission
    - Verify HTTPS usage
    - Check TLS version
    - Test certificate pinning
  
  - [ ] 32.3 Review data storage
    - Verify password hashing
    - Check for plain text sensitive data
    - Test data deletion
  
  - [ ] 32.4 Review logging
    - Verify PII exclusion
    - Check error logs
    - Test log sanitization

- [ ] 33. Implement Additional Security Features
  - [ ] 33.1 Add session timeout
    - Implement session tracking
    - Add re-authentication prompt
  
  - [ ] 33.2 Add data encryption
    - Encrypt sensitive local data
    - Implement secure key management

### Phase 9: Localization & Internationalization 🌍

- [ ] 34. Implement Localization
  - [ ] 34.1 Set up localization framework
    - Add flutter_localizations dependency
    - Create ARB files for supported languages
    - Generate localization classes
  
  - [ ] 34.2 Translate UI strings
    - Translate to Hindi, Bengali, Tamil, Telugu, etc.
    - Add language-specific fonts
    - Test RTL layout for Arabic/Urdu

### Phase 10: Analytics & Monitoring 📊

- [ ] 35. Implement Analytics
  - [ ] 35.1 Create AnalyticsService
    - Implement event logging
    - Add opt-out functionality
    - Implement offline event queuing
    - Add batch transmission
  
  - [ ] 35.2 Add analytics events
    - Translation events
    - Feature usage events
    - Error events
    - Performance metrics

- [ ] 36. Implement Error Tracking
  - [ ] 36.1 Set up error reporting
    - Integrate crash reporting service
    - Add error context collection
    - Implement PII sanitization

### Phase 11: Platform-Specific Features 📱

- [ ] 37. Platform-Specific Testing
  - [ ] 37.1 Test on Android
    - Test on Android 5.0 (API 21)
    - Test on latest Android version
    - Test on different screen sizes
    - Test on low-end devices
  
  - [ ] 37.2 Test on iOS
    - Test on iOS 12.0
    - Test on latest iOS version
    - Test on different iPhone models
    - Test on iPad
  
  - [ ] 37.3 Test on Web
    - Test on Chrome, Firefox, Safari, Edge
    - Test responsive design
    - Test keyboard navigation

- [ ] 38. Platform-Specific Optimizations
  - [ ] 38.1 Android optimizations
    - Optimize APK size
    - Add ProGuard rules
    - Test on different Android versions
  
  - [ ] 38.2 iOS optimizations
    - Optimize IPA size
    - Test on different iOS versions
    - Ensure App Store compliance
  
  - [ ] 38.3 Web optimizations
    - Optimize bundle size
    - Add PWA support
    - Implement service workers

### Phase 12: Documentation & Deployment 📚

- [ ] 39. Documentation
  - [ ] 39.1 Write technical documentation
    - Document architecture and design decisions
    - Document API integration
    - Document database schema
    - Create developer setup guide
  
  - [ ] 39.2 Write user documentation
    - Create user guide for each mode
    - Document accessibility features
    - Create FAQ
    - Create troubleshooting guide
  
  - [ ] 39.3 Create API documentation
    - Document Gemini API integration
    - Document ML Kit usage
    - Document Firebase integration

- [ ] 40. Prepare for Deployment
  - [ ] 40.1 Configure app signing
    - Set up Android signing
    - Set up iOS signing
  
  - [ ] 40.2 Set up CI/CD pipeline
    - Configure automated builds
    - Add automated testing
    - Set up deployment automation
  
  - [ ] 40.3 Create release builds
    - Build Android APK/AAB
    - Build iOS IPA
    - Build web bundle
  
  - [ ] 40.4 Create demo materials
    - Create app screenshots
    - Create demo video
    - Prepare pitch deck

### Phase 13: Additional Features (Future) 🚀

- [ ] 41. Implement Notifications
  - [ ] 41.1 Create notification service
    - Implement local notifications
    - Add notification for model download completion
    - Add notification for sync conflicts
    - Add notification for API limit warning

- [ ] 42. Implement Offline Explain Service
  - [ ] 42.1 Create rule-based explanation system
    - Implement template service
    - Create explanation templates
    - Add rule engine for offline explanations
    - **Location**: `lib/services/offline_explain_service.dart`, `lib/services/template_service.dart`, `lib/services/rule_engine.dart`, `lib/data/explanation_templates.dart`

- [ ] 43. Implement Whisper Service (Optional)
  - [ ] 43.1 Integrate Whisper for speech recognition
    - Add Whisper model integration
    - Implement offline speech recognition
    - **Location**: `lib/services/whisper_service.dart`

- [ ] 44. Implement Advanced Features
  - [ ] 44.1 Add conversation export
    - Export to PDF
    - Export to text file
    - Share via email
  
  - [ ] 44.2 Add translation history analytics
    - Show usage statistics
    - Show most translated languages
    - Show translation trends
  
  - [ ] 44.3 Add custom vocabulary
    - Allow users to add custom translations
    - Implement vocabulary management
    - Add vocabulary sync

## Notes

- ✅ = Completed
- 🔄 = In Progress
- ⚠️ = Partially Implemented
- 📝 = Needs Testing
- ⚡ = Needs Optimization
- 🔒 = Security Related
- 🌍 = Localization Related
- 📊 = Analytics Related
- 📱 = Platform Specific
- 📚 = Documentation
- 🚀 = Future Enhancement

### Implementation Notes

1. **Gemini AI Integration**: The application uses Gemini AI (gemini-2.0-flash model) for online translation, OCR, language detection, explanations, and assistant features. API usage is limited to 20 calls and tracked in local storage.

2. **ML Kit Integration**: Google ML Kit is used for offline translation and text recognition. The service supports bidirectional translation with automatic two-step translation via English for non-English language pairs.

3. **Offline-First Architecture**: The application automatically detects connectivity and routes requests to appropriate services (ML Kit for offline, Gemini for online).

4. **Firebase Integration**: Firebase Authentication (email/password, Google Sign-In, anonymous) and Firestore are integrated with graceful fallback when unavailable.

5. **Accessibility**: Basic accessibility features (theme switching, text scaling) are implemented. Advanced features (voice navigation, audio feedback, visual enhancements) are partially implemented with interfaces defined.

6. **State Management**: Provider pattern is used throughout the application for state management.

7. **Platform Support**: The application supports Android, iOS, and Web (with platform-specific fallbacks for SQLite and other native features).

8. **Testing**: Comprehensive testing (unit, widget, integration, property-based) is pending but test infrastructure is ready.

### Priority for Next Phase

1. **Complete Accessibility Features** (Phase 5) - Critical for target users
2. **Write Tests** (Phase 6) - Essential for quality assurance
3. **Performance Optimization** (Phase 7) - Important for user experience
4. **Security Audit** (Phase 8) - Critical before production release
5. **Documentation** (Phase 12) - Important for maintenance and onboarding

### Known Issues

1. **API Usage Limit**: Gemini API usage is limited to 20 calls. Need to implement proper quota management or upgrade plan.
2. **Offline Explain Mode**: Currently requires online connection. Offline explain service with templates is planned but not implemented.
3. **Voice Navigation**: Interface defined but implementation incomplete.
4. **Audio Feedback**: Partial implementation, needs completion.
5. **Localization**: UI strings are hardcoded in English, need to implement proper localization.
6. **Testing**: No tests written yet, comprehensive test suite needed.

### Code Quality Metrics (Target)

- Code Coverage: 80% minimum for service layer
- Property Tests: 100 iterations minimum per property
- Widget Tests: All critical user flows
- Integration Tests: End-to-end scenarios
- Performance: App launch < 3s, Translation latency < 2s

