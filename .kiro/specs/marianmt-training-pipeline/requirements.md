# Requirements Document: MarianMT Model Training & Deployment Pipeline

## Introduction

This document specifies the requirements for building an end-to-end machine learning pipeline to train, optimize, and deploy MarianMT neural machine translation models for the BhashaLens offline-first translation application. The pipeline will handle data collection from multiple sources, model training on local GPU/CPU infrastructure, quantization for mobile deployment, and packaging for offline use in the Flutter app. The system supports five Indian languages (Hindi, Marathi, Tamil, Gujarati, and English) with bidirectional translation capabilities and potential cross-Indic language pairs. The system must produce models under 30MB per language pair with sub-1000ms inference time while maintaining translation quality suitable for accessibility use cases.

## Glossary

- **MarianMT**: A neural machine translation framework based on the Marian NMT toolkit, optimized for efficient inference
- **Dataset_Collector**: The component responsible for gathering and aggregating translation data from multiple sources
- **Data_Cleaner**: The component that preprocesses and validates translation pairs before training
- **Training_Pipeline**: Local/offline-first training pipeline running on local machines with GPUs that trains MarianMT models using prepared datasets
- **Quantizer**: The component that compresses trained models using quantization techniques
- **Model_Optimizer**: The component that converts and optimizes models for mobile deployment (ONNX format)
- **Model_Packager**: The component that bundles optimized models with metadata for app deployment
- **S3_Storage**: Legacy/optional - AWS S3 bucket structure for storing datasets, checkpoints, and trained models
- **Local_Storage**: Local filesystem paths used for storing downloaded datasets, intermediate files, checkpoints, and final models
- **Language_Pair**: A bidirectional translation configuration (e.g., Hindi↔English)
- **BLEU_Score**: Bilingual Evaluation Understudy score, a metric for translation quality (0-100 scale)
- **ONNX**: Open Neural Network Exchange format for cross-platform model deployment
- **Quantization**: Model compression technique reducing precision (e.g., FP32 to INT8)
- **IIT_Bombay_Dataset**: Hindi-English parallel corpus from IIT Bombay CFILT
- **Samanantar_Dataset**: AI4Bharat Samanantar parallel corpus for Indian languages
- **IndicTrans2_Dataset**: AI4Bharat IndicTrans2 parallel data (IN22-Gen & IN22-Conv benchmarks)
- **IndicCorp_Dataset**: AI4Bharat IndicCorp monolingual corpus for Indian languages
- **PMIndia_Dataset**: PMIndia parallel corpus from PM speeches translated to Indian languages
- **OPUS_Dataset**: Open parallel corpus from OPUS project
- **Custom_Domain_Dataset**: Application-specific translation pairs for accessibility contexts
- **Training_Instance**: Local machine with NVIDIA GPU (recommended) or CPU
- **Inference_Time**: Time taken to translate a single sentence on target mobile device

## Requirements

### Requirement 1: Dataset Collection from Multiple Sources

**User Story:** As an ML engineer, I want to collect translation datasets from IIT Bombay, Samanantar, IndicTrans2, IndicCorp, PMIndia, OPUS, and custom sources, so that I can build a comprehensive training corpus with domain diversity.

#### Acceptance Criteria

1. THE Dataset_Collector SHALL download IIT_Bombay_Dataset for Hindi-English language pairs
2. THE Dataset_Collector SHALL download Samanantar_Dataset for Hindi-English, Marathi-English, Tamil-English, and Gujarati-English language pairs
3. THE Dataset_Collector SHALL download IndicTrans2_Dataset (IN22-Gen and IN22-Conv) for all supported language pairs
4. THE Dataset_Collector SHALL download IndicCorp_Dataset monolingual data for all supported Indic languages
5. THE Dataset_Collector SHALL download PMIndia_Dataset parallel corpus for all supported language pairs
6. THE Dataset_Collector SHALL download OPUS_Dataset subsets relevant to Indian language translation including Tamil and Gujarati pairs
7. THE Dataset_Collector SHALL accept Custom_Domain_Dataset files in TSV or JSON format with source-target pairs
8. WHEN all datasets are collected, THE Dataset_Collector SHALL store raw data under the local path `./bhashalens_ml/data/raw/{language_pair}/{source_name}/`
9. THE Dataset_Collector SHALL generate a manifest file listing all collected datasets with row counts and checksums
10. FOR ALL downloaded datasets, THE Dataset_Collector SHALL verify file integrity using MD5 checksums

### Requirement 2: Dataset Mixing and Composition

**User Story:** As an ML engineer, I want to mix datasets according to specified ratios, so that the training corpus balances general translation quality with domain-specific accuracy.

#### Acceptance Criteria

1. FOR Hindi-English language pairs, THE Dataset_Collector SHALL mix datasets with 20% IIT_Bombay_Dataset, 25% Samanantar_Dataset, 15% IndicTrans2_Dataset, 10% IndicCorp_Dataset, 10% PMIndia_Dataset, 10% OPUS_Dataset, and 10% Custom_Domain_Dataset
2. FOR Marathi-English language pairs, THE Dataset_Collector SHALL mix datasets with 25% Samanantar_Dataset, 20% IndicTrans2_Dataset, 15% IndicCorp_Dataset, 15% PMIndia_Dataset, 15% OPUS_Dataset, and 10% Custom_Domain_Dataset
3. FOR Tamil-English language pairs, THE Dataset_Collector SHALL mix datasets with 25% Samanantar_Dataset, 20% IndicTrans2_Dataset, 15% IndicCorp_Dataset, 15% PMIndia_Dataset, 15% OPUS_Dataset, and 10% Custom_Domain_Dataset
4. FOR Gujarati-English language pairs, THE Dataset_Collector SHALL mix datasets with 25% Samanantar_Dataset, 20% IndicTrans2_Dataset, 15% IndicCorp_Dataset, 15% PMIndia_Dataset, 15% OPUS_Dataset, and 10% Custom_Domain_Dataset
5. WHEN mixing datasets, THE Dataset_Collector SHALL randomly sample from each source to achieve target ratios
6. THE Dataset_Collector SHALL create separate train, validation, and test splits with 90%, 5%, and 5% ratios respectively
7. THE Dataset_Collector SHALL ensure no sentence pair appears in multiple splits
8. THE Dataset_Collector SHALL store mixed datasets locally under `./bhashalens_ml/data/mixed/{language_pair}/`

### Requirement 3: Data Cleaning and Preprocessing

**User Story:** As an ML engineer, I want to clean and validate translation pairs before training, so that low-quality data does not degrade model performance.

#### Acceptance Criteria

1. THE Data_Cleaner SHALL remove translation pairs where source or target text is empty
2. THE Data_Cleaner SHALL remove translation pairs where source and target text are identical
3. THE Data_Cleaner SHALL remove translation pairs where source or target length exceeds 512 characters
4. THE Data_Cleaner SHALL remove translation pairs where length ratio between source and target exceeds 3:1
5. THE Data_Cleaner SHALL remove duplicate translation pairs based on source text
6. THE Data_Cleaner SHALL normalize Unicode characters to NFC form
7. THE Data_Cleaner SHALL remove translation pairs containing URLs or email addresses
8. THE Data_Cleaner SHALL remove translation pairs where source text is not in the expected source language (using language detection)
9. THE Data_Cleaner SHALL remove translation pairs where target text is not in the expected target language
10. WHEN cleaning is complete, THE Data_Cleaner SHALL generate a cleaning report with statistics on removed pairs and reasons
11. THE Data_Cleaner SHALL store cleaned datasets locally under `./bhashalens_ml/data/cleaned/{language_pair}/`

### Requirement 4: Local Training Infrastructure Setup

**User Story:** As an ML engineer, I want to set up local infrastructure for model training, so that I can train models efficiently with GPU acceleration if available.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL detect local NVIDIA GPU via CUDA and fall back to CPU if unavailable
2. THE Training_Pipeline SHALL install MarianMT framework version 1.11 or later
3. THE Training_Pipeline SHALL install required dependencies including SentencePiece, PyYAML, and CUDA (if GPU available)
4. THE Training_Pipeline SHALL read datasets from and write checkpoints to local filesystem paths
5. THE Training_Pipeline SHALL log training metrics and errors to local log files
6. WHEN training starts, THE Training_Pipeline SHALL validate GPU availability and CUDA installation if applicable
7. THE Training_Pipeline SHALL support checkpoint-based resume after interruptions

### Requirement 5: MarianMT Model Training

**User Story:** As an ML engineer, I want to train MarianMT models on cleaned datasets, so that I can produce translation models for each language pair.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL train separate models for Hindi→English, English→Hindi, Marathi→English, English→Marathi, Tamil→English, English→Tamil, Gujarati→English, and English→Gujarati directions
2. THE Training_Pipeline SHALL use Transformer architecture with 6 encoder layers and 6 decoder layers
3. THE Training_Pipeline SHALL use a vocabulary size of 32,000 tokens per language using SentencePiece tokenization
4. THE Training_Pipeline SHALL train for a minimum of 50,000 steps or until validation loss plateaus for 5 consecutive evaluations
5. THE Training_Pipeline SHALL evaluate validation BLEU_Score every 2,500 training steps
6. THE Training_Pipeline SHALL save model checkpoints every 5,000 training steps to S3_Storage under `s3://bhashalens-models/checkpoints/{language_pair}/`
7. WHEN validation BLEU_Score does not improve for 10,000 steps, THE Training_Pipeline SHALL stop training early
8. THE Training_Pipeline SHALL use a batch size of 32 sentences and learning rate of 0.0003 with warmup
9. THE Training_Pipeline SHALL log training loss, validation loss, and BLEU_Score to CloudWatch metrics
10. WHEN training completes, THE Training_Pipeline SHALL save the final model to S3_Storage under `s3://bhashalens-models/trained/{language_pair}/`

### Requirement 6: Model Quality Validation

**User Story:** As an ML engineer, I want to validate trained model quality against benchmarks, so that I can ensure models meet minimum translation quality standards.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL evaluate final model BLEU_Score on the held-out test set
2. FOR Hindi↔English models, THE Training_Pipeline SHALL achieve a minimum BLEU_Score of 25 on the test set
3. FOR Marathi↔English models, THE Training_Pipeline SHALL achieve a minimum BLEU_Score of 20 on the test set
4. FOR Tamil↔English models, THE Training_Pipeline SHALL achieve a minimum BLEU_Score of 20 on the test set
5. FOR Gujarati↔English models, THE Training_Pipeline SHALL achieve a minimum BLEU_Score of 20 on the test set
6. THE Training_Pipeline SHALL generate sample translations for 100 random test sentences
7. THE Training_Pipeline SHALL calculate translation speed in sentences per second on Training_Instance
8. WHEN BLEU_Score is below minimum threshold, THE Training_Pipeline SHALL flag the model as failed and prevent deployment
9. THE Training_Pipeline SHALL store evaluation results in S3_Storage under `s3://bhashalens-models/evaluations/{language_pair}/`

### Requirement 7: Model Quantization for Mobile Deployment

**User Story:** As an ML engineer, I want to quantize trained models to reduce size, so that models can be deployed on mobile devices with limited storage.

#### Acceptance Criteria

1. THE Quantizer SHALL convert trained models from FP32 precision to INT8 precision using dynamic quantization
2. THE Quantizer SHALL ensure quantized model size is under 30MB per language direction
3. THE Quantizer SHALL validate that quantized model BLEU_Score degrades by no more than 2 points compared to FP32 model
4. WHEN quantization causes BLEU_Score degradation exceeding 2 points, THE Quantizer SHALL retry with mixed INT8/FP16 precision
5. THE Quantizer SHALL measure quantized model inference time on a reference Android device (mid-range, 4GB RAM)
6. THE Quantizer SHALL ensure quantized model Inference_Time is under 1000ms for sentences up to 50 words
7. THE Quantizer SHALL store quantized models in S3_Storage under `s3://bhashalens-models/quantized/{language_pair}/`

### Requirement 8: ONNX Model Conversion and Optimization

**User Story:** As an ML engineer, I want to convert quantized models to ONNX format, so that models can run efficiently on mobile devices using ONNX Runtime.

#### Acceptance Criteria

1. THE Model_Optimizer SHALL convert quantized MarianMT models to ONNX format version 1.12 or later
2. THE Model_Optimizer SHALL apply graph optimization passes including constant folding and operator fusion
3. THE Model_Optimizer SHALL validate ONNX model outputs match original model outputs within 0.01 tolerance
4. THE Model_Optimizer SHALL embed SentencePiece tokenizer vocabulary into ONNX model metadata
5. THE Model_Optimizer SHALL configure ONNX model for mobile execution providers (CPU and NNAPI for Android)
6. WHEN ONNX conversion fails validation, THE Model_Optimizer SHALL log detailed error information and halt the pipeline
7. THE Model_Optimizer SHALL store ONNX models in S3_Storage under `s3://bhashalens-models/onnx/{language_pair}/`

### Requirement 9: Model Packaging for App Deployment

**User Story:** As an app developer, I want models packaged with metadata and configuration, so that I can integrate them into the Flutter app for offline translation.

#### Acceptance Criteria

1. THE Model_Packager SHALL create a deployment package containing ONNX model file, tokenizer vocabulary, and metadata JSON
2. THE Model_Packager SHALL include metadata with model version, language pair, BLEU_Score, model size, and creation timestamp
3. THE Model_Packager SHALL include configuration with maximum input length, beam size, and inference parameters
4. THE Model_Packager SHALL compress the deployment package using ZIP format with maximum compression
5. THE Model_Packager SHALL ensure final package size is under 35MB per language direction
6. THE Model_Packager SHALL generate a SHA-256 checksum for package integrity verification
7. THE Model_Packager SHALL store deployment packages in S3_Storage under `s3://bhashalens-models/packages/{language_pair}/v{version}/`
8. THE Model_Packager SHALL create a manifest file listing all available model packages with versions and checksums

### Requirement 10: Model Versioning and Rollback

**User Story:** As an ML engineer, I want to version trained models and support rollback, so that I can manage model updates and revert to previous versions if needed.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL assign semantic version numbers to trained models (e.g., 1.0.0, 1.1.0)
2. THE Training_Pipeline SHALL increment major version when training data composition changes significantly
3. THE Training_Pipeline SHALL increment minor version when model architecture or hyperparameters change
4. THE Training_Pipeline SHALL increment patch version for retraining with same configuration
5. THE Model_Packager SHALL maintain all historical model versions in S3_Storage
6. THE Model_Packager SHALL tag the latest stable version for each language pair
7. THE Model_Packager SHALL support downloading specific model versions by version number
8. THE Model_Packager SHALL maintain a changelog documenting changes between model versions

### Requirement 11: Pipeline Automation and Orchestration

**User Story:** As an ML engineer, I want to automate the entire training pipeline, so that I can retrain models with minimal manual intervention.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL provide a single command or script to execute the entire pipeline from data collection to packaging
2. THE Training_Pipeline SHALL support configuration files specifying dataset sources, mixing ratios, and training hyperparameters
3. THE Training_Pipeline SHALL execute pipeline stages sequentially: collection → cleaning → training → quantization → conversion → packaging
4. WHEN any pipeline stage fails, THE Training_Pipeline SHALL halt execution and send failure notification via CloudWatch alarm
5. THE Training_Pipeline SHALL support resuming from the last successful stage after fixing errors
6. THE Training_Pipeline SHALL log all pipeline activities with timestamps to CloudWatch Logs
7. THE Training_Pipeline SHALL estimate and display total pipeline execution time and AWS costs before starting

### Requirement 12: Model Download and Integration in Flutter App

**User Story:** As an app developer, I want to download and integrate model packages into the Flutter app, so that users can perform offline translation.

#### Acceptance Criteria

1. THE Flutter_App SHALL download model packages from S3_Storage on first launch or when updates are available
2. THE Flutter_App SHALL verify package integrity using SHA-256 checksum before extraction
3. THE Flutter_App SHALL extract model files to app-specific storage directory with appropriate permissions
4. THE Flutter_App SHALL load ONNX models using ONNX Runtime Flutter plugin
5. THE Flutter_App SHALL initialize tokenizers using SentencePiece vocabulary from model package
6. WHEN model download fails, THE Flutter_App SHALL retry up to 3 times with exponential backoff
7. WHEN model extraction fails, THE Flutter_App SHALL delete corrupted files and re-download the package
8. THE Flutter_App SHALL display download progress to users during model installation
9. THE Flutter_App SHALL support background download of model updates without blocking app usage

### Requirement 13: Offline Translation Performance Monitoring

**User Story:** As an app developer, I want to monitor offline translation performance, so that I can identify and address performance issues in production.

#### Acceptance Criteria

1. THE Flutter_App SHALL measure and log Inference_Time for each translation request
2. THE Flutter_App SHALL measure and log model loading time on app startup
3. THE Flutter_App SHALL measure and log memory usage during translation
4. THE Flutter_App SHALL aggregate performance metrics locally and upload to analytics when online
5. WHEN Inference_Time exceeds 1000ms, THE Flutter_App SHALL log a performance warning with device information
6. THE Flutter_App SHALL track translation accuracy feedback from users (thumbs up/down)
7. THE Flutter_App SHALL support A/B testing of different model versions to compare performance

### Requirement 14: Dataset Privacy and Compliance

**User Story:** As a compliance officer, I want to ensure training datasets comply with privacy regulations, so that the app meets legal requirements for data handling.

#### Acceptance Criteria

1. THE Dataset_Collector SHALL only use publicly available datasets or datasets with appropriate licenses
2. THE Data_Cleaner SHALL remove any personally identifiable information (PII) including names, phone numbers, and email addresses from training data
3. THE Data_Cleaner SHALL remove any sensitive information including credit card numbers, social security numbers, and medical records
4. THE Training_Pipeline SHALL not log or store any training data samples in CloudWatch or other monitoring systems
5. THE Training_Pipeline SHALL maintain an audit log of all dataset sources and licenses
6. THE S3_Storage SHALL encrypt all datasets and models at rest using AES-256 encryption
7. THE S3_Storage SHALL restrict access to training data using IAM policies with least privilege principle

### Requirement 15: Local Resource Management

**User Story:** As an ML engineer, I want to manage local compute and storage resources efficiently, so that training runs smoothly on my machine.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL detect available GPU memory and adjust batch size if needed
2. WHEN training is interrupted, THE Training_Pipeline SHALL save checkpoint and support resuming
3. THE Training_Pipeline SHALL monitor disk space and warn if below 10GB during training
4. THE Training_Pipeline SHALL support configuring the local data and output directories
5. THE Training_Pipeline SHALL delete intermediate checkpoints older than 30 days to reduce disk usage
6. THE Training_Pipeline SHALL estimate total training time before starting based on dataset size and hardware
7. THE Training_Pipeline SHALL generate a resource usage report after training completion showing time and disk usage

### Requirement 16: Model Testing and Validation Suite

**User Story:** As a QA engineer, I want to run automated tests on trained models, so that I can verify model quality before deployment to production.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL execute a test suite on trained models before marking them as deployment-ready
2. THE test suite SHALL include translation accuracy tests using curated test sentences with expected outputs
3. THE test suite SHALL include performance tests measuring Inference_Time on reference devices
4. THE test suite SHALL include robustness tests with noisy inputs, typos, and mixed-language text
5. THE test suite SHALL include edge case tests with empty strings, very long sentences, and special characters
6. WHEN any test fails, THE Training_Pipeline SHALL mark the model as failed and prevent deployment
7. THE Training_Pipeline SHALL generate a test report with pass/fail status for each test case
8. THE Training_Pipeline SHALL store test reports in S3_Storage under `s3://bhashalens-models/test-reports/{language_pair}/`

### Requirement 17: Continuous Model Improvement Pipeline

**User Story:** As an ML engineer, I want to collect user feedback and retrain models periodically, so that translation quality improves over time based on real-world usage.

#### Acceptance Criteria

1. THE Flutter_App SHALL collect user corrections and feedback on translations when users provide them
2. THE Flutter_App SHALL upload anonymized feedback data to S3_Storage under `s3://bhashalens-datasets/feedback/{language_pair}/`
3. THE Training_Pipeline SHALL incorporate high-quality user feedback into Custom_Domain_Dataset for retraining
4. THE Training_Pipeline SHALL support scheduled retraining on a monthly or quarterly basis
5. THE Training_Pipeline SHALL compare new model BLEU_Score against current production model before deployment
6. WHEN new model BLEU_Score is lower than current model, THE Training_Pipeline SHALL not deploy the new model
7. THE Training_Pipeline SHALL maintain a feedback loop dashboard showing model improvement metrics over time

### Requirement 18: Multi-Language Pair Scalability

**User Story:** As a product manager, I want the pipeline to support adding new language pairs, so that BhashaLens can expand to additional Indian languages in the future.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL support configuration-driven addition of new language pairs without code changes
2. THE Training_Pipeline SHALL automatically discover and download datasets for newly configured language pairs
3. THE Training_Pipeline SHALL apply the same cleaning, training, and optimization process to all language pairs
4. THE Training_Pipeline SHALL support parallel training of multiple language pairs on separate Training_Instance resources
5. THE Training_Pipeline SHALL maintain separate S3_Storage paths for each language pair
6. THE Training_Pipeline SHALL generate language-pair-specific evaluation reports and deployment packages
7. THE Model_Packager SHALL support bundling multiple language pairs into a single app deployment package

### Requirement 19: Model Explainability and Debugging

**User Story:** As an ML engineer, I want to analyze model behavior and debug translation errors, so that I can identify and fix model weaknesses.

#### Acceptance Criteria

1. THE Training_Pipeline SHALL generate attention visualization plots for sample translations during evaluation
2. THE Training_Pipeline SHALL identify and log the 100 worst-performing test sentences by BLEU_Score
3. THE Training_Pipeline SHALL analyze common error patterns (e.g., named entity errors, grammar errors)
4. THE Training_Pipeline SHALL generate a confusion matrix for common vocabulary words
5. THE Training_Pipeline SHALL support interactive translation debugging with beam search visualization
6. THE Training_Pipeline SHALL store analysis artifacts in S3_Storage under `s3://bhashalens-models/analysis/{language_pair}/`
7. THE Training_Pipeline SHALL provide a web-based dashboard for exploring model behavior and evaluation results

### Requirement 20: Disaster Recovery and Backup

**User Story:** As a DevOps engineer, I want to implement backup and recovery procedures, so that training data and models are protected against data loss.

#### Acceptance Criteria

1. THE S3_Storage SHALL enable versioning for all datasets and model files
2. THE S3_Storage SHALL replicate critical data to a secondary AWS region for disaster recovery
3. THE Training_Pipeline SHALL maintain backup copies of production models in a separate S3 bucket
4. THE Training_Pipeline SHALL support restoring training state from checkpoints after infrastructure failures
5. THE Training_Pipeline SHALL document recovery procedures for common failure scenarios
6. THE Training_Pipeline SHALL test disaster recovery procedures quarterly to ensure they work correctly
7. WHEN data corruption is detected, THE Training_Pipeline SHALL automatically restore from the most recent valid backup
