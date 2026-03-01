# Implementation Plan: BhashaLens Production-Ready

## Overview

This implementation plan transforms BhashaLens into a production-ready, offline-first Android application with cloud augmentation. The architecture prioritizes on-device AI processing using quantized models while intelligently leveraging AWS cloud services when available. Implementation follows a phased approach focusing on core offline functionality first, then progressively adding voice, OCR, LLM assistance, and cloud integration.

The implementation uses Kotlin for Android development with Jetpack Compose for UI, integrating native libraries (llama.cpp JNI, Vosk/Whisper, Tesseract/ML Kit) for on-device AI processing.

## Tasks

- [x] 1. Set up project structure and core architecture
  - Create Kotlin package structure for offline-first architecture
  - Set up Gradle dependencies for Jetpack Compose, SQLCipher, WorkManager, Retrofit
  - Configure ProGuard/R8 rules for model optimization
  - Define core domain models (Language, LanguagePair, ProcessingBackend enums)
  - Create base interfaces for all major components
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Implement encrypted local storage layer
  - [x] 2.1 Create SQLCipher database with schema
    - Implement database schema for translation_history, user_preferences, translation_cache, conversation_history, language_pack_metadata tables
    - Configure AES-256 encryption with Android Keystore integration
    - _Requirements: 9.1, 9.2, 9.6_
  
  - [ ]* 2.2 Write property test for data encryption
    - **Property 24: Data encryption**
    - **Validates: Requirements 9.2**
  
  - [x] 2.3 Implement LocalStorage interface
    - Write methods for saveTranslation, getTranslationHistory, searchTranslationHistory, deleteTranslationHistory
    - Implement preference management (savePreference, getPreference)
    - Implement translation caching (cacheTranslation, getCachedTranslation)
    - Implement conversation history management
    - _Requirements: 9.2, 9.3, 9.4_
  
  - [ ]* 2.4 Write property tests for storage operations
    - **Property 25: Translation history retrieval ordering**
    - **Property 26: Data deletion completeness**
    - **Property 27: Encryption key security**
    - **Validates: Requirements 15.6, 9.4, 9.6**
  
  - [ ]* 2.5 Write unit tests for LocalStorage
    - Test edge cases for empty history, large datasets, concurrent access
    - Test cache expiration and cleanup
    - _Requirements: 9.2_

- [x] 3. Implement Translation Engine with quantized models
  - [x] 3.1 Integrate Marian NMT or Distilled NLLB models
    - Set up model loading infrastructure for INT8 quantized models
    - Implement model inference using ONNX Runtime or TensorFlow Lite
    - Create language pair model registry
    - _Requirements: 2.5, 2.6_
  
  - [x] 3.2 Implement TranslationEngine interface
    - Write initialize method for loading language-specific models
    - Implement translate method with confidence scoring
    - Implement isLanguagePairAvailable check
    - Add model resource management (release method)
    - _Requirements: 2.1, 2.4_
  
  - [ ]* 3.3 Write property tests for Translation Engine
    - **Property 1: Offline translation availability**
    - **Property 2: Translation latency target**
    - **Property 3: Language pair bidirectionality**
    - **Property 5: Translation cache consistency**
    - **Validates: Requirements 1.1, 2.1, 2.4, 9.2**
  
  - [ ]* 3.4 Write unit tests for Translation Engine
    - Test translation quality with sample phrases
    - Test error handling for invalid inputs
    - Test model loading failures
    - _Requirements: 2.1, 2.6_

- [ ] 4. Implement Language Pack Manager
  - [ ] 4.1 Create language pack download infrastructure
    - Implement LanguagePackManager interface with download, delete, verify methods
    - Set up HTTP client for downloading from S3/CDN with progress tracking
    - Implement checksum verification (SHA-256)
    - Create file system structure for language pack storage
    - _Requirements: 8.1, 8.2, 8.5, 8.6_
  
  - [ ]* 4.2 Write property tests for Language Pack Manager
    - **Property 20: Language pack size constraint**
    - **Property 21: Download integrity verification**
    - **Property 22: Storage availability check**
    - **Property 23: Language pack availability**
    - **Validates: Requirements 8.2, 8.6, 8.7, 8.3**
  
  - [ ] 4.3 Implement language pack update mechanism
    - Implement checkForUpdates and updateLanguagePack methods
    - Add rollback capability for failed updates
    - Store language pack metadata in LocalStorage
    - _Requirements: 14.1, 14.2, 14.5_
  
  - [ ]* 4.4 Write unit tests for update mechanism
    - Test update detection logic
    - Test rollback on failure
    - Test incremental updates
    - _Requirements: 14.3, 14.5_

- [x] 5. Checkpoint - Ensure basic translation works offline
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement Voice Processor for STT and TTS
  - [ ] 6.1 Integrate Vosk or Whisper Small for STT
    - Set up Vosk or Whisper Small (4-bit quantized) model loading
    - Implement VoiceProcessor interface with speechToText method
    - Add audio recording and preprocessing
    - _Requirements: 3.1, 3.4_
  
  - [ ] 6.2 Integrate Android TTS for speech synthesis
    - Implement textToSpeech method using Android native TTS
    - Configure language-specific voices for Hindi, Marathi, English
    - _Requirements: 3.2, 3.5_
  
  - [ ] 6.3 Implement voice translation pipeline
    - Implement voiceTranslate method combining STT, Translation, TTS
    - Ensure raw audio is not permanently stored
    - _Requirements: 2.2, 3.3, 3.6_
  
  - [ ]* 6.4 Write property tests for Voice Processor
    - **Property 6: Voice roundtrip latency**
    - **Property 7: Voice data privacy**
    - **Property 8: STT accuracy threshold**
    - **Validates: Requirements 3.3, 13.2, 3.6, 9.3, 3.7**
  
  - [ ]* 6.5 Write unit tests for Voice Processor
    - Test STT with sample audio files
    - Test TTS output quality
    - Test error handling for unsupported languages
    - _Requirements: 3.1, 3.2_

- [ ] 7. Implement OCR Engine for image text extraction
  - [ ] 7.1 Integrate Tesseract or ML Kit for OCR
    - Set up Tesseract 5.x or Google ML Kit
    - Configure support for Devanagari (Hindi, Marathi) and Latin (English) scripts
    - Implement image preprocessing (contrast, brightness, deskewing)
    - _Requirements: 4.1, 4.2_
  
  - [ ] 7.2 Implement OCREngine interface
    - Write extractText method with confidence scoring
    - Implement extractTextRegions for multi-region detection
    - Add language detection for extracted text
    - _Requirements: 4.3, 4.4_
  
  - [ ]* 7.3 Write property tests for OCR Engine
    - **Property 9: OCR processing latency**
    - **Property 10: OCR accuracy threshold**
    - **Property 11: Multi-script support**
    - **Validates: Requirements 4.4, 4.5, 4.2**
  
  - [ ]* 7.4 Write unit tests for OCR Engine
    - Test with sample images containing Hindi, Marathi, English text
    - Test error handling for low-quality images
    - Test multi-region extraction
    - _Requirements: 4.1, 4.6_

- [ ] 8. Implement LLM Assistant with on-device model
  - [ ] 8.1 Integrate llama.cpp via JNI for GGUF model inference
    - Set up llama.cpp JNI bindings for Android
    - Implement model loading for 1B-3B parameter GGUF models (Phi-2, TinyLlama, Gemma-2B)
    - Configure 4-bit or 8-bit quantization
    - _Requirements: 5.4_
  
  - [ ] 8.2 Implement LLMAssistant interface for grammar checking
    - Write checkGrammar method with correction detection and explanations
    - Implement prompt engineering for grammar analysis
    - _Requirements: 5.1_
  
  - [ ] 8.3 Implement Q&A and conversation features
    - Write answerQuestion method with context support
    - Implement practiceConversation with conversation history management
    - Maintain context for up to 10 exchanges (~2048 tokens)
    - _Requirements: 5.2, 5.3, 5.7_
  
  - [ ] 8.4 Implement text simplification and explanation
    - Write simplifyText method with complexity level control
    - Implement explainText method with key term extraction
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.6_
  
  - [ ]* 8.5 Write property tests for LLM Assistant
    - **Property 12: Grammar correction completeness**
    - **Property 13: Conversation context maintenance**
    - **Property 14: Simplification accuracy**
    - **Property 15: LLM response latency**
    - **Validates: Requirements 5.1, 5.7, 6.1, 6.5, 5.5, 13.6**
  
  - [ ]* 8.6 Write unit tests for LLM Assistant
    - Test grammar checking with sample texts
    - Test Q&A with various question types
    - Test conversation context preservation
    - Test simplification quality
    - _Requirements: 5.1, 5.2, 6.1_

- [ ] 9. Checkpoint - Ensure all offline modes work
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Implement Smart Hybrid Router
  - [ ] 10.1 Create routing decision engine
    - Implement HybridRouter interface with routing logic
    - Create RoutingContext data class for network, battery, preferences
    - Implement decision tree: offline → on-device, low battery → on-device, complex + online → cloud with fallback
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_
  
  - [ ]* 10.2 Write property tests for Smart Hybrid Router
    - **Property 16: Offline routing guarantee**
    - **Property 17: User preference respect**
    - **Property 18: Cloud fallback execution**
    - **Property 19: Battery-aware routing**
    - **Validates: Requirements 7.3, 7.6, 7.5, 11.7, 7.7**
  
  - [ ] 10.3 Implement request complexity analyzer
    - Create logic to classify requests as SIMPLE, MODERATE, COMPLEX
    - Consider text length, language pair, operation type
    - _Requirements: 7.2_
  
  - [ ]* 10.4 Write unit tests for routing logic
    - Test all routing decision paths
    - Test fallback scenarios
    - Test preference overrides
    - _Requirements: 7.1, 7.2_

- [ ] 11. Implement AWS Backend integration
  - [ ] 11.1 Create API Gateway client
    - Set up Retrofit client with HTTPS enforcement
    - Implement IAM authentication or API key management
    - Define API endpoints for /v1/translate, /v1/assist, /v1/simplify
    - _Requirements: 11.1, 12.1_
  
  - [ ] 11.2 Implement cloud request handlers
    - Create request/response models for cloud API
    - Implement timeout handling (5 second limit)
    - Add circuit breaker pattern for resilience
    - _Requirements: 11.2, 11.6, 17.6_
  
  - [ ]* 11.3 Write property tests for AWS integration
    - **Property 32: HTTPS enforcement**
    - **Property 33: Cloud response latency**
    - **Property 34: Cloud unavailability fallback**
    - **Validates: Requirements 11.1, 12.1, 11.6, 13.3, 11.7**
  
  - [ ]* 11.4 Write unit tests for API client
    - Test request serialization
    - Test error handling for network failures
    - Test timeout scenarios
    - _Requirements: 11.1, 11.6_

- [ ] 12. Implement AWS Lambda functions
  - [ ] 12.1 Create translation handler Lambda
    - Write Python Lambda function for translation using Amazon Bedrock
    - Implement request validation and error handling
    - Add CloudWatch logging
    - _Requirements: 11.2, 11.3_
  
  - [ ] 12.2 Create assistance handler Lambda
    - Write Lambda for grammar, Q&A, conversation using Bedrock
    - Implement context management for multi-turn conversations
    - _Requirements: 11.2, 11.3_
  
  - [ ] 12.3 Create simplification handler Lambda
    - Write Lambda for text simplification and explanation using Bedrock
    - _Requirements: 11.2, 11.3_
  
  - [ ]* 12.4 Write unit tests for Lambda functions
    - Test each handler with sample inputs
    - Test error handling and validation
    - Test Bedrock integration
    - _Requirements: 11.2_

- [ ] 13. Set up AWS infrastructure with Terraform
  - [ ] 13.1 Create Terraform configuration for API Gateway
    - Define REST API with HTTPS enforcement
    - Configure IAM authentication
    - Set up CORS and rate limiting
    - _Requirements: 11.1, 12.2_
  
  - [ ] 13.2 Create Terraform configuration for Lambda functions
    - Define Lambda functions with Python 3.11 runtime
    - Configure IAM roles with least privilege
    - Set up environment variables and timeouts
    - _Requirements: 11.2, 12.2_
  
  - [ ] 13.3 Create Terraform configuration for DynamoDB
    - Define UserPreferences, TranslationHistory, LanguagePackMetadata tables
    - Enable encryption at rest with AWS-managed keys
    - Configure on-demand capacity mode
    - _Requirements: 11.4, 12.4_
  
  - [ ] 13.4 Create Terraform configuration for S3
    - Define bucket for language packs and model artifacts
    - Enable AES-256 encryption at rest
    - Configure lifecycle policies
    - Set up CloudFront distribution for CDN
    - _Requirements: 11.5, 12.3_
  
  - [ ] 13.5 Create Terraform configuration for CloudWatch
    - Set up log groups for Lambda functions
    - Configure alarms for latency, errors, throttling
    - Set up X-Ray tracing
    - _Requirements: 11.6_
  
  - [ ]* 13.6 Write property test for data encryption at rest
    - **Property 35: Data encryption at rest**
    - **Validates: Requirements 11.3, 11.4**

- [ ] 14. Implement Sync Manager for background synchronization
  - [ ] 14.1 Create WorkManager jobs for sync operations
    - Implement SyncManager interface with syncNow, scheduleSyncJob methods
    - Set up WorkManager for reliable background execution
    - Configure constraints (network type, battery level)
    - _Requirements: 10.1, 10.2, 10.3_
  
  - [ ] 14.2 Implement sync logic with exponential backoff
    - Implement retry logic with 1s, 2s, 4s delays
    - Batch operations to minimize network requests
    - Implement delta sync for changed data only
    - _Requirements: 10.4_
  
  - [ ] 14.3 Implement preference and history sync
    - Sync user preferences to DynamoDB
    - Sync translation history with user consent check
    - Sync language pack metadata
    - _Requirements: 10.2, 10.7_
  
  - [ ]* 14.4 Write property tests for Sync Manager
    - **Property 28: Automatic sync trigger**
    - **Property 29: Background sync non-blocking**
    - **Property 30: Sync retry with backoff**
    - **Property 31: User consent for history sync**
    - **Validates: Requirements 10.1, 10.3, 10.4, 10.7**
  
  - [ ]* 14.5 Write unit tests for sync operations
    - Test sync success and failure scenarios
    - Test network constraint handling
    - Test user consent enforcement
    - _Requirements: 10.1, 10.4, 10.7_

- [ ] 15. Checkpoint - Ensure cloud integration works
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 16. Implement UI layer with Jetpack Compose
  - [ ] 16.1 Create mode selector screen
    - Design home screen with Translation, Assistance, Simplify mode cards
    - Implement navigation to each mode
    - Follow BhashaLens design system (blue-slate palette, Lexend/Source Sans 3 fonts)
    - _Requirements: 15.1_
  
  - [ ] 16.2 Create Translation Mode UI
    - Implement text input/output with language selector
    - Add voice input button with recording indicator
    - Add camera button for OCR translation
    - Display translation history with search/filter
    - _Requirements: 2.1, 2.2, 2.3, 15.6_
  
  - [ ] 16.3 Create Assistance Mode UI
    - Implement grammar check interface with corrections display
    - Create Q&A interface with context input
    - Create conversation practice interface with history
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 16.4 Create Simplify & Explain Mode UI
    - Implement text input with simplification level selector
    - Display simplified text and explanation side-by-side
    - _Requirements: 6.1, 6.2_
  
  - [ ] 16.5 Create Settings screen
    - Implement language pack management UI (download, delete, update)
    - Add data usage preferences (offline only, Wi-Fi only, cellular allowed)
    - Add sync preferences (timing, network type, history opt-in)
    - Add privacy controls (clear data, opt-out of cloud)
    - Display battery and data usage statistics
    - _Requirements: 8.4, 7.6, 10.5, 12.6, 16.3, 16.4_
  
  - [ ]* 16.6 Write unit tests for UI components
    - Test navigation flows
    - Test input validation
    - Test error message display
    - _Requirements: 15.1, 15.2_

- [ ] 17. Implement real-time feedback and progress indicators
  - [ ] 17.1 Add loading indicators for all processing operations
    - Show spinner during translation, voice processing, OCR
    - Display progress bars for language pack downloads
    - Show estimated time remaining
    - _Requirements: 15.2, 8.5_
  
  - [ ] 17.2 Implement haptic feedback
    - Add haptic feedback for voice recording start/stop
    - Add haptic feedback for translation complete
    - _Requirements: 15.4_
  
  - [ ] 17.3 Implement error messaging
    - Display clear error messages in user's preferred language
    - Provide actionable suggestions (retry, download language pack, check network)
    - _Requirements: 15.5, 17.1_

- [ ] 18. Implement accessibility features
  - [ ] 18.1 Add TalkBack support
    - Add content descriptions for all UI elements
    - Ensure proper focus order
    - Test with TalkBack enabled
    - _Requirements: 15.3_
  
  - [ ] 18.2 Add large text support
    - Implement dynamic text scaling
    - Test with system large text settings
    - _Requirements: 15.3_
  
  - [ ] 18.3 Add high contrast mode
    - Ensure sufficient color contrast ratios
    - Test with high contrast mode enabled
    - _Requirements: 15.3_

- [ ] 19. Implement resource management and optimization
  - [ ] 19.1 Implement model resource management
    - Release models when not in use
    - Implement lazy loading for models
    - Optimize memory footprint
    - _Requirements: 16.2, 16.7_
  
  - [ ] 19.2 Implement background processing limits
    - Disable non-essential background operations when battery < 15%
    - Limit background sync to essential operations
    - _Requirements: 16.1, 16.5_
  
  - [ ] 19.3 Add usage statistics tracking
    - Track battery usage by component
    - Track data usage for cloud requests
    - Display statistics in settings
    - _Requirements: 16.3, 16.4, 16.6_

- [ ] 20. Implement error handling and resilience
  - [ ] 20.1 Add comprehensive error handling
    - Implement error handling for translation failures
    - Detect and handle corrupted language packs
    - Handle cloud service unavailability with fallback
    - Handle storage full scenarios
    - _Requirements: 17.1, 17.2, 17.3, 17.4_
  
  - [ ] 20.2 Implement circuit breaker for cloud services
    - Add circuit breaker pattern to prevent cascading failures
    - Configure thresholds and recovery timeouts
    - _Requirements: 17.6_
  
  - [ ] 20.3 Add crash reporting
    - Implement crash reporting with user consent
    - Log unrecoverable errors for debugging
    - _Requirements: 17.7_
  
  - [ ]* 20.4 Write unit tests for error handling
    - Test all error scenarios
    - Test fallback mechanisms
    - Test circuit breaker behavior
    - _Requirements: 17.1, 17.6_

- [ ] 21. Implement security and privacy features
  - [ ] 21.1 Enforce HTTPS for all network communications
    - Configure Retrofit with HTTPS-only
    - Implement certificate pinning
    - _Requirements: 12.1_
  
  - [ ] 21.2 Implement privacy controls
    - Add opt-out for cloud features
    - Enforce no data transmission when opted out
    - Require explicit consent for voice data transmission
    - _Requirements: 12.5, 12.6, 12.7_
  
  - [ ]* 21.3 Write property tests for security and privacy
    - **Property 36: Voice transmission consent**
    - **Property 37: Privacy control availability**
    - **Property 38: Opt-out enforcement**
    - **Validates: Requirements 12.5, 12.6, 12.7**
  
  - [ ]* 21.4 Write unit tests for security features
    - Test HTTPS enforcement
    - Test opt-out enforcement
    - Test consent checks
    - _Requirements: 12.1, 12.7_

- [ ] 22. Implement performance monitoring and optimization
  - [ ] 22.1 Add performance metric logging
    - Implement PerformanceMetrics data class
    - Log metrics for all operations
    - Log when performance targets are not met
    - _Requirements: 13.7_
  
  - [ ]* 22.2 Write property tests for performance targets
    - **Property 2: Translation latency target**
    - **Property 6: Voice roundtrip latency**
    - **Property 9: OCR processing latency**
    - **Property 15: LLM response latency**
    - **Property 33: Cloud response latency**
    - **Property 39: Cold start latency**
    - **Property 40: UI responsiveness**
    - **Property 41: Performance metric logging**
    - **Validates: Requirements 2.1, 13.1, 3.3, 13.2, 4.4, 5.5, 13.6, 11.6, 13.3, 13.4, 13.5, 13.7**
  
  - [ ] 22.3 Optimize cold start performance
    - Implement lazy initialization for components
    - Optimize app startup sequence
    - Ensure home screen displays within 3 seconds
    - _Requirements: 13.4_
  
  - [ ]* 22.4 Write unit tests for performance monitoring
    - Test metric collection
    - Test logging when targets are missed
    - _Requirements: 13.7_

- [ ] 23. Implement phased rollout support
  - [ ] 23.1 Add feature flag system
    - Implement feature flags for enabling/disabling functionality
    - Configure flags for Phase 1-5 features
    - Hide/disable features from incomplete phases
    - _Requirements: 18.1, 18.7_
  
  - [ ] 23.2 Configure Phase 1 (Offline Translation MVP)
    - Enable text translation for Hindi, Marathi, English
    - Disable voice, OCR, LLM, cloud features
    - _Requirements: 18.2_
  
  - [ ]* 23.3 Write unit tests for feature flags
    - Test flag evaluation
    - Test feature visibility based on flags
    - _Requirements: 18.1_

- [ ] 24. Checkpoint - Ensure all features work end-to-end
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 25. Set up CI/CD pipeline
  - [ ] 25.1 Create GitHub Actions workflow for Android app
    - Configure build, test, lint steps
    - Set up automated testing on pull requests
    - Configure release builds with signing
    - _Requirements: 14.1_
  
  - [ ] 25.2 Create CI/CD pipeline for AWS infrastructure
    - Set up Terraform plan/apply automation
    - Configure Lambda deployment pipeline
    - Add automated testing for Lambda functions
    - _Requirements: 11.2_

- [ ] 26. Implement monitoring and observability
  - [ ] 26.1 Set up CloudWatch dashboards
    - Create dashboards for Lambda metrics (latency, errors, invocations)
    - Create dashboards for API Gateway metrics
    - Set up alarms for critical metrics
    - _Requirements: 11.6_
  
  - [ ] 26.2 Set up X-Ray tracing
    - Enable X-Ray for Lambda functions
    - Configure trace sampling
    - _Requirements: 11.6_
  
  - [ ] 26.3 Set up application performance monitoring
    - Integrate Firebase Performance Monitoring or similar
    - Track screen load times, network requests, custom traces
    - _Requirements: 13.5_

- [ ] 27. Implement ProGuard/R8 optimization
  - [ ] 27.1 Configure ProGuard rules
    - Add keep rules for model classes and JNI interfaces
    - Enable code shrinking and obfuscation
    - Test release builds thoroughly
    - _Requirements: 16.7_
  
  - [ ] 27.2 Configure ABI splits and App Bundle
    - Set up ABI splits for optimized APK sizes
    - Configure Android App Bundle for Play Store
    - _Requirements: 16.7_

- [ ] 28. Final integration testing and validation
  - [ ] 28.1 Test offline-first functionality
    - Test all modes work without internet
    - Test language pack installation and usage
    - Test data persistence and encryption
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [ ] 28.2 Test cloud augmentation
    - Test Smart Hybrid Router routing decisions
    - Test cloud fallback scenarios
    - Test sync operations
    - _Requirements: 7.1, 7.5, 10.1_
  
  - [ ] 28.3 Test performance targets
    - Benchmark all operations against targets
    - Test on low-end and high-end devices
    - Optimize bottlenecks
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_
  
  - [ ] 28.4 Test security and privacy
    - Verify encryption at rest and in transit
    - Test privacy controls and opt-out enforcement
    - Conduct security audit
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_
  
  - [ ]* 28.5 Run all property-based tests
    - Execute all 41 property tests with 100+ iterations
    - Verify all properties hold across input space
    - _Requirements: All_

- [ ] 29. Final checkpoint - Production readiness validation
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at major milestones
- Property tests validate universal correctness properties (41 total)
- Unit tests validate specific examples and edge cases
- Implementation uses Kotlin for Android with Jetpack Compose UI
- On-device AI uses quantized models: Marian NMT/NLLB (translation), Vosk/Whisper (STT), Tesseract/ML Kit (OCR), llama.cpp (LLM)
- AWS cloud uses Lambda + Bedrock for enhanced processing when available
- All core features work 100% offline; cloud only augments, never blocks
