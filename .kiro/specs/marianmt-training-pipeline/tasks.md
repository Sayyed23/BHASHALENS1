# Implementation Plan: MarianMT Model Training & Deployment Pipeline

## Overview

This implementation plan covers the end-to-end machine learning pipeline for training, optimizing, and deploying MarianMT neural machine translation models for BhashaLens offline-first translation. The pipeline will be implemented in Python and will handle data collection from multiple sources, model training on AWS infrastructure, quantization for mobile deployment, and packaging for offline use in the Flutter app.

The implementation supports five Indian languages (Hindi, Marathi, Tamil, Gujarati, and English) with eight bidirectional translation models, producing models under 30MB per language pair with sub-1000ms inference time.

## Tasks

- [ ] 1. Set up project structure and core infrastructure
  - Create Python project structure with src/, tests/, config/, scripts/ directories
  - Set up virtual environment and requirements.txt with dependencies (boto3, torch, transformers, sentencepiece, langdetect, onnx, onnxruntime)
  - Create configuration management system using YAML files for pipeline settings
  - Set up logging infrastructure with structured logging to CloudWatch
  - Create base classes and interfaces for pipeline components
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 2. Implement AWS infrastructure setup
  - [ ] 2.1 Create Terraform configuration for S3 buckets
    - Define S3 bucket structure for datasets (raw, mixed, cleaned, feedback)
    - Define S3 bucket structure for models (checkpoints, trained, quantized, onnx, packages, evaluations)
    - Configure bucket policies with encryption at rest (AES-256)
    - Set up versioning and lifecycle policies for cost optimization
    - Configure cross-region replication for disaster recovery
    - _Requirements: 4.4, 14.6, 15.4, 20.1, 20.2_

  - [ ] 2.2 Create Terraform configuration for EC2 training instances
    - Define EC2 instance configuration (p3.2xlarge with GPU)
    - Create IAM roles and policies for training instances
    - Configure security groups and VPC settings
    - Set up spot instance configuration with fallback to on-demand
    - Create user data script for instance initialization
    - _Requirements: 4.1, 4.2, 4.3, 15.1, 15.2_

  - [ ] 2.3 Set up CloudWatch monitoring and alerting
    - Create CloudWatch log groups for pipeline components
    - Define custom metrics for training (loss, BLEU score, cost)
    - Configure CloudWatch alarms for failures and quality thresholds
    - Set up SNS topics for alert notifications
    - Create CloudWatch dashboards for monitoring
    - _Requirements: 4.5, 5.9, 11.4, 11.6_

- [ ] 3. Implement dataset collection component
  - [ ] 3.1 Create DatasetCollector class with download methods
    - Implement IIT Bombay dataset downloader for Hindi-English
    - Implement AI4Bharat dataset downloader for all language pairs
    - Implement OPUS dataset downloader with filtering
    - Implement custom dataset importer (TSV/JSON format)
    - Add MD5 checksum verification for downloaded files
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.7_

  - [ ] 3.2 Implement dataset mixing and composition logic
    - Create stratified random sampling for dataset mixing
    - Implement mixing ratios (35% IIT Bombay, 40% AI4Bharat, 15% OPUS, 10% Custom for Hindi-English)
    - Implement mixing ratios (65% AI4Bharat, 20% OPUS, 15% Custom for other pairs)
    - Create train/validation/test splits (90%/5%/5%)
    - Implement hash-based deterministic splitting for reproducibility
    - Ensure no sentence pairs appear in multiple splits
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [ ] 3.3 Implement S3 upload and manifest generation
    - Upload raw datasets to S3 with proper path structure
    - Upload mixed datasets to S3
    - Generate manifest file with dataset metadata (row counts, checksums)
    - _Requirements: 1.5, 1.6, 2.8_

- [ ] 4. Implement data cleaning component
  - [ ] 4.1 Create DataCleaner class with validation rules
    - Implement empty pair removal
    - Implement identical source-target pair removal
    - Implement length filtering (max 512 characters, ratio <3:1)
    - Implement deduplication based on source text
    - Implement Unicode NFC normalization
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ] 4.2 Implement advanced cleaning filters
    - Add URL and email address removal using regex
    - Implement language detection using langdetect library
    - Validate source and target languages match expected languages
    - Process datasets in chunks for memory efficiency
    - Use multiprocessing for language detection
    - _Requirements: 3.7, 3.8, 3.9_

  - [ ] 4.3 Generate cleaning reports and upload cleaned data
    - Generate cleaning report with statistics on removed pairs
    - Upload cleaned datasets to S3
    - _Requirements: 3.10, 3.11_

- [ ] 5. Checkpoint - Ensure data pipeline tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement training pipeline core
  - [ ] 6.1 Create TrainingPipeline class with EC2 management
    - Implement EC2 instance provisioning with spot instance support
    - Create instance setup script (install MarianMT, CUDA, dependencies)
    - Implement checkpoint-based recovery for spot interruptions
    - Add automatic instance termination after training
    - _Requirements: 4.1, 4.2, 4.3, 4.7, 15.1, 15.2, 15.3_

  - [ ] 6.2 Implement MarianMT model training
    - Configure Transformer architecture (6 encoder/decoder layers, 512 hidden size)
    - Train SentencePiece tokenizer with 32,000 vocabulary size
    - Implement training loop with batch size 32 and learning rate 0.0003
    - Add gradient clipping and label smoothing
    - Train separate models for each language direction (8 models total)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.8_

  - [ ] 6.3 Implement evaluation and checkpointing
    - Evaluate validation BLEU score every 2,500 steps
    - Save checkpoints every 5,000 steps to S3
    - Implement early stopping (no improvement for 10,000 steps)
    - Log training metrics to CloudWatch
    - _Requirements: 5.5, 5.6, 5.7, 5.9_

  - [ ] 6.4 Implement model quality validation
    - Evaluate final model on test set
    - Validate BLEU score meets minimum thresholds (25 for Hindi-English, 20 for others)
    - Generate sample translations for 100 random test sentences
    - Calculate translation speed in sentences per second
    - Flag models below threshold and prevent deployment
    - Store evaluation results in S3
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9_

  - [ ] 6.5 Save trained models to S3
    - Upload final model and tokenizer to S3
    - Save training history and metadata
    - _Requirements: 5.10_

- [ ] 7. Implement model quantization component
  - [ ] 7.1 Create Quantizer class with INT8 quantization
    - Implement dynamic INT8 quantization for model compression
    - Ensure quantized model size is under 30MB
    - Implement mixed INT8/FP16 precision as fallback
    - _Requirements: 7.1, 7.2, 7.4_

  - [ ] 7.2 Implement quantization validation
    - Validate BLEU score degradation is within 2 points
    - Measure inference time on reference Android device
    - Ensure inference time is under 1000ms for 50-word sentences
    - Store quantized models in S3
    - _Requirements: 7.3, 7.5, 7.6, 7.7_

- [ ] 8. Implement ONNX conversion and optimization
  - [ ] 8.1 Create ModelOptimizer class for ONNX conversion
    - Convert quantized models to ONNX format (opset 13+)
    - Apply graph optimization passes (constant folding, operator fusion)
    - Embed SentencePiece tokenizer vocabulary in metadata
    - Configure execution providers (CPU, NNAPI for Android)
    - _Requirements: 8.1, 8.2, 8.4, 8.5_

  - [ ] 8.2 Implement ONNX validation
    - Validate ONNX outputs match original model within 0.01 tolerance
    - Test with sample inputs
    - Store ONNX models in S3
    - _Requirements: 8.3, 8.6, 8.7_

- [ ] 9. Implement model packaging component
  - [ ] 9.1 Create ModelPackager class for deployment packages
    - Create ZIP package with ONNX model, tokenizer, and metadata
    - Generate metadata JSON with model version, BLEU score, size, timestamp
    - Include inference configuration (max length, beam size, parameters)
    - Compress package with maximum compression
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [ ] 9.2 Implement package validation and upload
    - Ensure package size is under 35MB
    - Generate SHA-256 checksum for integrity verification
    - Upload packages to S3 with version number
    - Create manifest file listing all packages
    - _Requirements: 9.5, 9.6, 9.7, 9.8_

- [ ] 10. Checkpoint - Ensure model pipeline tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Implement model versioning system
  - [ ] 11.1 Create versioning logic with semantic versioning
    - Assign semantic version numbers (MAJOR.MINOR.PATCH)
    - Increment major version for data composition changes
    - Increment minor version for architecture/hyperparameter changes
    - Increment patch version for retraining with same config
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [ ] 11.2 Implement version management and rollback
    - Maintain all historical versions in S3
    - Tag latest stable version for each language pair
    - Support downloading specific versions by version number
    - Maintain changelog documenting version changes
    - _Requirements: 10.5, 10.6, 10.7, 10.8_

- [ ] 12. Implement pipeline orchestration
  - [ ] 12.1 Create PipelineOrchestrator class
    - Implement state machine for pipeline stages
    - Execute stages sequentially: collection → cleaning → training → quantization → conversion → packaging
    - Add error handling and failure notifications via CloudWatch
    - Support resuming from last successful stage
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

  - [ ] 12.2 Add pipeline configuration and cost estimation
    - Support YAML configuration files for pipeline settings
    - Estimate total execution time and AWS costs before starting
    - Log all activities with timestamps to CloudWatch
    - _Requirements: 11.2, 11.6, 11.7_

- [ ] 13. Implement cost optimization features
  - [ ] 13.1 Add spot instance management
    - Use spot instances with fallback to on-demand
    - Handle spot interruptions with checkpoint recovery
    - Automatically terminate instances after completion
    - _Requirements: 15.1, 15.2, 15.3_

  - [ ] 13.2 Implement storage cost optimization
    - Use S3 Intelligent-Tiering for datasets
    - Delete intermediate checkpoints older than 30 days
    - Generate cost reports after training
    - Require confirmation for costs exceeding $100
    - _Requirements: 15.4, 15.5, 15.6, 15.7_

- [ ] 14. Implement model testing and validation suite
  - [ ] 14.1 Create automated test suite for trained models
    - Implement translation accuracy tests with curated examples
    - Add performance tests measuring inference time
    - Create robustness tests with noisy inputs and edge cases
    - Test empty strings, very long sentences, special characters
    - _Requirements: 16.1, 16.2, 16.3, 16.5_

  - [ ] 14.2 Generate test reports
    - Mark models as failed if tests don't pass
    - Generate test report with pass/fail status
    - Store test reports in S3
    - _Requirements: 16.6, 16.7, 16.8_

- [ ] 15. Implement Flutter app integration components
  - [ ] 15.1 Create model download manager for Flutter (Dart)
    - Implement checkForUpdates() to fetch manifest from S3
    - Implement downloadModelPackage() with progress tracking
    - Add retry logic with exponential backoff (up to 3 attempts)
    - Display download progress to users
    - _Requirements: 12.1, 12.6, 12.8_

  - [ ] 15.2 Implement package verification and extraction (Dart)
    - Verify package integrity using SHA-256 checksum
    - Extract ZIP package to app storage directory
    - Delete corrupted files and re-download if extraction fails
    - Validate extracted files (model.onnx, tokenizer.model, metadata.json)
    - _Requirements: 12.2, 12.3, 12.7_

  - [ ] 15.3 Implement ONNX Runtime integration (Dart)
    - Load ONNX models using ONNX Runtime Flutter plugin
    - Initialize SentencePiece tokenizers from vocabulary
    - Support background download of model updates
    - _Requirements: 12.4, 12.5, 12.9_

- [ ] 16. Implement performance monitoring
  - [ ] 16.1 Add offline translation performance tracking (Dart)
    - Measure and log inference time for each translation
    - Measure and log model loading time on app startup
    - Measure and log memory usage during translation
    - Log performance warnings when inference exceeds 1000ms
    - _Requirements: 13.1, 13.2, 13.3, 13.5_

  - [ ] 16.2 Implement analytics and feedback collection (Dart)
    - Aggregate performance metrics locally
    - Upload metrics to analytics when online
    - Track translation accuracy feedback from users (thumbs up/down)
    - Support A/B testing of different model versions
    - _Requirements: 13.4, 13.6, 13.7_

- [ ] 17. Checkpoint - Ensure Flutter integration tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 18. Implement privacy and compliance features
  - [ ] 18.1 Create PII removal and dataset validation
    - Implement PII detection and removal (names, emails, phone numbers, SSNs, credit cards)
    - Remove sensitive information from training data
    - Maintain audit log of dataset sources and licenses
    - _Requirements: 14.1, 14.2, 14.3, 14.5_

  - [ ] 18.2 Configure encryption and access control
    - Ensure S3 encryption at rest (AES-256)
    - Configure IAM policies with least privilege
    - Prevent logging of training data samples
    - _Requirements: 14.4, 14.6, 14.7_

- [ ] 19. Implement continuous improvement pipeline
  - [ ] 19.1 Create feedback collection system (Dart)
    - Collect user corrections and feedback on translations
    - Upload anonymized feedback to S3
    - Store feedback locally until online
    - _Requirements: 17.1, 17.2_

  - [ ] 19.2 Implement feedback processing pipeline (Python)
    - Download feedback from S3 for date ranges
    - Filter high-quality feedback (language detection, profanity check)
    - Create custom dataset from user feedback
    - Incorporate feedback into retraining pipeline
    - _Requirements: 17.3, 17.4_

  - [ ] 19.3 Add scheduled retraining support
    - Support monthly/quarterly retraining schedule
    - Compare new model BLEU against current production model
    - Prevent deployment if new model is worse
    - Maintain feedback loop dashboard
    - _Requirements: 17.5, 17.6, 17.7_

- [ ] 20. Implement multi-language pair scalability
  - [ ] 20.1 Add configuration-driven language pair support
    - Support adding new language pairs via configuration
    - Automatically discover and download datasets for new pairs
    - Apply same cleaning, training, optimization to all pairs
    - _Requirements: 18.1, 18.2, 18.3_

  - [ ] 20.2 Implement parallel training support
    - Support parallel training of multiple language pairs
    - Maintain separate S3 paths for each pair
    - Generate language-pair-specific reports and packages
    - Support bundling multiple pairs into single deployment package
    - _Requirements: 18.4, 18.5, 18.6, 18.7_

- [ ] 21. Implement model explainability and debugging
  - [ ] 21.1 Create analysis and visualization tools
    - Generate attention visualization plots for sample translations
    - Identify and log 100 worst-performing test sentences
    - Analyze common error patterns (named entities, grammar)
    - Generate confusion matrix for common vocabulary
    - _Requirements: 19.1, 19.2, 19.3, 19.4_

  - [ ] 21.2 Build debugging dashboard
    - Support interactive translation debugging with beam search
    - Store analysis artifacts in S3
    - Provide web-based dashboard for exploring model behavior
    - _Requirements: 19.5, 19.6, 19.7_

- [ ] 22. Implement disaster recovery procedures
  - [ ] 22.1 Set up backup and replication
    - Enable S3 versioning for all datasets and models
    - Configure cross-region replication for critical data
    - Maintain backup copies in separate S3 bucket
    - _Requirements: 20.1, 20.2, 20.3_

  - [ ] 22.2 Create recovery procedures
    - Implement checkpoint-based training recovery
    - Create S3 data corruption recovery from versions
    - Implement emergency model rollback procedures
    - Document recovery procedures for common failures
    - Test disaster recovery quarterly
    - _Requirements: 20.4, 20.5, 20.6, 20.7_

- [ ] 23. Implement deployment and manifest management
  - [ ] 23.1 Create ManifestManager class
    - Generate manifest.json with all model versions
    - Update manifest with new model versions
    - Support canary deployments (10% of users)
    - Implement rollback to previous versions
    - _Requirements: 10.6, 10.7_

  - [ ] 23.2 Implement A/B testing framework (Dart)
    - Create ModelSelector for deterministic user bucketing
    - Implement canary deployment logic in Flutter app
    - Collect metrics for version comparison
    - Support rollout decisions based on metrics
    - _Requirements: 13.7_

- [ ] 24. Create deployment scripts and documentation
  - [ ] 24.1 Create deployment scripts
    - Write script to deploy Terraform infrastructure
    - Create script to run complete pipeline for all language pairs
    - Add script for model deployment and manifest updates
    - Create script for emergency rollback

  - [ ] 24.2 Write comprehensive documentation
    - Document pipeline architecture and components
    - Create setup and installation guide
    - Write operational runbook for common tasks
    - Document disaster recovery procedures
    - Add troubleshooting guide

- [ ] 25. Final checkpoint - End-to-end pipeline validation
  - Run complete pipeline for one language pair (Hindi-English)
  - Verify all artifacts are created in S3
  - Test model download and integration in Flutter app
  - Validate model quality meets requirements
  - Ensure all monitoring and alerting is working
  - Ask the user if questions arise before marking complete.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Python is used for ML pipeline, Dart for Flutter app integration
- AWS infrastructure is managed with Terraform
- All models are trained separately (8 bidirectional models)
- Cost optimization is critical (spot instances, S3 tiering, auto-termination)
