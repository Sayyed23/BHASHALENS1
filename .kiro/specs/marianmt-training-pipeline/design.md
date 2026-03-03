# Design Document: MarianMT Model Training & Deployment Pipeline

## Overview

The MarianMT Model Training & Deployment Pipeline is an end-to-end machine learning system that trains, optimizes, and deploys neural machine translation models for the BhashaLens offline-first translation application. The pipeline supports five Indian languages (Hindi, Marathi, Tamil, Gujarati, and English) with eight bidirectional translation models.

### System Goals

- Train high-quality MarianMT translation models achieving minimum BLEU scores (25 for Hindi↔English, 20 for other pairs)
- Produce quantized models under 30MB per language pair with sub-1000ms inference time
- Automate the entire pipeline from data collection to deployment
- Support continuous model improvement through user feedback
- Optimize AWS costs while maintaining training efficiency
- Ensure data privacy and compliance with regulations

### Key Constraints

- Model size: <30MB per language direction (quantized)
- Inference time: <1000ms for sentences up to 50 words
- Training infrastructure: AWS with GPU instances (p3.2xlarge or similar)
- Target deployment: Flutter mobile app with ONNX Runtime
- Data sources: IIT Bombay, AI4Bharat, OPUS, custom domain datasets
- Quality threshold: BLEU score degradation <2 points after quantization


## Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Data Collection Layer                        │
├─────────────────────────────────────────────────────────────────────┤
│  Dataset_Collector                                                   │
│  ├─ IIT Bombay Downloader                                           │
│  ├─ AI4Bharat Downloader                                            │
│  ├─ OPUS Downloader                                                 │
│  └─ Custom Dataset Importer                                         │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Data Processing Layer                           │
├─────────────────────────────────────────────────────────────────────┤
│  Data_Cleaner                                                        │
│  ├─ Validation Rules Engine                                         │
│  ├─ Language Detection                                              │
│  ├─ Deduplication                                                   │
│  └─ Train/Val/Test Splitter                                         │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Training Layer (AWS)                           │
├─────────────────────────────────────────────────────────────────────┤
│  Training_Pipeline                                                   │
│  ├─ EC2 Instance Manager (p3.2xlarge + Spot)                       │
│  ├─ MarianMT Trainer                                                │
│  ├─ Checkpoint Manager                                              │
│  ├─ Evaluation Engine                                               │
│  └─ CloudWatch Logger                                               │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Optimization Layer                               │
├─────────────────────────────────────────────────────────────────────┤
│  Quantizer → Model_Optimizer → Model_Packager                       │
│  ├─ INT8 Quantization                                               │
│  ├─ ONNX Conversion                                                 │
│  ├─ Graph Optimization                                              │
│  └─ Package Assembly                                                │
└────────────────┬────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Storage Layer (AWS S3)                          │
├─────────────────────────────────────────────────────────────────────┤
│  s3://bhashalens-datasets/                                          │
│  ├─ raw/{language_pair}/{source}/                                   │
│  ├─ mixed/{language_pair}/                                          │
│  ├─ cleaned/{language_pair}/                                        │
│  └─ feedback/{language_pair}/                                       │
│                                                                      │
│  s3://bhashalens-models/                                            │
│  ├─ checkpoints/{language_pair}/                                    │
│  ├─ trained/{language_pair}/                                        │
│  ├─ quantized/{language_pair}/                                      │
│  ├─ onnx/{language_pair}/                                           │
│  ├─ packages/{language_pair}/v{version}/                            │
│  ├─ evaluations/{language_pair}/                                    │
│  ├─ test-reports/{language_pair}/                                   │
│  └─ analysis/{language_pair}/                                       │
└─────────────────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Deployment Layer (Flutter App)                    │
├─────────────────────────────────────────────────────────────────────┤
│  Model Download Manager                                              │
│  ├─ Package Downloader                                              │
│  ├─ Integrity Verifier                                              │
│  ├─ Model Extractor                                                 │
│  └─ ONNX Runtime Integration                                        │
└─────────────────────────────────────────────────────────────────────┘
```

### AWS Infrastructure Components


**Compute Resources:**
- EC2 p3.2xlarge instances (1x NVIDIA V100 GPU, 61GB RAM, 8 vCPUs)
- Spot Instance support for cost optimization (up to 70% savings)
- Auto-termination after training completion
- Checkpoint-based recovery for spot interruptions

**Storage:**
- S3 buckets with Intelligent-Tiering for cost optimization
- Versioning enabled for disaster recovery
- Cross-region replication for critical data
- AES-256 encryption at rest

**Monitoring & Logging:**
- CloudWatch Logs for pipeline execution logs
- CloudWatch Metrics for training metrics (loss, BLEU score)
- CloudWatch Alarms for failure notifications
- Custom dashboards for model performance tracking

**Security:**
- IAM roles with least privilege access
- S3 bucket policies restricting public access
- VPC configuration for EC2 instances
- Secrets Manager for API keys and credentials

### Language Pair Configuration

The pipeline supports 8 bidirectional translation models:

1. Hindi → English
2. English → Hindi
3. Marathi → English
4. English → Marathi
5. Tamil → English
6. English → Tamil
7. Gujarati → English
8. English → Gujarati

Each language pair is trained independently with separate models, datasets, and evaluation metrics.


## Components and Interfaces

### 1. Dataset_Collector

**Responsibility:** Download and aggregate translation datasets from multiple sources.

**Interfaces:**

```python
class DatasetCollector:
    def download_iit_bombay(self, language_pair: str) -> DatasetMetadata
    def download_ai4bharat(self, language_pair: str) -> DatasetMetadata
    def download_opus(self, language_pair: str, filters: List[str]) -> DatasetMetadata
    def import_custom_dataset(self, file_path: str, format: str) -> DatasetMetadata
    def mix_datasets(self, language_pair: str, ratios: Dict[str, float]) -> MixedDataset
    def create_splits(self, dataset: MixedDataset, ratios: Tuple[float, float, float]) -> DatasetSplits
    def upload_to_s3(self, dataset: Dataset, s3_path: str) -> bool
    def generate_manifest(self, datasets: List[DatasetMetadata]) -> Manifest
```

**Key Algorithms:**

- **Dataset Mixing:** Stratified random sampling to achieve target ratios
  - For Hindi-English: 35% IIT Bombay, 40% AI4Bharat, 15% OPUS, 10% Custom
  - For other pairs: 65% AI4Bharat, 20% OPUS, 15% Custom
- **Split Creation:** Hash-based deterministic splitting to ensure reproducibility
- **Checksum Verification:** MD5 hash validation for downloaded files

**Configuration:**

```yaml
dataset_sources:
  iit_bombay:
    url: "http://www.cfilt.iitb.ac.in/iitb_parallel/"
    languages: ["hi-en"]
  ai4bharat:
    url: "https://ai4bharat.org/samanantar"
    languages: ["hi-en", "mr-en", "ta-en", "gu-en"]
  opus:
    url: "https://opus.nlpl.eu/"
    corpora: ["OpenSubtitles", "Tatoeba", "WikiMatrix"]
  custom:
    path: "s3://bhashalens-datasets/custom/"
    format: "tsv"

mixing_ratios:
  hi-en:
    iit_bombay: 0.35
    ai4bharat: 0.40
    opus: 0.15
    custom: 0.10
  mr-en:
    ai4bharat: 0.65
    opus: 0.20
    custom: 0.15
  # Similar for ta-en, gu-en

split_ratios:
  train: 0.90
  validation: 0.05
  test: 0.05
```


### 2. Data_Cleaner

**Responsibility:** Validate, clean, and preprocess translation pairs before training.

**Interfaces:**

```python
class DataCleaner:
    def remove_empty_pairs(self, dataset: Dataset) -> Dataset
    def remove_identical_pairs(self, dataset: Dataset) -> Dataset
    def filter_by_length(self, dataset: Dataset, max_length: int, max_ratio: float) -> Dataset
    def deduplicate(self, dataset: Dataset) -> Dataset
    def normalize_unicode(self, text: str) -> str
    def remove_urls_emails(self, dataset: Dataset) -> Dataset
    def validate_language(self, text: str, expected_lang: str) -> bool
    def clean_dataset(self, dataset: Dataset, config: CleaningConfig) -> CleanedDataset
    def generate_cleaning_report(self, original: Dataset, cleaned: Dataset) -> CleaningReport
```

**Validation Rules:**

1. **Empty Check:** Remove pairs where `len(source.strip()) == 0 or len(target.strip()) == 0`
2. **Identity Check:** Remove pairs where `source == target`
3. **Length Check:** Remove pairs where `len(source) > 512 or len(target) > 512`
4. **Ratio Check:** Remove pairs where `max(len(source), len(target)) / min(len(source), len(target)) > 3`
5. **Deduplication:** Remove duplicate source texts (keep first occurrence)
6. **Unicode Normalization:** Apply NFC normalization to all text
7. **URL/Email Removal:** Regex-based detection and removal
8. **Language Detection:** Use `langdetect` library with confidence threshold >0.9

**Cleaning Pipeline:**

```
Input Dataset
    ↓
Empty Removal → Identity Removal → Length Filter → Ratio Filter
    ↓
Deduplication → Unicode Normalization → URL/Email Removal
    ↓
Language Validation (Source) → Language Validation (Target)
    ↓
Cleaned Dataset + Cleaning Report
```

**Performance Considerations:**

- Process datasets in chunks of 10,000 pairs for memory efficiency
- Use multiprocessing for language detection (CPU-bound operation)
- Cache language detection results to avoid redundant checks


### 3. Training_Pipeline

**Responsibility:** Orchestrate model training on AWS infrastructure with GPU acceleration.

**Interfaces:**

```python
class TrainingPipeline:
    def provision_instance(self, instance_type: str, use_spot: bool) -> EC2Instance
    def setup_environment(self, instance: EC2Instance) -> bool
    def train_model(self, config: TrainingConfig, dataset: DatasetSplits) -> TrainedModel
    def evaluate_model(self, model: TrainedModel, test_set: Dataset) -> EvaluationResults
    def save_checkpoint(self, model: TrainedModel, step: int, s3_path: str) -> bool
    def early_stopping_check(self, validation_history: List[float], patience: int) -> bool
    def log_metrics(self, metrics: Dict[str, float], step: int) -> None
    def terminate_instance(self, instance: EC2Instance) -> bool
```

**Training Configuration:**

```yaml
model_architecture:
  type: "transformer"
  encoder_layers: 6
  decoder_layers: 6
  hidden_size: 512
  attention_heads: 8
  feed_forward_size: 2048
  dropout: 0.1

tokenization:
  type: "sentencepiece"
  vocab_size: 32000
  model_type: "unigram"

training_hyperparameters:
  batch_size: 32
  learning_rate: 0.0003
  warmup_steps: 4000
  max_steps: 50000
  gradient_accumulation: 1
  optimizer: "adam"
  beta1: 0.9
  beta2: 0.98
  epsilon: 1e-9
  label_smoothing: 0.1

evaluation:
  eval_frequency: 2500  # steps
  checkpoint_frequency: 5000  # steps
  early_stopping_patience: 10000  # steps (4 evaluations)
  
aws_config:
  instance_type: "p3.2xlarge"
  use_spot: true
  max_spot_price: 1.50  # USD per hour
  region: "us-east-1"
  ami: "ami-deep-learning-pytorch"
```

**Training Workflow:**

```
1. Provision EC2 Instance (Spot if available)
2. Install Dependencies (MarianMT, CUDA, SentencePiece)
3. Download Dataset from S3
4. Train SentencePiece Tokenizer
5. Initialize Model Architecture
6. Training Loop:
   - Forward pass (batch_size=32)
   - Compute loss (cross-entropy + label smoothing)
   - Backward pass + gradient clipping
   - Optimizer step
   - Every 2500 steps: Evaluate on validation set
   - Every 5000 steps: Save checkpoint to S3
   - Check early stopping condition
7. Final Evaluation on Test Set
8. Save Final Model to S3
9. Terminate Instance
```

**Early Stopping Logic:**

```python
def early_stopping_check(validation_scores, patience=10000, eval_freq=2500):
    """
    Stop training if validation BLEU doesn't improve for 'patience' steps.
    patience=10000 steps = 4 consecutive evaluations without improvement.
    """
    if len(validation_scores) < 2:
        return False
    
    best_score = max(validation_scores[:-patience//eval_freq])
    recent_scores = validation_scores[-patience//eval_freq:]
    
    return all(score <= best_score for score in recent_scores)
```


### 4. Quantizer

**Responsibility:** Compress trained models using quantization techniques for mobile deployment.

**Interfaces:**

```python
class Quantizer:
    def quantize_model(self, model: TrainedModel, precision: str) -> QuantizedModel
    def validate_quantization(self, original: TrainedModel, quantized: QuantizedModel, 
                             test_set: Dataset) -> ValidationResults
    def measure_inference_time(self, model: QuantizedModel, device: str) -> float
    def retry_with_mixed_precision(self, model: TrainedModel) -> QuantizedModel
```

**Quantization Strategy:**

1. **Primary Approach:** Dynamic INT8 quantization
   - Convert weights from FP32 to INT8
   - Keep activations in FP32 (computed dynamically)
   - Target: 4x size reduction (120MB → 30MB)

2. **Fallback Approach:** Mixed INT8/FP16 precision
   - Quantize most layers to INT8
   - Keep attention layers in FP16 for quality
   - Target: 2-3x size reduction with <2 BLEU degradation

**Validation Process:**

```python
def validate_quantization(original_model, quantized_model, test_set):
    """
    Ensure quantized model maintains quality within acceptable bounds.
    """
    original_bleu = evaluate_bleu(original_model, test_set)
    quantized_bleu = evaluate_bleu(quantized_model, test_set)
    
    bleu_degradation = original_bleu - quantized_bleu
    model_size = get_model_size_mb(quantized_model)
    
    return ValidationResults(
        original_bleu=original_bleu,
        quantized_bleu=quantized_bleu,
        degradation=bleu_degradation,
        size_mb=model_size,
        passed=(bleu_degradation <= 2.0 and model_size <= 30.0)
    )
```

**Performance Benchmarking:**

- Reference device: Mid-range Android (Snapdragon 660, 4GB RAM)
- Test sentences: 50 words average length
- Target: <1000ms inference time
- Measurement: Average over 100 test sentences


### 5. Model_Optimizer

**Responsibility:** Convert quantized models to ONNX format and apply graph optimizations.

**Interfaces:**

```python
class ModelOptimizer:
    def convert_to_onnx(self, model: QuantizedModel, opset_version: int) -> ONNXModel
    def optimize_graph(self, onnx_model: ONNXModel) -> ONNXModel
    def validate_conversion(self, original: QuantizedModel, onnx: ONNXModel, 
                           tolerance: float) -> bool
    def embed_tokenizer(self, onnx_model: ONNXModel, vocab: SentencePieceVocab) -> ONNXModel
    def configure_execution_providers(self, onnx_model: ONNXModel, 
                                     providers: List[str]) -> ONNXModel
```

**ONNX Conversion Process:**

```
MarianMT Model (PyTorch)
    ↓
Export to ONNX (opset 13+)
    ↓
Graph Optimization Passes:
  - Constant Folding
  - Operator Fusion (MatMul + Add → Gemm)
  - Redundant Node Elimination
  - Shape Inference
    ↓
Embed SentencePiece Vocabulary in Metadata
    ↓
Configure Execution Providers (CPU, NNAPI)
    ↓
Validate Output Consistency
    ↓
Optimized ONNX Model
```

**Optimization Passes:**

1. **Constant Folding:** Pre-compute constant operations at conversion time
2. **Operator Fusion:** Combine consecutive operations (e.g., MatMul + Bias + ReLU)
3. **Layout Optimization:** Optimize tensor layouts for target hardware
4. **Quantization-Aware Optimization:** Leverage INT8 operations where available

**Validation:**

```python
def validate_conversion(original_model, onnx_model, test_inputs, tolerance=0.01):
    """
    Ensure ONNX model produces equivalent outputs to original model.
    """
    for input_text in test_inputs:
        original_output = original_model.translate(input_text)
        onnx_output = onnx_model.translate(input_text)
        
        # Compare token probabilities
        prob_diff = abs(original_output.probs - onnx_output.probs).max()
        
        if prob_diff > tolerance:
            return False, f"Probability difference: {prob_diff}"
    
    return True, "Validation passed"
```

**Execution Provider Configuration:**

```python
execution_providers = [
    "CPUExecutionProvider",  # Fallback
    "CoreMLExecutionProvider",  # iOS
    "NNAPIExecutionProvider",  # Android
]
```


### 6. Model_Packager

**Responsibility:** Bundle optimized models with metadata and configuration for app deployment.

**Interfaces:**

```python
class ModelPackager:
    def create_package(self, onnx_model: ONNXModel, metadata: ModelMetadata, 
                      config: InferenceConfig) -> ModelPackage
    def compress_package(self, package: ModelPackage) -> bytes
    def generate_checksum(self, package_bytes: bytes) -> str
    def upload_package(self, package: ModelPackage, version: str) -> str
    def create_manifest(self, packages: List[ModelPackage]) -> Manifest
    def tag_latest_version(self, language_pair: str, version: str) -> bool
```

**Package Structure:**

```
model_package_{language_pair}_v{version}.zip
├── model.onnx                    # Optimized ONNX model
├── tokenizer.model               # SentencePiece vocabulary
├── metadata.json                 # Model metadata
├── config.json                   # Inference configuration
└── README.md                     # Package documentation
```

**Metadata Schema:**

```json
{
  "model_version": "1.0.0",
  "language_pair": "hi-en",
  "source_language": "hi",
  "target_language": "en",
  "bleu_score": 27.5,
  "bleu_score_quantized": 26.8,
  "model_size_mb": 28.3,
  "training_date": "2024-01-15T10:30:00Z",
  "training_steps": 50000,
  "dataset_composition": {
    "iit_bombay": 0.35,
    "ai4bharat": 0.40,
    "opus": 0.15,
    "custom": 0.10
  },
  "architecture": {
    "encoder_layers": 6,
    "decoder_layers": 6,
    "hidden_size": 512,
    "vocab_size": 32000
  },
  "performance": {
    "inference_time_ms": 850,
    "device": "Snapdragon 660"
  }
}
```

**Inference Configuration:**

```json
{
  "max_input_length": 512,
  "beam_size": 4,
  "length_penalty": 0.6,
  "no_repeat_ngram_size": 3,
  "early_stopping": true,
  "num_return_sequences": 1,
  "execution_providers": ["CPUExecutionProvider", "NNAPIExecutionProvider"]
}
```

**Versioning Strategy:**

- **Semantic Versioning:** MAJOR.MINOR.PATCH
  - MAJOR: Dataset composition changes (e.g., new data source)
  - MINOR: Architecture or hyperparameter changes
  - PATCH: Retraining with same configuration
- **Version Tags:** `latest`, `stable`, `v1.0.0`
- **Changelog:** Maintained in S3 at `s3://bhashalens-models/CHANGELOG.md`


## Data Models

### Dataset

```python
@dataclass
class Dataset:
    """Represents a collection of translation pairs."""
    language_pair: str  # e.g., "hi-en"
    source_language: str  # e.g., "hi"
    target_language: str  # e.g., "en"
    pairs: List[TranslationPair]
    source_name: str  # e.g., "iit_bombay", "ai4bharat"
    metadata: DatasetMetadata

@dataclass
class TranslationPair:
    """A single source-target translation pair."""
    source: str
    target: str
    source_length: int
    target_length: int
    pair_id: str  # Unique identifier

@dataclass
class DatasetMetadata:
    """Metadata about a dataset."""
    total_pairs: int
    source_name: str
    download_date: datetime
    checksum: str  # MD5 hash
    license: str
    url: str
```

### DatasetSplits

```python
@dataclass
class DatasetSplits:
    """Train/validation/test splits of a dataset."""
    train: Dataset
    validation: Dataset
    test: Dataset
    split_ratios: Tuple[float, float, float]  # (0.9, 0.05, 0.05)
    split_method: str  # "hash-based" or "random"
```

### TrainedModel

```python
@dataclass
class TrainedModel:
    """A trained MarianMT model."""
    model_id: str
    language_pair: str
    model_path: str  # S3 path
    tokenizer_path: str  # S3 path
    architecture: ModelArchitecture
    training_config: TrainingConfig
    training_history: TrainingHistory
    evaluation_results: EvaluationResults

@dataclass
class ModelArchitecture:
    """Model architecture specification."""
    encoder_layers: int
    decoder_layers: int
    hidden_size: int
    attention_heads: int
    feed_forward_size: int
    vocab_size: int
    dropout: float

@dataclass
class TrainingHistory:
    """Training metrics over time."""
    steps: List[int]
    train_loss: List[float]
    validation_loss: List[float]
    validation_bleu: List[float]
    learning_rate: List[float]
    total_steps: int
    training_time_hours: float
```

### EvaluationResults

```python
@dataclass
class EvaluationResults:
    """Model evaluation metrics."""
    bleu_score: float
    test_loss: float
    sentences_per_second: float
    sample_translations: List[SampleTranslation]
    worst_translations: List[SampleTranslation]  # Bottom 100 by BLEU
    evaluation_date: datetime

@dataclass
class SampleTranslation:
    """A sample translation with reference."""
    source: str
    reference: str
    hypothesis: str
    bleu_score: float
```

### QuantizedModel

```python
@dataclass
class QuantizedModel:
    """A quantized model ready for mobile deployment."""
    model_id: str
    original_model_id: str
    quantization_method: str  # "int8" or "mixed"
    model_path: str
    model_size_mb: float
    bleu_score: float
    bleu_degradation: float
    inference_time_ms: float
    validation_passed: bool
```

### ONNXModel

```python
@dataclass
class ONNXModel:
    """An ONNX-converted model."""
    model_id: str
    quantized_model_id: str
    onnx_path: str
    opset_version: int
    execution_providers: List[str]
    graph_optimizations: List[str]
    validation_passed: bool
    output_tolerance: float
```

### ModelPackage

```python
@dataclass
class ModelPackage:
    """A deployable model package."""
    package_id: str
    version: str  # Semantic version
    language_pair: str
    onnx_model: ONNXModel
    metadata: ModelMetadata
    inference_config: InferenceConfig
    package_path: str  # S3 path
    package_size_mb: float
    checksum: str  # SHA-256
    created_at: datetime

@dataclass
class ModelMetadata:
    """Comprehensive model metadata."""
    model_version: str
    language_pair: str
    source_language: str
    target_language: str
    bleu_score: float
    bleu_score_quantized: float
    model_size_mb: float
    training_date: datetime
    training_steps: int
    dataset_composition: Dict[str, float]
    architecture: ModelArchitecture
    performance: PerformanceMetrics

@dataclass
class PerformanceMetrics:
    """Model performance metrics."""
    inference_time_ms: float
    device: str
    memory_usage_mb: float
    sentences_per_second: float

@dataclass
class InferenceConfig:
    """Configuration for model inference."""
    max_input_length: int
    beam_size: int
    length_penalty: float
    no_repeat_ngram_size: int
    early_stopping: bool
    num_return_sequences: int
    execution_providers: List[str]
```


## Pipeline Orchestration

### Pipeline State Machine

```
┌─────────────┐
│   IDLE      │
└──────┬──────┘
       │ start_pipeline()
       ▼
┌─────────────────┐
│  COLLECTING     │ ← Dataset_Collector downloads data
└──────┬──────────┘
       │ on_collection_complete()
       ▼
┌─────────────────┐
│  CLEANING       │ ← Data_Cleaner processes data
└──────┬──────────┘
       │ on_cleaning_complete()
       ▼
┌─────────────────┐
│  PROVISIONING   │ ← EC2 instance setup
└──────┬──────────┘
       │ on_instance_ready()
       ▼
┌─────────────────┐
│  TRAINING       │ ← Model training in progress
└──────┬──────────┘
       │ on_training_complete()
       ▼
┌─────────────────┐
│  EVALUATING     │ ← Model evaluation
└──────┬──────────┘
       │ on_evaluation_complete()
       ▼
┌─────────────────┐
│  QUANTIZING     │ ← Model quantization
└──────┬──────────┘
       │ on_quantization_complete()
       ▼
┌─────────────────┐
│  OPTIMIZING     │ ← ONNX conversion
└──────┬──────────┘
       │ on_optimization_complete()
       ▼
┌─────────────────┐
│  PACKAGING      │ ← Package assembly
└──────┬──────────┘
       │ on_packaging_complete()
       ▼
┌─────────────────┐
│  COMPLETED      │
└─────────────────┘

       │ on_error()
       ▼
┌─────────────────┐
│  FAILED         │
└─────────────────┘
```

### Pipeline Orchestrator

```python
class PipelineOrchestrator:
    """Orchestrates the entire training pipeline."""
    
    def __init__(self, config: PipelineConfig):
        self.config = config
        self.state = PipelineState.IDLE
        self.dataset_collector = DatasetCollector()
        self.data_cleaner = DataCleaner()
        self.training_pipeline = TrainingPipeline()
        self.quantizer = Quantizer()
        self.model_optimizer = ModelOptimizer()
        self.model_packager = ModelPackager()
    
    def run_pipeline(self, language_pair: str) -> ModelPackage:
        """Execute the complete pipeline for a language pair."""
        try:
            # Stage 1: Data Collection
            self.state = PipelineState.COLLECTING
            raw_datasets = self.dataset_collector.collect_all(language_pair)
            mixed_dataset = self.dataset_collector.mix_datasets(
                language_pair, self.config.mixing_ratios
            )
            splits = self.dataset_collector.create_splits(mixed_dataset)
            
            # Stage 2: Data Cleaning
            self.state = PipelineState.CLEANING
            cleaned_splits = self.data_cleaner.clean_dataset(splits)
            
            # Stage 3: Training
            self.state = PipelineState.PROVISIONING
            instance = self.training_pipeline.provision_instance()
            
            self.state = PipelineState.TRAINING
            trained_model = self.training_pipeline.train_model(
                self.config.training_config, cleaned_splits
            )
            
            # Stage 4: Evaluation
            self.state = PipelineState.EVALUATING
            eval_results = self.training_pipeline.evaluate_model(
                trained_model, cleaned_splits.test
            )
            
            if not self.validate_quality(eval_results, language_pair):
                raise PipelineError("Model quality below threshold")
            
            # Stage 5: Quantization
            self.state = PipelineState.QUANTIZING
            quantized_model = self.quantizer.quantize_model(trained_model)
            
            # Stage 6: ONNX Optimization
            self.state = PipelineState.OPTIMIZING
            onnx_model = self.model_optimizer.convert_to_onnx(quantized_model)
            
            # Stage 7: Packaging
            self.state = PipelineState.PACKAGING
            package = self.model_packager.create_package(
                onnx_model, eval_results, self.config.inference_config
            )
            
            self.state = PipelineState.COMPLETED
            return package
            
        except Exception as e:
            self.state = PipelineState.FAILED
            self.handle_error(e)
            raise
        finally:
            self.cleanup()
    
    def validate_quality(self, results: EvaluationResults, 
                        language_pair: str) -> bool:
        """Validate model meets minimum quality thresholds."""
        thresholds = {
            "hi-en": 25.0,
            "en-hi": 25.0,
            "mr-en": 20.0,
            "en-mr": 20.0,
            "ta-en": 20.0,
            "en-ta": 20.0,
            "gu-en": 20.0,
            "en-gu": 20.0,
        }
        return results.bleu_score >= thresholds.get(language_pair, 20.0)
    
    def handle_error(self, error: Exception) -> None:
        """Handle pipeline errors and send notifications."""
        logger.error(f"Pipeline failed: {error}")
        self.send_cloudwatch_alarm(error)
        self.save_error_state()
    
    def cleanup(self) -> None:
        """Clean up resources after pipeline execution."""
        self.training_pipeline.terminate_instance()
```

### Configuration Management

```yaml
# pipeline_config.yaml
pipeline:
  language_pairs:
    - "hi-en"
    - "en-hi"
    - "mr-en"
    - "en-mr"
    - "ta-en"
    - "en-ta"
    - "gu-en"
    - "en-gu"
  
  parallel_training: false  # Train one pair at a time
  resume_from_checkpoint: true
  
dataset_collection:
  sources:
    - iit_bombay
    - ai4bharat
    - opus
    - custom
  
  mixing_ratios:
    hi-en:
      iit_bombay: 0.35
      ai4bharat: 0.40
      opus: 0.15
      custom: 0.10
    # ... other pairs
  
  split_ratios:
    train: 0.90
    validation: 0.05
    test: 0.05

data_cleaning:
  max_length: 512
  max_length_ratio: 3.0
  language_detection_confidence: 0.9
  remove_urls: true
  remove_emails: true

training:
  instance_type: "p3.2xlarge"
  use_spot: true
  max_spot_price: 1.50
  
  model:
    encoder_layers: 6
    decoder_layers: 6
    hidden_size: 512
    vocab_size: 32000
  
  hyperparameters:
    batch_size: 32
    learning_rate: 0.0003
    max_steps: 50000
    eval_frequency: 2500
    checkpoint_frequency: 5000
    early_stopping_patience: 10000

quantization:
  method: "int8"
  fallback_method: "mixed"
  max_bleu_degradation: 2.0
  target_size_mb: 30.0

optimization:
  onnx_opset: 13
  graph_optimizations:
    - constant_folding
    - operator_fusion
    - layout_optimization
  execution_providers:
    - CPUExecutionProvider
    - NNAPIExecutionProvider

packaging:
  compression: "zip"
  max_package_size_mb: 35.0
  versioning: "semantic"

aws:
  region: "us-east-1"
  s3_bucket_datasets: "bhashalens-datasets"
  s3_bucket_models: "bhashalens-models"
  cloudwatch_log_group: "/aws/bhashalens/training"

cost_optimization:
  use_spot_instances: true
  auto_terminate: true
  delete_old_checkpoints_days: 30
  s3_intelligent_tiering: true
```


## AWS Infrastructure Design

### S3 Bucket Structure

```
s3://bhashalens-datasets/
├── raw/
│   ├── hi-en/
│   │   ├── iit_bombay/
│   │   │   ├── train.tsv
│   │   │   └── metadata.json
│   │   ├── ai4bharat/
│   │   ├── opus/
│   │   └── custom/
│   ├── mr-en/
│   ├── ta-en/
│   └── gu-en/
├── mixed/
│   ├── hi-en/
│   │   ├── train.tsv
│   │   ├── val.tsv
│   │   ├── test.tsv
│   │   └── manifest.json
│   └── ...
├── cleaned/
│   ├── hi-en/
│   │   ├── train.tsv
│   │   ├── val.tsv
│   │   ├── test.tsv
│   │   └── cleaning_report.json
│   └── ...
└── feedback/
    ├── hi-en/
    │   └── user_corrections_2024-01.jsonl
    └── ...

s3://bhashalens-models/
├── checkpoints/
│   ├── hi-en/
│   │   ├── step_5000/
│   │   ├── step_10000/
│   │   └── ...
│   └── ...
├── trained/
│   ├── hi-en/
│   │   ├── model.pt
│   │   ├── tokenizer.model
│   │   └── training_history.json
│   └── ...
├── quantized/
│   ├── hi-en/
│   │   ├── model_int8.pt
│   │   └── validation_results.json
│   └── ...
├── onnx/
│   ├── hi-en/
│   │   ├── model.onnx
│   │   └── conversion_report.json
│   └── ...
├── packages/
│   ├── hi-en/
│   │   ├── v1.0.0/
│   │   │   ├── model_package.zip
│   │   │   └── checksum.txt
│   │   ├── v1.1.0/
│   │   └── latest -> v1.1.0
│   └── ...
├── evaluations/
│   ├── hi-en/
│   │   └── eval_results_v1.0.0.json
│   └── ...
├── test-reports/
│   ├── hi-en/
│   │   └── test_report_v1.0.0.json
│   └── ...
├── analysis/
│   ├── hi-en/
│   │   ├── attention_plots/
│   │   └── error_analysis.json
│   └── ...
└── CHANGELOG.md
```

### S3 Bucket Policies

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyPublicAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::bhashalens-datasets/*",
        "arn:aws:s3:::bhashalens-models/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalAccount": "ACCOUNT_ID"
        }
      }
    },
    {
      "Sid": "AllowTrainingInstanceRead",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:role/BhashaLensTrainingRole"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bhashalens-datasets/*",
        "arn:aws:s3:::bhashalens-models/*"
      ]
    },
    {
      "Sid": "AllowTrainingInstanceWrite",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:role/BhashaLensTrainingRole"
      },
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::bhashalens-models/checkpoints/*",
        "arn:aws:s3:::bhashalens-models/trained/*",
        "arn:aws:s3:::bhashalens-models/quantized/*",
        "arn:aws:s3:::bhashalens-models/onnx/*",
        "arn:aws:s3:::bhashalens-models/packages/*"
      ]
    }
  ]
}
```

### IAM Roles and Policies

**Training Instance Role:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bhashalens-datasets/*",
        "arn:aws:s3:::bhashalens-models/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/bhashalens/training:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "cloudwatch:namespace": "BhashaLens/Training"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Project": "BhashaLens"
        }
      }
    }
  ]
}
```

### EC2 Instance Configuration

**Instance Specifications:**
- Instance Type: p3.2xlarge
- GPU: 1x NVIDIA V100 (16GB VRAM)
- vCPUs: 8
- RAM: 61 GB
- Storage: 500 GB EBS (gp3)
- AMI: Deep Learning AMI (Ubuntu 20.04)

**User Data Script:**

```bash
#!/bin/bash
set -e

# Update system
apt-get update && apt-get upgrade -y

# Install dependencies
apt-get install -y python3-pip git wget

# Install CUDA toolkit
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run
sh cuda_11.8.0_520.61.05_linux.run --silent --toolkit

# Install Python packages
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip3 install transformers sentencepiece pyyaml boto3 langdetect onnx onnxruntime

# Clone MarianMT
git clone https://github.com/marian-nmt/marian-dev.git
cd marian-dev
mkdir build && cd build
cmake .. -DUSE_SENTENCEPIECE=on -DUSE_CUDA=on
make -j8
make install

# Configure AWS CLI
aws configure set region us-east-1

# Download training script
aws s3 cp s3://bhashalens-scripts/train.py /home/ubuntu/train.py

# Set up CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Start training
cd /home/ubuntu
python3 train.py --config s3://bhashalens-configs/training_config.yaml

# Auto-terminate on completion
shutdown -h now
```

**Spot Instance Configuration:**

```python
spot_instance_config = {
    "InstanceType": "p3.2xlarge",
    "MaxPrice": "1.50",  # USD per hour
    "SpotInstanceType": "one-time",
    "InstanceInterruptionBehavior": "terminate",
    "BlockDurationMinutes": 360,  # 6 hours
}
```

### CloudWatch Configuration

**Log Groups:**

```
/aws/bhashalens/training/
├── dataset-collection
├── data-cleaning
├── model-training
├── model-evaluation
├── quantization
├── onnx-conversion
└── packaging
```

**Custom Metrics:**

```python
cloudwatch_metrics = [
    {
        "MetricName": "TrainingLoss",
        "Namespace": "BhashaLens/Training",
        "Dimensions": [
            {"Name": "LanguagePair", "Value": "hi-en"},
            {"Name": "ModelVersion", "Value": "1.0.0"}
        ],
        "Unit": "None"
    },
    {
        "MetricName": "ValidationBLEU",
        "Namespace": "BhashaLens/Training",
        "Unit": "None"
    },
    {
        "MetricName": "InferenceTime",
        "Namespace": "BhashaLens/Performance",
        "Unit": "Milliseconds"
    },
    {
        "MetricName": "ModelSize",
        "Namespace": "BhashaLens/Models",
        "Unit": "Megabytes"
    },
    {
        "MetricName": "TrainingCost",
        "Namespace": "BhashaLens/Costs",
        "Unit": "None"
    }
]
```

**CloudWatch Alarms:**

```python
alarms = [
    {
        "AlarmName": "TrainingFailure",
        "MetricName": "TrainingErrors",
        "Threshold": 1,
        "ComparisonOperator": "GreaterThanThreshold",
        "EvaluationPeriods": 1,
        "AlarmActions": ["arn:aws:sns:us-east-1:ACCOUNT_ID:training-alerts"]
    },
    {
        "AlarmName": "LowBLEUScore",
        "MetricName": "ValidationBLEU",
        "Threshold": 20,
        "ComparisonOperator": "LessThanThreshold",
        "EvaluationPeriods": 2,
        "AlarmActions": ["arn:aws:sns:us-east-1:ACCOUNT_ID:quality-alerts"]
    },
    {
        "AlarmName": "HighTrainingCost",
        "MetricName": "TrainingCost",
        "Threshold": 100,
        "ComparisonOperator": "GreaterThanThreshold",
        "EvaluationPeriods": 1,
        "AlarmActions": ["arn:aws:sns:us-east-1:ACCOUNT_ID:cost-alerts"]
    }
]
```


## Security and Compliance

### Data Privacy

**PII Removal Strategy:**

```python
class PIIRemover:
    """Remove personally identifiable information from training data."""
    
    PATTERNS = {
        "email": r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
        "phone": r'\b(\+\d{1,3}[-.]?)?\(?\d{3}\)?[-.]?\d{3}[-.]?\d{4}\b',
        "ssn": r'\b\d{3}-\d{2}-\d{4}\b',
        "credit_card": r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b',
        "url": r'https?://[^\s]+',
    }
    
    def remove_pii(self, text: str) -> str:
        """Remove PII patterns from text."""
        for pattern_type, pattern in self.PATTERNS.items():
            text = re.sub(pattern, f"[{pattern_type.upper()}]", text)
        return text
    
    def scan_dataset(self, dataset: Dataset) -> PIIScanReport:
        """Scan dataset for PII and generate report."""
        pii_found = defaultdict(int)
        
        for pair in dataset.pairs:
            for pattern_type, pattern in self.PATTERNS.items():
                if re.search(pattern, pair.source):
                    pii_found[pattern_type] += 1
                if re.search(pattern, pair.target):
                    pii_found[pattern_type] += 1
        
        return PIIScanReport(
            total_pairs=len(dataset.pairs),
            pii_instances=dict(pii_found),
            scan_date=datetime.now()
        )
```

**Dataset Licensing:**

```python
DATASET_LICENSES = {
    "iit_bombay": {
        "license": "CC BY-NC-SA 4.0",
        "url": "http://www.cfilt.iitb.ac.in/iitb_parallel/",
        "commercial_use": False,
        "attribution_required": True
    },
    "ai4bharat": {
        "license": "CC0 1.0",
        "url": "https://ai4bharat.org/samanantar",
        "commercial_use": True,
        "attribution_required": False
    },
    "opus": {
        "license": "Various (check per corpus)",
        "url": "https://opus.nlpl.eu/",
        "commercial_use": "Varies",
        "attribution_required": True
    },
    "custom": {
        "license": "Proprietary",
        "commercial_use": True,
        "attribution_required": False
    }
}
```

### Encryption

**Data at Rest:**
- S3 buckets: AES-256 encryption (SSE-S3)
- EBS volumes: AES-256 encryption
- Secrets Manager: Automatic encryption

**Data in Transit:**
- S3 transfers: HTTPS/TLS 1.2+
- EC2 communication: VPC with security groups
- API calls: AWS Signature Version 4

### Access Control

**Principle of Least Privilege:**

```
Training Pipeline:
  - Read: datasets, configs
  - Write: models, checkpoints, logs
  - No access: production app data

Flutter App:
  - Read: model packages (public S3 URLs with signed URLs)
  - No write access to any S3 buckets

Developers:
  - Read: all buckets (via IAM user)
  - Write: custom datasets only
  - No access: production credentials
```

**Multi-Factor Authentication:**
- Required for all IAM users
- Required for AWS Console access
- Not required for service roles (EC2, Lambda)

### Audit Logging

```python
class AuditLogger:
    """Log all pipeline activities for compliance."""
    
    def log_dataset_access(self, user: str, dataset: str, action: str):
        """Log dataset access events."""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "user": user,
            "dataset": dataset,
            "action": action,
            "ip_address": self.get_ip_address()
        }
        self.write_to_cloudwatch(log_entry, "/aws/bhashalens/audit")
    
    def log_model_deployment(self, model_id: str, version: str, deployer: str):
        """Log model deployment events."""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "model_id": model_id,
            "version": version,
            "deployer": deployer,
            "action": "deploy"
        }
        self.write_to_cloudwatch(log_entry, "/aws/bhashalens/audit")
```

### Compliance Requirements

**GDPR Compliance:**
- No personal data in training datasets
- Right to erasure: User feedback can be deleted
- Data minimization: Only collect necessary data
- Transparency: Document all data sources

**Data Retention:**
- Training datasets: Indefinite (no personal data)
- Model checkpoints: 30 days
- Production models: Indefinite
- Logs: 90 days
- User feedback: 1 year


## Cost Optimization

### Cost Breakdown Estimation

**Per Language Pair Training:**

```
EC2 p3.2xlarge (Spot):
  - On-demand: $3.06/hour
  - Spot (avg): $0.92/hour (70% savings)
  - Training time: ~8 hours
  - Cost: $7.36 per model

S3 Storage:
  - Datasets: ~5 GB per language pair
  - Models: ~2 GB per language pair
  - Monthly cost: ~$0.16 per language pair

Data Transfer:
  - Download datasets: ~5 GB
  - Upload models: ~2 GB
  - Cost: ~$0.63 per training run

CloudWatch:
  - Logs: ~1 GB per training run
  - Metrics: ~100 custom metrics
  - Cost: ~$0.50 per training run

Total per language pair: ~$8.50
Total for 8 models: ~$68
```

### Cost Optimization Strategies

**1. Spot Instance Usage:**

```python
def provision_with_spot_fallback(instance_type: str, max_price: float):
    """Try spot instance first, fall back to on-demand if unavailable."""
    try:
        # Request spot instance
        response = ec2.request_spot_instances(
            InstanceType=instance_type,
            MaxPrice=str(max_price),
            SpotInstanceType="one-time",
            LaunchSpecification={...}
        )
        return wait_for_spot_fulfillment(response)
    except SpotInstanceNotAvailable:
        # Fall back to on-demand
        logger.warning("Spot instance unavailable, using on-demand")
        return ec2.run_instances(InstanceType=instance_type, ...)
```

**2. Checkpoint-Based Recovery:**

```python
def handle_spot_interruption():
    """Save checkpoint and resume on new instance."""
    # Listen for spot interruption notice (2-minute warning)
    if spot_interruption_detected():
        logger.info("Spot interruption detected, saving checkpoint")
        save_checkpoint(current_step)
        upload_to_s3(checkpoint_path)
        
        # Request new spot instance
        new_instance = provision_with_spot_fallback()
        resume_training_from_checkpoint(new_instance, checkpoint_path)
```

**3. S3 Intelligent-Tiering:**

```python
s3_lifecycle_policy = {
    "Rules": [
        {
            "Id": "MoveOldCheckpointsToIA",
            "Status": "Enabled",
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "INTELLIGENT_TIERING"
                }
            ],
            "Expiration": {
                "Days": 90
            },
            "Filter": {
                "Prefix": "checkpoints/"
            }
        },
        {
            "Id": "DeleteOldLogs",
            "Status": "Enabled",
            "Expiration": {
                "Days": 90
            },
            "Filter": {
                "Prefix": "logs/"
            }
        }
    ]
}
```

**4. Automatic Instance Termination:**

```python
def auto_terminate_on_completion():
    """Terminate instance within 5 minutes of training completion."""
    training_complete = wait_for_training()
    
    # Upload final artifacts
    upload_model_to_s3()
    upload_logs_to_s3()
    
    # Wait for uploads to complete
    time.sleep(60)
    
    # Terminate instance
    instance_id = get_instance_id()
    ec2.terminate_instances(InstanceIds=[instance_id])
    logger.info(f"Instance {instance_id} terminated")
```

**5. Parallel Training Optimization:**

```python
def optimize_parallel_training(language_pairs: List[str], budget: float):
    """
    Decide whether to train models in parallel or sequentially
    based on budget and time constraints.
    """
    cost_per_model = 8.50
    time_per_model_hours = 8
    
    if budget >= len(language_pairs) * cost_per_model:
        # Train all models in parallel (faster, more expensive)
        return "parallel", len(language_pairs) * cost_per_model
    else:
        # Train models sequentially (slower, cheaper)
        return "sequential", len(language_pairs) * cost_per_model
```

### Cost Monitoring

```python
class CostTracker:
    """Track and report training costs."""
    
    def __init__(self):
        self.costs = defaultdict(float)
    
    def track_ec2_cost(self, instance_type: str, hours: float, spot: bool):
        """Track EC2 instance costs."""
        rates = {
            "p3.2xlarge": {"on_demand": 3.06, "spot": 0.92}
        }
        rate = rates[instance_type]["spot" if spot else "on_demand"]
        cost = hours * rate
        self.costs["ec2"] += cost
        return cost
    
    def track_s3_cost(self, storage_gb: float, transfer_gb: float):
        """Track S3 storage and transfer costs."""
        storage_cost = storage_gb * 0.023  # $0.023 per GB/month
        transfer_cost = transfer_gb * 0.09  # $0.09 per GB
        self.costs["s3"] += storage_cost + transfer_cost
        return storage_cost + transfer_cost
    
    def generate_cost_report(self) -> CostReport:
        """Generate detailed cost breakdown."""
        return CostReport(
            total=sum(self.costs.values()),
            breakdown=dict(self.costs),
            timestamp=datetime.now()
        )
```


## Flutter App Integration

### Model Download Manager

**Responsibility:** Download model packages from S3 and manage local model storage.

**Interfaces:**

```dart
class ModelDownloadManager {
  Future<bool> checkForUpdates(String languagePair);
  Future<void> downloadModelPackage(String languagePair, String version, 
                                    {Function(double)? onProgress});
  Future<bool> verifyPackageIntegrity(String packagePath, String expectedChecksum);
  Future<void> extractModelPackage(String packagePath, String destinationDir);
  Future<List<InstalledModel>> getInstalledModels();
  Future<void> deleteModel(String languagePair);
  Future<ModelMetadata> getModelMetadata(String languagePair);
}
```

**Download Workflow:**

```
1. Check for Updates
   ├─ Fetch manifest from S3: s3://bhashalens-models/packages/manifest.json
   ├─ Compare installed version with latest version
   └─ Return update availability status

2. Download Model Package
   ├─ Generate signed S3 URL (valid for 1 hour)
   ├─ Download package with progress tracking
   ├─ Save to temporary directory
   └─ Return download status

3. Verify Package Integrity
   ├─ Calculate SHA-256 checksum of downloaded file
   ├─ Compare with expected checksum from manifest
   └─ Return verification result

4. Extract Model Package
   ├─ Unzip package to app storage directory
   ├─ Validate extracted files (model.onnx, tokenizer.model, metadata.json)
   ├─ Set appropriate file permissions
   └─ Delete temporary package file

5. Load Model
   ├─ Initialize ONNX Runtime session
   ├─ Load tokenizer vocabulary
   └─ Mark model as ready for inference
```

**Implementation:**

```dart
class ModelDownloadManager {
  final String baseUrl = 'https://bhashalens-models.s3.amazonaws.com';
  final Directory appStorageDir;
  final SharedPreferences prefs;
  
  Future<bool> checkForUpdates(String languagePair) async {
    try {
      // Fetch manifest
      final manifestUrl = '$baseUrl/packages/manifest.json';
      final response = await http.get(Uri.parse(manifestUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch manifest');
      }
      
      final manifest = json.decode(response.body);
      final latestVersion = manifest['models'][languagePair]['latest_version'];
      final installedVersion = prefs.getString('model_version_$languagePair');
      
      return installedVersion == null || 
             _compareVersions(latestVersion, installedVersion) > 0;
    } catch (e) {
      logger.error('Error checking for updates: $e');
      return false;
    }
  }
  
  Future<void> downloadModelPackage(
    String languagePair, 
    String version,
    {Function(double)? onProgress}
  ) async {
    final packageUrl = '$baseUrl/packages/$languagePair/v$version/model_package.zip';
    final tempFile = File('${appStorageDir.path}/temp_$languagePair.zip');
    
    try {
      final request = await HttpClient().getUrl(Uri.parse(packageUrl));
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }
      
      final totalBytes = response.contentLength;
      var downloadedBytes = 0;
      
      final sink = tempFile.openWrite();
      await for (var chunk in response) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        if (onProgress != null && totalBytes > 0) {
          onProgress(downloadedBytes / totalBytes);
        }
      }
      
      await sink.close();
      logger.info('Downloaded model package for $languagePair');
    } catch (e) {
      logger.error('Download error: $e');
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
      rethrow;
    }
  }

  Future<bool> verifyPackageIntegrity(String packagePath, String expectedChecksum) async {
    try {
      final file = File(packagePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final actualChecksum = digest.toString();
      
      final isValid = actualChecksum == expectedChecksum;
      
      if (!isValid) {
        logger.error('Checksum mismatch: expected $expectedChecksum, got $actualChecksum');
      }
      
      return isValid;
    } catch (e) {
      logger.error('Verification error: $e');
      return false;
    }
  }
  
  Future<void> extractModelPackage(String packagePath, String destinationDir) async {
    try {
      final zipFile = File(packagePath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final file in archive) {
        final filename = file.name;
        final filePath = '$destinationDir/$filename';
        
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }
      
      // Validate extracted files
      final requiredFiles = ['model.onnx', 'tokenizer.model', 'metadata.json'];
      for (final filename in requiredFiles) {
        final file = File('$destinationDir/$filename');
        if (!file.existsSync()) {
          throw Exception('Missing required file: $filename');
        }
      }
      
      // Delete temporary zip file
      await zipFile.delete();
      
      logger.info('Extracted model package to $destinationDir');
    } catch (e) {
      logger.error('Extraction error: $e');
      rethrow;
    }
  }
}
```

### ONNX Runtime Integration

**Responsibility:** Load and execute ONNX models for offline translation.

**Implementation:**

```dart
class ONNXTranslationEngine {
  late OrtSession session;
  late SentencePieceProcessor tokenizer;
  late ModelMetadata metadata;
  
  Future<void> initialize(String modelDir) async {
    try {
      // Load ONNX model
      final modelPath = '$modelDir/model.onnx';
      final sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(4)
        ..setIntraOpNumThreads(4)
        ..setGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
      
      session = OrtSession.fromFile(modelPath, sessionOptions);
      
      // Load tokenizer
      final tokenizerPath = '$modelDir/tokenizer.model';
      tokenizer = SentencePieceProcessor.fromFile(tokenizerPath);
      
      // Load metadata
      final metadataPath = '$modelDir/metadata.json';
      final metadataJson = await File(metadataPath).readAsString();
      metadata = ModelMetadata.fromJson(json.decode(metadataJson));
      
      logger.info('Initialized ONNX model: ${metadata.languagePair} v${metadata.modelVersion}');
    } catch (e) {
      logger.error('Model initialization error: $e');
      rethrow;
    }
  }
  
  Future<String> translate(String sourceText, {int beamSize = 4}) async {
    try {
      // Tokenize input
      final inputIds = tokenizer.encode(sourceText);
      
      if (inputIds.length > metadata.maxInputLength) {
        throw Exception('Input exceeds maximum length: ${metadata.maxInputLength}');
      }
      
      // Prepare input tensor
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        [inputIds],
        [1, inputIds.length],
      );
      
      // Run inference
      final startTime = DateTime.now();
      final outputs = await session.runAsync(
        OrtRunOptions(),
        {'input_ids': inputTensor},
      );
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;
      
      // Decode output
      final outputIds = outputs[0]?.value as List<List<int>>;
      final translatedText = tokenizer.decode(outputIds[0]);
      
      // Log performance
      logger.info('Translation completed in ${inferenceTime}ms');
      
      return translatedText;
    } catch (e) {
      logger.error('Translation error: $e');
      rethrow;
    }
  }
  
  void dispose() {
    session.release();
    tokenizer.dispose();
  }
}
```

### Model Update Strategy

**Background Updates:**

```dart
class ModelUpdateService {
  final ModelDownloadManager downloadManager;
  final NotificationService notificationService;
  
  Future<void> checkAndDownloadUpdates() async {
    final installedModels = await downloadManager.getInstalledModels();
    
    for (final model in installedModels) {
      final hasUpdate = await downloadManager.checkForUpdates(model.languagePair);
      
      if (hasUpdate) {
        // Download in background
        await _downloadInBackground(model.languagePair);
      }
    }
  }
  
  Future<void> _downloadInBackground(String languagePair) async {
    try {
      // Show notification
      await notificationService.show(
        title: 'Model Update Available',
        body: 'Downloading improved translation model for $languagePair',
      );
      
      // Download with retry logic
      var attempts = 0;
      const maxAttempts = 3;
      
      while (attempts < maxAttempts) {
        try {
          await downloadManager.downloadModelPackage(
            languagePair,
            'latest',
            onProgress: (progress) {
              notificationService.updateProgress(progress);
            },
          );
          
          // Verify and extract
          final packagePath = '${downloadManager.appStorageDir.path}/temp_$languagePair.zip';
          final manifest = await _fetchManifest();
          final expectedChecksum = manifest['models'][languagePair]['checksum'];
          
          if (await downloadManager.verifyPackageIntegrity(packagePath, expectedChecksum)) {
            await downloadManager.extractModelPackage(
              packagePath,
              '${downloadManager.appStorageDir.path}/models/$languagePair',
            );
            
            // Success notification
            await notificationService.show(
              title: 'Model Updated',
              body: 'Translation model for $languagePair has been updated',
            );
            
            break;
          } else {
            throw Exception('Integrity verification failed');
          }
        } catch (e) {
          attempts++;
          if (attempts >= maxAttempts) {
            logger.error('Failed to download model after $maxAttempts attempts: $e');
            await notificationService.show(
              title: 'Model Update Failed',
              body: 'Could not download model update. Will retry later.',
            );
          } else {
            // Exponential backoff
            await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));
          }
        }
      }
    } catch (e) {
      logger.error('Background download error: $e');
    }
  }
}
```


## Continuous Model Improvement

### User Feedback Collection

**Responsibility:** Collect user corrections and feedback for model retraining.

**Interfaces:**

```dart
class FeedbackCollector {
  Future<void> submitCorrection(TranslationCorrection correction);
  Future<void> submitRating(TranslationRating rating);
  Future<void> uploadFeedbackBatch();
  Future<List<TranslationCorrection>> getPendingFeedback();
}

@immutable
class TranslationCorrection {
  final String sourceText;
  final String modelTranslation;
  final String userCorrection;
  final String languagePair;
  final DateTime timestamp;
  final String userId;  // Anonymized
  
  const TranslationCorrection({
    required this.sourceText,
    required this.modelTranslation,
    required this.userCorrection,
    required this.languagePair,
    required this.timestamp,
    required this.userId,
  });
  
  Map<String, dynamic> toJson() => {
    'source_text': sourceText,
    'model_translation': modelTranslation,
    'user_correction': userCorrection,
    'language_pair': languagePair,
    'timestamp': timestamp.toIso8601String(),
    'user_id': userId,
  };
}

@immutable
class TranslationRating {
  final String sourceText;
  final String translation;
  final String languagePair;
  final int rating;  // 1-5 stars or thumbs up/down
  final DateTime timestamp;
  
  const TranslationRating({
    required this.sourceText,
    required this.translation,
    required this.languagePair,
    required this.rating,
    required this.timestamp,
  });
}
```

**Implementation:**

```dart
class FeedbackCollector {
  final LocalStorage localStorage;
  final S3Client s3Client;
  
  Future<void> submitCorrection(TranslationCorrection correction) async {
    // Store locally first
    await localStorage.saveFeedback(correction);
    
    // Upload when online
    if (await _isOnline()) {
      await uploadFeedbackBatch();
    }
  }
  
  Future<void> uploadFeedbackBatch() async {
    try {
      final pendingFeedback = await getPendingFeedback();
      
      if (pendingFeedback.isEmpty) {
        return;
      }
      
      // Anonymize user data
      final anonymizedFeedback = pendingFeedback.map((f) => 
        f.copyWith(userId: _hashUserId(f.userId))
      ).toList();
      
      // Create JSONL file
      final lines = anonymizedFeedback.map((f) => json.encode(f.toJson())).join('\n');
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'feedback_$timestamp.jsonl';
      
      // Upload to S3
      await s3Client.putObject(
        bucket: 'bhashalens-datasets',
        key: 'feedback/${anonymizedFeedback.first.languagePair}/$filename',
        body: utf8.encode(lines),
      );
      
      // Clear local storage
      await localStorage.clearFeedback(pendingFeedback);
      
      logger.info('Uploaded ${pendingFeedback.length} feedback items');
    } catch (e) {
      logger.error('Feedback upload error: $e');
    }
  }
  
  String _hashUserId(String userId) {
    // One-way hash for anonymization
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

### Feedback Processing Pipeline

**Responsibility:** Process user feedback and incorporate into training datasets.

```python
class FeedbackProcessor:
    """Process user feedback for model retraining."""
    
    def __init__(self, s3_client, quality_threshold=0.8):
        self.s3_client = s3_client
        self.quality_threshold = quality_threshold
    
    def collect_feedback(self, language_pair: str, start_date: datetime, 
                        end_date: datetime) -> List[TranslationCorrection]:
        """Collect feedback from S3 for a date range."""
        feedback_items = []
        
        # List all feedback files in date range
        prefix = f'feedback/{language_pair}/'
        objects = self.s3_client.list_objects(
            Bucket='bhashalens-datasets',
            Prefix=prefix
        )
        
        for obj in objects:
            # Parse timestamp from filename
            file_date = self._parse_date_from_filename(obj['Key'])
            
            if start_date <= file_date <= end_date:
                # Download and parse JSONL
                content = self.s3_client.get_object(
                    Bucket='bhashalens-datasets',
                    Key=obj['Key']
                )['Body'].read().decode('utf-8')
                
                for line in content.split('\n'):
                    if line.strip():
                        feedback_items.append(json.loads(line))
        
        return feedback_items
    
    def filter_high_quality_feedback(self, feedback_items: List[dict]) -> List[dict]:
        """Filter feedback to keep only high-quality corrections."""
        filtered = []
        
        for item in feedback_items:
            # Quality checks
            if self._is_high_quality(item):
                filtered.append(item)
        
        logger.info(f'Filtered {len(filtered)}/{len(feedback_items)} high-quality items')
        return filtered
    
    def _is_high_quality(self, item: dict) -> bool:
        """Determine if feedback item is high quality."""
        source = item['source_text']
        model_trans = item['model_translation']
        user_correction = item['user_correction']
        
        # Check 1: Not too similar to model output (user made meaningful change)
        similarity = self._calculate_similarity(model_trans, user_correction)
        if similarity > 0.9:
            return False
        
        # Check 2: Reasonable length
        if len(user_correction) < 3 or len(user_correction) > 512:
            return False
        
        # Check 3: No profanity or inappropriate content
        if self._contains_profanity(user_correction):
            return False
        
        # Check 4: Language detection matches expected target language
        detected_lang = self._detect_language(user_correction)
        expected_lang = item['language_pair'].split('-')[1]
        if detected_lang != expected_lang:
            return False
        
        return True

    def create_custom_dataset(self, feedback_items: List[dict], 
                             output_path: str) -> None:
        """Create custom dataset from feedback for retraining."""
        # Convert to training format
        training_pairs = []
        
        for item in feedback_items:
            training_pairs.append({
                'source': item['source_text'],
                'target': item['user_correction'],
            })
        
        # Deduplicate
        unique_pairs = self._deduplicate(training_pairs)
        
        # Write to TSV
        with open(output_path, 'w', encoding='utf-8') as f:
            for pair in unique_pairs:
                f.write(f"{pair['source']}\t{pair['target']}\n")
        
        logger.info(f'Created custom dataset with {len(unique_pairs)} pairs')
        
        # Upload to S3
        self.s3_client.upload_file(
            output_path,
            'bhashalens-datasets',
            f'custom/{language_pair}/user_feedback.tsv'
        )
```

### Retraining Schedule

**Monthly Retraining Workflow:**

```
1. Collect Feedback (1st of month)
   ├─ Gather all feedback from previous month
   ├─ Filter for high-quality corrections
   └─ Create custom dataset

2. Evaluate Feedback Volume
   ├─ If < 1000 corrections: Skip retraining
   └─ If >= 1000 corrections: Proceed

3. Trigger Retraining Pipeline
   ├─ Update dataset mixing ratios (increase custom dataset weight)
   ├─ Run full training pipeline
   └─ Generate new model version

4. A/B Testing
   ├─ Deploy new model to 10% of users
   ├─ Monitor BLEU scores and user ratings
   └─ Compare against current production model

5. Rollout Decision
   ├─ If new model performs better: Full rollout
   ├─ If new model performs worse: Rollback
   └─ Document results in changelog
```


## Testing Strategy

### Unit Tests

**Data Processing Tests:**

```python
class TestDataCleaner(unittest.TestCase):
    """Unit tests for Data_Cleaner component."""
    
    def setUp(self):
        self.cleaner = DataCleaner()
        self.sample_dataset = Dataset(
            language_pair='hi-en',
            source_language='hi',
            target_language='en',
            pairs=[
                TranslationPair('नमस्ते', 'Hello', 7, 5, 'pair_1'),
                TranslationPair('', 'Empty source', 0, 12, 'pair_2'),
                TranslationPair('Same', 'Same', 4, 4, 'pair_3'),
            ],
            source_name='test',
            metadata=DatasetMetadata(...)
        )
    
    def test_remove_empty_pairs(self):
        """Test that empty pairs are removed."""
        result = self.cleaner.remove_empty_pairs(self.sample_dataset)
        self.assertEqual(len(result.pairs), 2)
        self.assertNotIn('pair_2', [p.pair_id for p in result.pairs])
    
    def test_remove_identical_pairs(self):
        """Test that identical source-target pairs are removed."""
        result = self.cleaner.remove_identical_pairs(self.sample_dataset)
        self.assertNotIn('pair_3', [p.pair_id for p in result.pairs])
    
    def test_length_filter(self):
        """Test length-based filtering."""
        long_pair = TranslationPair('a' * 600, 'b' * 600, 600, 600, 'pair_4')
        dataset = Dataset(pairs=[long_pair], ...)
        
        result = self.cleaner.filter_by_length(dataset, max_length=512, max_ratio=3.0)
        self.assertEqual(len(result.pairs), 0)
    
    def test_unicode_normalization(self):
        """Test Unicode NFC normalization."""
        text = 'café'  # Composed form
        normalized = self.cleaner.normalize_unicode(text)
        self.assertEqual(normalized, 'café')  # NFC form
```

**Model Training Tests:**

```python
class TestTrainingPipeline(unittest.TestCase):
    """Unit tests for Training_Pipeline component."""
    
    def test_early_stopping_check(self):
        """Test early stopping logic."""
        # No improvement for 4 evaluations
        validation_scores = [25.0, 26.0, 27.0, 27.1, 27.0, 26.9, 26.8, 26.7]
        
        result = early_stopping_check(
            validation_scores, 
            patience=10000, 
            eval_freq=2500
        )
        
        self.assertTrue(result)
    
    def test_checkpoint_saving(self):
        """Test checkpoint saving to S3."""
        mock_model = MagicMock()
        pipeline = TrainingPipeline()
        
        result = pipeline.save_checkpoint(
            mock_model, 
            step=5000, 
            s3_path='s3://test-bucket/checkpoints/'
        )
        
        self.assertTrue(result)
        # Verify S3 upload was called
        self.assertTrue(pipeline.s3_client.upload_file.called)
    
    def test_quality_validation(self):
        """Test model quality threshold validation."""
        pipeline = TrainingPipeline()
        
        # Hindi-English should require BLEU >= 25
        results_pass = EvaluationResults(bleu_score=26.5, ...)
        self.assertTrue(pipeline.validate_quality(results_pass, 'hi-en'))
        
        results_fail = EvaluationResults(bleu_score=23.0, ...)
        self.assertFalse(pipeline.validate_quality(results_fail, 'hi-en'))
```

**Quantization Tests:**

```python
class TestQuantizer(unittest.TestCase):
    """Unit tests for Quantizer component."""
    
    def test_quantization_size_reduction(self):
        """Test that quantization reduces model size."""
        quantizer = Quantizer()
        mock_model = self._create_mock_model(size_mb=120)
        
        quantized = quantizer.quantize_model(mock_model, precision='int8')
        
        self.assertLess(quantized.model_size_mb, 30.0)
    
    def test_quantization_quality_degradation(self):
        """Test that BLEU degradation is within acceptable bounds."""
        quantizer = Quantizer()
        original_bleu = 27.5
        
        validation_results = quantizer.validate_quantization(
            original_model=mock_model,
            quantized_model=quantized_model,
            test_set=test_dataset
        )
        
        self.assertLessEqual(validation_results.degradation, 2.0)
        self.assertTrue(validation_results.passed)
```

### Integration Tests

**End-to-End Pipeline Tests:**

```python
class TestPipelineIntegration(unittest.TestCase):
    """Integration tests for complete pipeline."""
    
    @pytest.mark.slow
    def test_full_pipeline_execution(self):
        """Test complete pipeline from data collection to packaging."""
        orchestrator = PipelineOrchestrator(test_config)
        
        # Run pipeline for test language pair
        package = orchestrator.run_pipeline('hi-en')
        
        # Verify package was created
        self.assertIsNotNone(package)
        self.assertEqual(package.language_pair, 'hi-en')
        self.assertLess(package.package_size_mb, 35.0)
        
        # Verify S3 artifacts exist
        self.assertTrue(self._s3_object_exists(package.package_path))
    
    @pytest.mark.slow
    def test_spot_instance_interruption_recovery(self):
        """Test recovery from spot instance interruption."""
        pipeline = TrainingPipeline()
        
        # Start training
        pipeline.train_model(config, dataset)
        
        # Simulate spot interruption at step 10000
        pipeline.simulate_spot_interruption(step=10000)
        
        # Resume training
        pipeline.resume_from_checkpoint(step=10000)
        
        # Verify training completed
        self.assertEqual(pipeline.state, PipelineState.COMPLETED)
    
    def test_model_download_and_integration(self):
        """Test Flutter app model download and integration."""
        download_manager = ModelDownloadManager()
        
        # Download model
        download_manager.downloadModelPackage('hi-en', '1.0.0')
        
        # Verify integrity
        is_valid = download_manager.verifyPackageIntegrity(...)
        self.assertTrue(is_valid)
        
        # Extract and load
        download_manager.extractModelPackage(...)
        engine = ONNXTranslationEngine()
        engine.initialize(model_dir)
        
        # Test translation
        result = engine.translate('नमस्ते')
        self.assertIsNotNone(result)
        self.assertGreater(len(result), 0)
```

### Model Validation Tests

**Translation Quality Tests:**

```python
class TestModelQuality(unittest.TestCase):
    """Validation tests for trained models."""
    
    def setUp(self):
        self.model = load_trained_model('hi-en', version='1.0.0')
        self.test_cases = [
            ('नमस्ते', 'Hello'),
            ('आप कैसे हैं?', 'How are you?'),
            ('मुझे मदद चाहिए', 'I need help'),
            # ... more test cases
        ]
    
    def test_accuracy_on_curated_examples(self):
        """Test translation accuracy on curated examples."""
        correct = 0
        
        for source, expected in self.test_cases:
            translation = self.model.translate(source)
            
            # Calculate BLEU score for this pair
            bleu = calculate_bleu([expected], translation)
            
            if bleu > 0.5:  # Threshold for "correct"
                correct += 1
        
        accuracy = correct / len(self.test_cases)
        self.assertGreater(accuracy, 0.8)  # 80% accuracy threshold
    
    def test_inference_time_performance(self):
        """Test that inference time meets requirements."""
        test_sentence = 'यह एक परीक्षण वाक्य है जिसमें लगभग पचास शब्द हैं।'
        
        times = []
        for _ in range(100):
            start = time.time()
            self.model.translate(test_sentence)
            end = time.time()
            times.append((end - start) * 1000)  # Convert to ms
        
        avg_time = sum(times) / len(times)
        self.assertLess(avg_time, 1000)  # < 1000ms requirement
    
    def test_robustness_to_noisy_input(self):
        """Test model handles noisy input gracefully."""
        noisy_inputs = [
            'नमस्ते  ',  # Extra whitespace
            'HELLO',  # Wrong language
            'नमस्ते123',  # Mixed with numbers
            'नमस्ते!!!',  # Punctuation
        ]
        
        for input_text in noisy_inputs:
            try:
                result = self.model.translate(input_text)
                self.assertIsNotNone(result)
            except Exception as e:
                self.fail(f'Model failed on noisy input: {input_text}, error: {e}')
    
    def test_edge_cases(self):
        """Test model handles edge cases."""
        edge_cases = [
            '',  # Empty string
            'a',  # Single character
            'a' * 512,  # Maximum length
        ]
        
        for input_text in edge_cases:
            try:
                result = self.model.translate(input_text)
                # Should either return valid translation or raise expected error
                self.assertTrue(isinstance(result, str) or result is None)
            except ValueError:
                # Expected for invalid inputs
                pass
```

### Test Automation

**CI/CD Integration:**

```yaml
# .github/workflows/model-pipeline-test.yml
name: Model Pipeline Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov
      
      - name: Run unit tests
        run: |
          pytest tests/unit/ --cov=src --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
  
  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Run integration tests
        run: |
          pytest tests/integration/ -v --tb=short
  
  model-validation:
    runs-on: ubuntu-latest
    needs: integration-tests
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Download latest model
        run: |
          aws s3 cp s3://bhashalens-models/packages/hi-en/latest/ ./models/ --recursive
      
      - name: Run validation tests
        run: |
          pytest tests/validation/ -v
```


## Deployment Strategy

### Model Versioning and Release Process

**Version Numbering:**

```
MAJOR.MINOR.PATCH

MAJOR: Dataset composition changes (new data sources, significant ratio changes)
MINOR: Architecture or hyperparameter changes
PATCH: Retraining with same configuration

Examples:
- 1.0.0: Initial release
- 1.0.1: Retrained with same config
- 1.1.0: Changed learning rate or model size
- 2.0.0: Added new dataset source
```

**Release Workflow:**

```
1. Model Training Complete
   ├─ Run validation test suite
   ├─ Generate evaluation report
   └─ Assign version number

2. Staging Deployment
   ├─ Upload to staging S3 bucket
   ├─ Deploy to internal test devices
   ├─ Run manual QA tests
   └─ Collect feedback from team

3. Canary Deployment (10% of users)
   ├─ Deploy to production S3
   ├─ Update manifest with canary flag
   ├─ Monitor metrics for 48 hours
   └─ Compare against baseline model

4. Rollout Decision
   ├─ If metrics improved: Proceed to full rollout
   ├─ If metrics degraded: Rollback to previous version
   └─ Document decision in changelog

5. Full Deployment (100% of users)
   ├─ Update manifest to mark as latest
   ├─ Send push notification about update
   ├─ Monitor for 7 days
   └─ Archive old version
```

### Manifest Management

**Manifest Structure:**

```json
{
  "version": "1.0",
  "last_updated": "2024-01-15T10:30:00Z",
  "models": {
    "hi-en": {
      "latest_version": "1.2.0",
      "stable_version": "1.1.0",
      "canary_version": "1.2.0",
      "canary_percentage": 10,
      "versions": {
        "1.2.0": {
          "package_url": "https://bhashalens-models.s3.amazonaws.com/packages/hi-en/v1.2.0/model_package.zip",
          "checksum": "a1b2c3d4e5f6...",
          "size_mb": 28.5,
          "bleu_score": 27.8,
          "release_date": "2024-01-15T10:30:00Z",
          "changelog": "Improved accuracy on medical terminology",
          "min_app_version": "2.0.0"
        },
        "1.1.0": {
          "package_url": "https://bhashalens-models.s3.amazonaws.com/packages/hi-en/v1.1.0/model_package.zip",
          "checksum": "f6e5d4c3b2a1...",
          "size_mb": 29.2,
          "bleu_score": 27.2,
          "release_date": "2023-12-01T08:00:00Z",
          "changelog": "Initial production release"
        }
      }
    },
    "en-hi": {
      "latest_version": "1.1.0",
      "stable_version": "1.1.0",
      "versions": { /* ... */ }
    }
    // ... other language pairs
  }
}
```

**Manifest Update Script:**

```python
class ManifestManager:
    """Manage model manifest for deployments."""
    
    def __init__(self, s3_client):
        self.s3_client = s3_client
        self.manifest_path = 's3://bhashalens-models/packages/manifest.json'
    
    def update_manifest(self, language_pair: str, version: str, 
                       package_info: dict, deployment_type: str = 'stable'):
        """Update manifest with new model version."""
        # Download current manifest
        manifest = self._download_manifest()
        
        # Add new version
        if language_pair not in manifest['models']:
            manifest['models'][language_pair] = {
                'versions': {}
            }
        
        manifest['models'][language_pair]['versions'][version] = package_info
        
        # Update deployment pointers
        if deployment_type == 'canary':
            manifest['models'][language_pair]['canary_version'] = version
            manifest['models'][language_pair]['canary_percentage'] = 10
        elif deployment_type == 'stable':
            manifest['models'][language_pair]['stable_version'] = version
            manifest['models'][language_pair]['latest_version'] = version
        
        manifest['last_updated'] = datetime.now().isoformat()
        
        # Upload updated manifest
        self._upload_manifest(manifest)
        
        logger.info(f'Updated manifest: {language_pair} v{version} ({deployment_type})')
    
    def rollback_version(self, language_pair: str, target_version: str):
        """Rollback to a previous version."""
        manifest = self._download_manifest()
        
        if target_version not in manifest['models'][language_pair]['versions']:
            raise ValueError(f'Version {target_version} not found')
        
        manifest['models'][language_pair]['latest_version'] = target_version
        manifest['models'][language_pair]['stable_version'] = target_version
        manifest['models'][language_pair]['canary_version'] = None
        manifest['models'][language_pair]['canary_percentage'] = 0
        
        self._upload_manifest(manifest)
        
        logger.info(f'Rolled back {language_pair} to v{target_version}')
```

### A/B Testing Framework

**Client-Side Implementation:**

```dart
class ModelSelector {
  final String userId;
  final ManifestService manifestService;
  
  Future<String> selectModelVersion(String languagePair) async {
    final manifest = await manifestService.fetchManifest();
    final modelInfo = manifest['models'][languagePair];
    
    // Check if canary deployment is active
    if (modelInfo['canary_version'] != null) {
      final canaryPercentage = modelInfo['canary_percentage'] ?? 0;
      
      // Deterministic assignment based on user ID
      final userHash = _hashUserId(userId);
      final bucket = userHash % 100;
      
      if (bucket < canaryPercentage) {
        // User is in canary group
        logger.info('Selected canary version: ${modelInfo['canary_version']}');
        return modelInfo['canary_version'];
      }
    }
    
    // Use stable version
    return modelInfo['stable_version'];
  }
  
  int _hashUserId(String userId) {
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    return digest.bytes[0];  // Use first byte for bucketing
  }
}
```

**Metrics Collection:**

```dart
class ABTestMetrics {
  final AnalyticsService analytics;
  
  void logTranslation(String languagePair, String modelVersion, 
                     int inferenceTimeMs, bool userSatisfied) {
    analytics.logEvent('translation_completed', {
      'language_pair': languagePair,
      'model_version': modelVersion,
      'inference_time_ms': inferenceTimeMs,
      'user_satisfied': userSatisfied,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<ABTestResults> compareVersions(String languagePair, 
                                       String versionA, String versionB) async {
    final metricsA = await analytics.getMetrics(languagePair, versionA);
    final metricsB = await analytics.getMetrics(languagePair, versionB);
    
    return ABTestResults(
      versionA: versionA,
      versionB: versionB,
      avgInferenceTimeA: metricsA['avg_inference_time'],
      avgInferenceTimeB: metricsB['avg_inference_time'],
      satisfactionRateA: metricsA['satisfaction_rate'],
      satisfactionRateB: metricsB['satisfaction_rate'],
      sampleSizeA: metricsA['sample_size'],
      sampleSizeB: metricsB['sample_size'],
    );
  }
}
```


## Monitoring and Observability

### CloudWatch Dashboards

**Training Pipeline Dashboard:**

```python
dashboard_config = {
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["BhashaLens/Training", "TrainingLoss", {"stat": "Average"}],
                    [".", "ValidationLoss", {"stat": "Average"}],
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "Training and Validation Loss",
                "yAxis": {"left": {"min": 0}}
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["BhashaLens/Training", "ValidationBLEU", {"stat": "Average"}],
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "Validation BLEU Score",
                "yAxis": {"left": {"min": 0, "max": 100}}
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["BhashaLens/Costs", "TrainingCost", {"stat": "Sum"}],
                ],
                "period": 3600,
                "stat": "Sum",
                "region": "us-east-1",
                "title": "Training Cost (USD)",
                "yAxis": {"left": {"min": 0}}
            }
        },
        {
            "type": "log",
            "properties": {
                "query": "SOURCE '/aws/bhashalens/training' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20",
                "region": "us-east-1",
                "title": "Recent Errors"
            }
        }
    ]
}
```

**Production Model Performance Dashboard:**

```python
production_dashboard = {
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["BhashaLens/Performance", "InferenceTime", 
                     {"stat": "Average", "dimensions": {"LanguagePair": "hi-en"}}],
                    ["...", {"stat": "p99"}],
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "Inference Time (ms)",
                "yAxis": {"left": {"min": 0, "max": 2000}}
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["BhashaLens/Quality", "UserSatisfactionRate", {"stat": "Average"}],
                ],
                "period": 3600,
                "stat": "Average",
                "region": "us-east-1",
                "title": "User Satisfaction Rate (%)",
                "yAxis": {"left": {"min": 0, "max": 100}}
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["BhashaLens/Usage", "TranslationsPerHour", {"stat": "Sum"}],
                ],
                "period": 3600,
                "stat": "Sum",
                "region": "us-east-1",
                "title": "Translations Per Hour"
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["BhashaLens/Models", "ModelDownloads", 
                     {"stat": "Sum", "dimensions": {"ModelVersion": "1.2.0"}}],
                ],
                "period": 3600,
                "stat": "Sum",
                "region": "us-east-1",
                "title": "Model Downloads by Version"
            }
        }
    ]
}
```

### Alerting Configuration

**Critical Alerts:**

```python
critical_alarms = [
    {
        "AlarmName": "TrainingPipelineFailure",
        "MetricName": "PipelineFailures",
        "Namespace": "BhashaLens/Training",
        "Statistic": "Sum",
        "Period": 300,
        "EvaluationPeriods": 1,
        "Threshold": 1,
        "ComparisonOperator": "GreaterThanOrEqualToThreshold",
        "AlarmActions": [
            "arn:aws:sns:us-east-1:ACCOUNT_ID:critical-alerts"
        ],
        "AlarmDescription": "Training pipeline has failed"
    },
    {
        "AlarmName": "ModelQualityBelowThreshold",
        "MetricName": "ValidationBLEU",
        "Namespace": "BhashaLens/Training",
        "Statistic": "Average",
        "Period": 300,
        "EvaluationPeriods": 2,
        "Threshold": 20,
        "ComparisonOperator": "LessThanThreshold",
        "AlarmActions": [
            "arn:aws:sns:us-east-1:ACCOUNT_ID:quality-alerts"
        ],
        "AlarmDescription": "Model BLEU score below minimum threshold"
    },
    {
        "AlarmName": "HighInferenceLatency",
        "MetricName": "InferenceTime",
        "Namespace": "BhashaLens/Performance",
        "Statistic": "Average",
        "Period": 300,
        "EvaluationPeriods": 3,
        "Threshold": 1500,
        "ComparisonOperator": "GreaterThanThreshold",
        "AlarmActions": [
            "arn:aws:sns:us-east-1:ACCOUNT_ID:performance-alerts"
        ],
        "AlarmDescription": "Inference time exceeding 1500ms"
    }
]
```

**Warning Alerts:**

```python
warning_alarms = [
    {
        "AlarmName": "HighTrainingCost",
        "MetricName": "TrainingCost",
        "Namespace": "BhashaLens/Costs",
        "Statistic": "Sum",
        "Period": 3600,
        "EvaluationPeriods": 1,
        "Threshold": 50,
        "ComparisonOperator": "GreaterThanThreshold",
        "AlarmActions": [
            "arn:aws:sns:us-east-1:ACCOUNT_ID:cost-alerts"
        ],
        "AlarmDescription": "Training cost exceeding $50/hour"
    },
    {
        "AlarmName": "LowUserSatisfaction",
        "MetricName": "UserSatisfactionRate",
        "Namespace": "BhashaLens/Quality",
        "Statistic": "Average",
        "Period": 3600,
        "EvaluationPeriods": 6,
        "Threshold": 70,
        "ComparisonOperator": "LessThanThreshold",
        "AlarmActions": [
            "arn:aws:sns:us-east-1:ACCOUNT_ID:quality-alerts"
        ],
        "AlarmDescription": "User satisfaction rate below 70%"
    }
]
```

### Logging Strategy

**Structured Logging:**

```python
import logging
import json
from datetime import datetime

class StructuredLogger:
    """Structured logging for pipeline components."""
    
    def __init__(self, component_name: str):
        self.component_name = component_name
        self.logger = logging.getLogger(component_name)
    
    def log(self, level: str, message: str, **kwargs):
        """Log structured message with metadata."""
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'component': self.component_name,
            'level': level,
            'message': message,
            **kwargs
        }
        
        log_line = json.dumps(log_entry)
        
        if level == 'ERROR':
            self.logger.error(log_line)
        elif level == 'WARNING':
            self.logger.warning(log_line)
        elif level == 'INFO':
            self.logger.info(log_line)
        else:
            self.logger.debug(log_line)
    
    def log_training_step(self, step: int, loss: float, bleu: float = None):
        """Log training step metrics."""
        self.log('INFO', 'Training step completed', 
                step=step, loss=loss, bleu=bleu)
    
    def log_error(self, error: Exception, context: dict = None):
        """Log error with context."""
        self.log('ERROR', str(error), 
                error_type=type(error).__name__,
                context=context or {})

# Usage
logger = StructuredLogger('TrainingPipeline')
logger.log_training_step(step=5000, loss=2.34, bleu=25.6)
```

**Log Retention Policy:**

```python
log_retention_config = {
    '/aws/bhashalens/training': 90,  # days
    '/aws/bhashalens/inference': 30,
    '/aws/bhashalens/audit': 365,
    '/aws/bhashalens/errors': 180,
}
```


## Disaster Recovery

### Backup Strategy

**S3 Versioning and Replication:**

```python
# Enable versioning on critical buckets
s3_versioning_config = {
    'bhashalens-datasets': {
        'versioning': 'Enabled',
        'lifecycle_rules': [
            {
                'id': 'archive-old-versions',
                'status': 'Enabled',
                'noncurrent_version_transitions': [
                    {
                        'days': 30,
                        'storage_class': 'GLACIER'
                    }
                ],
                'noncurrent_version_expiration': {
                    'days': 365
                }
            }
        ]
    },
    'bhashalens-models': {
        'versioning': 'Enabled',
        'replication': {
            'role': 'arn:aws:iam::ACCOUNT_ID:role/S3ReplicationRole',
            'rules': [
                {
                    'id': 'replicate-production-models',
                    'status': 'Enabled',
                    'priority': 1,
                    'filter': {
                        'prefix': 'packages/'
                    },
                    'destination': {
                        'bucket': 'arn:aws:s3:::bhashalens-models-backup',
                        'region': 'us-west-2',
                        'storage_class': 'STANDARD_IA'
                    }
                }
            ]
        }
    }
}
```

**Automated Backups:**

```python
class BackupManager:
    """Manage automated backups of critical data."""
    
    def __init__(self, s3_client):
        self.s3_client = s3_client
    
    def backup_production_models(self):
        """Backup all production models to secondary region."""
        models = self._list_production_models()
        
        for model in models:
            source_key = model['key']
            dest_key = f"backups/{datetime.now().strftime('%Y-%m-%d')}/{source_key}"
            
            # Copy to backup bucket
            self.s3_client.copy_object(
                CopySource={'Bucket': 'bhashalens-models', 'Key': source_key},
                Bucket='bhashalens-models-backup',
                Key=dest_key
            )
            
            logger.info(f'Backed up model: {source_key}')
    
    def backup_training_datasets(self):
        """Backup cleaned training datasets."""
        datasets = self._list_cleaned_datasets()
        
        for dataset in datasets:
            # Create compressed archive
            archive_path = self._create_archive(dataset)
            
            # Upload to backup bucket
            self.s3_client.upload_file(
                archive_path,
                'bhashalens-datasets-backup',
                f"datasets/{dataset['language_pair']}/{dataset['name']}.tar.gz"
            )
    
    def schedule_backups(self):
        """Schedule daily backups using CloudWatch Events."""
        # Backup production models daily at 2 AM UTC
        # Backup datasets weekly on Sunday at 3 AM UTC
        pass
```

### Recovery Procedures

**Scenario 1: Training Instance Failure**

```
Recovery Steps:
1. Detect failure via CloudWatch alarm
2. Identify last successful checkpoint in S3
3. Provision new training instance
4. Download checkpoint from S3
5. Resume training from checkpoint
6. Verify training continues normally

Estimated Recovery Time: 15-30 minutes
Data Loss: Minimal (last checkpoint to failure)
```

**Implementation:**

```python
class TrainingRecovery:
    """Handle training instance failures and recovery."""
    
    def recover_from_failure(self, language_pair: str):
        """Recover training from last checkpoint."""
        try:
            # Find last checkpoint
            checkpoint = self._find_latest_checkpoint(language_pair)
            
            if checkpoint is None:
                logger.error('No checkpoint found, cannot recover')
                return False
            
            logger.info(f'Recovering from checkpoint: {checkpoint["step"]}')
            
            # Provision new instance
            instance = self.training_pipeline.provision_instance(
                instance_type='p3.2xlarge',
                use_spot=True
            )
            
            # Download checkpoint
            checkpoint_path = self._download_checkpoint(checkpoint['s3_path'])
            
            # Resume training
            self.training_pipeline.resume_training(
                instance=instance,
                checkpoint_path=checkpoint_path,
                config=self._load_training_config(language_pair)
            )
            
            logger.info('Training resumed successfully')
            return True
            
        except Exception as e:
            logger.error(f'Recovery failed: {e}')
            self._send_alert('Training recovery failed', str(e))
            return False
```

**Scenario 2: S3 Data Corruption**

```
Recovery Steps:
1. Detect corruption via integrity check
2. Identify corrupted objects
3. Restore from S3 versioning or backup bucket
4. Verify restored data integrity
5. Resume normal operations

Estimated Recovery Time: 5-15 minutes
Data Loss: None (versioning enabled)
```

**Implementation:**

```python
class DataRecovery:
    """Handle S3 data corruption and recovery."""
    
    def recover_corrupted_data(self, bucket: str, key: str):
        """Recover corrupted S3 object from version history."""
        try:
            # List object versions
            versions = self.s3_client.list_object_versions(
                Bucket=bucket,
                Prefix=key
            )
            
            # Try previous versions until we find a valid one
            for version in versions['Versions'][1:]:  # Skip current version
                version_id = version['VersionId']
                
                # Download version
                obj = self.s3_client.get_object(
                    Bucket=bucket,
                    Key=key,
                    VersionId=version_id
                )
                
                # Verify integrity
                if self._verify_integrity(obj['Body'].read()):
                    # Restore this version as current
                    self.s3_client.copy_object(
                        CopySource={'Bucket': bucket, 'Key': key, 'VersionId': version_id},
                        Bucket=bucket,
                        Key=key
                    )
                    
                    logger.info(f'Restored {key} from version {version_id}')
                    return True
            
            # If no valid version found, restore from backup bucket
            return self._restore_from_backup(bucket, key)
            
        except Exception as e:
            logger.error(f'Data recovery failed: {e}')
            return False
```

**Scenario 3: Model Deployment Failure**

```
Recovery Steps:
1. Detect deployment failure (high error rate, user complaints)
2. Immediately rollback to previous stable version
3. Update manifest to point to stable version
4. Notify users of rollback
5. Investigate root cause
6. Fix issues and redeploy

Estimated Recovery Time: 5 minutes
Data Loss: None
```

**Implementation:**

```python
class DeploymentRecovery:
    """Handle model deployment failures."""
    
    def emergency_rollback(self, language_pair: str):
        """Immediately rollback to previous stable version."""
        try:
            manifest = self.manifest_manager.get_manifest()
            model_info = manifest['models'][language_pair]
            
            current_version = model_info['latest_version']
            stable_version = model_info['stable_version']
            
            if current_version == stable_version:
                logger.warning('Already on stable version')
                return False
            
            # Rollback manifest
            self.manifest_manager.rollback_version(language_pair, stable_version)
            
            # Send notification
            self._send_notification(
                title='Model Rollback',
                message=f'{language_pair} rolled back to v{stable_version}'
            )
            
            # Log incident
            self._log_incident({
                'type': 'emergency_rollback',
                'language_pair': language_pair,
                'from_version': current_version,
                'to_version': stable_version,
                'timestamp': datetime.now().isoformat()
            })
            
            logger.info(f'Emergency rollback completed: {language_pair}')
            return True
            
        except Exception as e:
            logger.error(f'Rollback failed: {e}')
            return False
```

### Disaster Recovery Testing

**Quarterly DR Drills:**

```python
class DRTestSuite:
    """Disaster recovery testing procedures."""
    
    def test_training_recovery(self):
        """Test recovery from training failure."""
        # 1. Start training
        # 2. Simulate failure at random step
        # 3. Verify checkpoint exists
        # 4. Trigger recovery
        # 5. Verify training resumes correctly
        pass
    
    def test_data_corruption_recovery(self):
        """Test recovery from data corruption."""
        # 1. Corrupt a test dataset
        # 2. Trigger integrity check
        # 3. Verify corruption detected
        # 4. Trigger recovery
        # 5. Verify data restored correctly
        pass
    
    def test_deployment_rollback(self):
        """Test emergency deployment rollback."""
        # 1. Deploy test model version
        # 2. Simulate deployment failure
        # 3. Trigger emergency rollback
        # 4. Verify rollback completed
        # 5. Verify users receive stable version
        pass
```


## Performance Considerations

### Training Optimization

**GPU Utilization:**

```python
# Optimize batch size for GPU memory
def calculate_optimal_batch_size(gpu_memory_gb: float, model_size_mb: float) -> int:
    """Calculate optimal batch size based on available GPU memory."""
    # Rule of thumb: Use 80% of GPU memory
    available_memory_mb = gpu_memory_gb * 1024 * 0.8
    
    # Estimate memory per sample (model + activations + gradients)
    memory_per_sample = model_size_mb * 3  # Rough estimate
    
    batch_size = int(available_memory_mb / memory_per_sample)
    
    # Ensure batch size is power of 2 for efficiency
    batch_size = 2 ** int(math.log2(batch_size))
    
    return max(8, min(batch_size, 64))  # Clamp between 8 and 64

# For p3.2xlarge with 16GB V100
optimal_batch_size = calculate_optimal_batch_size(16, 120)  # Returns 32
```

**Mixed Precision Training:**

```python
# Use automatic mixed precision for faster training
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()

for batch in dataloader:
    optimizer.zero_grad()
    
    # Forward pass with autocast
    with autocast():
        outputs = model(batch)
        loss = criterion(outputs, targets)
    
    # Backward pass with gradient scaling
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()

# Expected speedup: 2-3x on V100 GPUs
```

**Gradient Accumulation:**

```python
# Simulate larger batch sizes with gradient accumulation
accumulation_steps = 4
effective_batch_size = batch_size * accumulation_steps  # 32 * 4 = 128

for i, batch in enumerate(dataloader):
    outputs = model(batch)
    loss = criterion(outputs, targets) / accumulation_steps
    loss.backward()
    
    if (i + 1) % accumulation_steps == 0:
        optimizer.step()
        optimizer.zero_grad()
```

### Inference Optimization

**Model Quantization Strategies:**

```python
# Dynamic quantization for CPU inference
import torch.quantization

def quantize_for_mobile(model):
    """Apply dynamic quantization for mobile deployment."""
    # Quantize linear layers to INT8
    quantized_model = torch.quantization.quantize_dynamic(
        model,
        {torch.nn.Linear, torch.nn.LSTM},
        dtype=torch.qint8
    )
    
    return quantized_model

# Static quantization with calibration
def quantize_static(model, calibration_data):
    """Apply static quantization with calibration."""
    model.eval()
    model.qconfig = torch.quantization.get_default_qconfig('fbgemm')
    
    # Prepare model for quantization
    model_prepared = torch.quantization.prepare(model)
    
    # Calibrate with representative data
    with torch.no_grad():
        for batch in calibration_data:
            model_prepared(batch)
    
    # Convert to quantized model
    model_quantized = torch.quantization.convert(model_prepared)
    
    return model_quantized
```

**ONNX Runtime Optimization:**

```python
# Configure ONNX Runtime for optimal mobile performance
import onnxruntime as ort

session_options = ort.SessionOptions()

# Enable graph optimizations
session_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

# Set thread count based on device
session_options.intra_op_num_threads = 4
session_options.inter_op_num_threads = 4

# Enable memory pattern optimization
session_options.enable_mem_pattern = True
session_options.enable_cpu_mem_arena = True

# Create session with optimizations
session = ort.InferenceSession(
    'model.onnx',
    session_options,
    providers=['CPUExecutionProvider']
)
```

**Caching Strategy:**

```dart
class TranslationCache {
  final int maxSize = 1000;
  final Map<String, String> cache = {};
  
  String? getCachedTranslation(String sourceText, String languagePair) {
    final key = '$languagePair:${sourceText.hashCode}';
    return cache[key];
  }
  
  void cacheTranslation(String sourceText, String translation, String languagePair) {
    final key = '$languagePair:${sourceText.hashCode}';
    
    // LRU eviction
    if (cache.length >= maxSize) {
      cache.remove(cache.keys.first);
    }
    
    cache[key] = translation;
  }
}
```

### Data Pipeline Optimization

**Parallel Data Processing:**

```python
from multiprocessing import Pool
import functools

class ParallelDataCleaner:
    """Clean datasets using parallel processing."""
    
    def __init__(self, num_workers=8):
        self.num_workers = num_workers
    
    def clean_dataset_parallel(self, dataset: Dataset) -> Dataset:
        """Clean dataset using multiple processes."""
        # Split dataset into chunks
        chunk_size = len(dataset.pairs) // self.num_workers
        chunks = [
            dataset.pairs[i:i + chunk_size]
            for i in range(0, len(dataset.pairs), chunk_size)
        ]
        
        # Process chunks in parallel
        with Pool(self.num_workers) as pool:
            cleaned_chunks = pool.map(self._clean_chunk, chunks)
        
        # Merge results
        cleaned_pairs = [pair for chunk in cleaned_chunks for pair in chunk]
        
        return Dataset(
            language_pair=dataset.language_pair,
            pairs=cleaned_pairs,
            ...
        )
    
    def _clean_chunk(self, pairs: List[TranslationPair]) -> List[TranslationPair]:
        """Clean a chunk of translation pairs."""
        cleaned = []
        
        for pair in pairs:
            if self._is_valid(pair):
                cleaned.append(pair)
        
        return cleaned
```

**S3 Transfer Acceleration:**

```python
# Enable S3 Transfer Acceleration for faster uploads/downloads
s3_client = boto3.client(
    's3',
    config=Config(
        s3={'use_accelerate_endpoint': True}
    )
)

# Use multipart upload for large files
def upload_large_file(file_path: str, bucket: str, key: str):
    """Upload large file using multipart upload."""
    config = TransferConfig(
        multipart_threshold=1024 * 25,  # 25 MB
        max_concurrency=10,
        multipart_chunksize=1024 * 25,
        use_threads=True
    )
    
    s3_client.upload_file(
        file_path,
        bucket,
        key,
        Config=config
    )
```


## Future Enhancements

### 1. Cross-Indic Language Pairs

**Objective:** Support direct translation between Indian languages without English as intermediary.

**Implementation:**

```
New Language Pairs:
- Hindi ↔ Marathi
- Hindi ↔ Tamil
- Hindi ↔ Gujarati
- Marathi ↔ Tamil
- Marathi ↔ Gujarati
- Tamil ↔ Gujarati

Total: 12 additional models (6 bidirectional pairs)
```

**Challenges:**
- Limited parallel corpora for cross-Indic pairs
- May require synthetic data generation via back-translation
- Quality validation more difficult without established benchmarks

**Benefits:**
- Better translation quality (no English intermediary)
- Faster inference (single model vs. two-step translation)
- Reduced storage (one model vs. two)

### 2. Multilingual Model Architecture

**Objective:** Train a single multilingual model supporting all language pairs.

**Advantages:**
- Reduced storage: 1 model (~50MB) vs. 8 models (~240MB)
- Transfer learning between related languages
- Easier maintenance and updates

**Challenges:**
- More complex training pipeline
- Potential quality degradation for individual pairs
- Requires language ID tokens in input

**Architecture:**

```python
# Multilingual model with language tokens
input_format = "<2en> नमस्ते"  # Translate Hindi to English
input_format = "<2hi> Hello"   # Translate English to Hindi

# Shared encoder-decoder with language embeddings
class MultilingualMarianMT:
    def __init__(self, languages: List[str]):
        self.encoder = TransformerEncoder(...)
        self.decoder = TransformerDecoder(...)
        self.language_embeddings = nn.Embedding(len(languages), hidden_size)
    
    def forward(self, input_ids, source_lang, target_lang):
        # Add language embeddings
        src_emb = self.language_embeddings(source_lang)
        tgt_emb = self.language_embeddings(target_lang)
        
        # Encode with source language context
        encoder_output = self.encoder(input_ids + src_emb)
        
        # Decode with target language context
        decoder_output = self.decoder(encoder_output, tgt_emb)
        
        return decoder_output
```

### 3. Active Learning Pipeline

**Objective:** Prioritize user feedback collection for sentences where model is uncertain.

**Implementation:**

```python
class ActiveLearningSelector:
    """Select translations for user feedback based on model uncertainty."""
    
    def calculate_uncertainty(self, translation_output):
        """Calculate uncertainty score for translation."""
        # Use beam search probabilities
        beam_scores = translation_output.beam_scores
        
        # High uncertainty = low confidence or high variance
        confidence = max(beam_scores)
        variance = np.var(beam_scores)
        
        uncertainty = (1 - confidence) + variance
        return uncertainty
    
    def should_request_feedback(self, uncertainty: float, threshold: float = 0.5) -> bool:
        """Decide whether to request user feedback."""
        return uncertainty > threshold
    
    def prioritize_feedback(self, feedback_queue: List[dict]) -> List[dict]:
        """Prioritize feedback items by learning value."""
        # Sort by uncertainty score (descending)
        sorted_queue = sorted(
            feedback_queue,
            key=lambda x: x['uncertainty'],
            reverse=True
        )
        
        return sorted_queue[:1000]  # Top 1000 most valuable items
```

**Benefits:**
- More efficient use of user feedback
- Faster model improvement
- Reduced annotation burden on users

### 4. Domain-Specific Model Variants

**Objective:** Train specialized models for specific domains (medical, legal, technical).

**Implementation:**

```
Domain Models:
- Medical: Hindi-English medical terminology
- Legal: Hindi-English legal documents
- Technical: Hindi-English technical documentation
- Conversational: Casual conversation and slang

Storage Strategy:
- Base model: 28MB (general purpose)
- Domain adapters: 5MB each (fine-tuned layers)
- Total: 28MB + (5MB × domains used)
```

**Adapter Architecture:**

```python
class DomainAdapter(nn.Module):
    """Lightweight adapter for domain-specific translation."""
    
    def __init__(self, hidden_size: int, adapter_size: int = 64):
        super().__init__()
        self.down_project = nn.Linear(hidden_size, adapter_size)
        self.up_project = nn.Linear(adapter_size, hidden_size)
        self.activation = nn.ReLU()
    
    def forward(self, hidden_states):
        # Bottleneck architecture
        down = self.activation(self.down_project(hidden_states))
        up = self.up_project(down)
        
        # Residual connection
        return hidden_states + up

# Usage
base_model = load_base_model()
medical_adapter = load_adapter('medical')

output = base_model(input_ids, adapter=medical_adapter)
```

### 5. Federated Learning for Privacy

**Objective:** Train models on user devices without collecting raw data.

**Architecture:**

```
1. Central Server
   ├─ Maintains global model
   ├─ Aggregates updates from devices
   └─ Distributes updated model

2. User Devices
   ├─ Download global model
   ├─ Train on local data
   ├─ Upload encrypted gradients
   └─ Never upload raw data

3. Secure Aggregation
   ├─ Homomorphic encryption
   ├─ Differential privacy
   └─ Gradient clipping
```

**Implementation:**

```python
class FederatedTrainingClient:
    """Client-side federated learning."""
    
    def __init__(self, model, local_data):
        self.model = model
        self.local_data = local_data
    
    def train_local_model(self, epochs: int = 1):
        """Train model on local data."""
        for epoch in range(epochs):
            for batch in self.local_data:
                loss = self.model.train_step(batch)
        
        # Extract gradients
        gradients = self.model.get_gradients()
        
        # Apply differential privacy
        noisy_gradients = self._add_noise(gradients)
        
        return noisy_gradients
    
    def _add_noise(self, gradients, epsilon: float = 1.0):
        """Add Gaussian noise for differential privacy."""
        noise_scale = 1.0 / epsilon
        
        noisy_gradients = []
        for grad in gradients:
            noise = np.random.normal(0, noise_scale, grad.shape)
            noisy_gradients.append(grad + noise)
        
        return noisy_gradients

class FederatedTrainingServer:
    """Server-side federated learning."""
    
    def aggregate_updates(self, client_gradients: List[np.ndarray]):
        """Aggregate gradients from multiple clients."""
        # Federated averaging
        avg_gradients = [
            np.mean([client[i] for client in client_gradients], axis=0)
            for i in range(len(client_gradients[0]))
        ]
        
        # Apply to global model
        self.global_model.apply_gradients(avg_gradients)
        
        return self.global_model
```

**Benefits:**
- Enhanced privacy (no raw data collection)
- Personalized models (trained on user's data)
- Compliance with strict privacy regulations

**Challenges:**
- Communication overhead
- Heterogeneous device capabilities
- Convergence slower than centralized training

### 6. Neural Architecture Search (NAS)

**Objective:** Automatically discover optimal model architectures for mobile deployment.

**Search Space:**

```python
search_space = {
    'encoder_layers': [4, 6, 8],
    'decoder_layers': [4, 6, 8],
    'hidden_size': [256, 512, 768],
    'attention_heads': [4, 8, 16],
    'feed_forward_size': [1024, 2048, 4096],
    'dropout': [0.1, 0.2, 0.3],
}

# Constraints
constraints = {
    'max_model_size_mb': 30,
    'max_inference_time_ms': 1000,
    'min_bleu_score': 25,
}
```

**Search Algorithm:**

```python
class NeuralArchitectureSearch:
    """Search for optimal model architecture."""
    
    def __init__(self, search_space, constraints):
        self.search_space = search_space
        self.constraints = constraints
    
    def search(self, num_trials: int = 100):
        """Run architecture search."""
        best_architecture = None
        best_score = 0
        
        for trial in range(num_trials):
            # Sample architecture
            architecture = self._sample_architecture()
            
            # Train and evaluate
            model = self._train_model(architecture)
            metrics = self._evaluate_model(model)
            
            # Check constraints
            if not self._satisfies_constraints(metrics):
                continue
            
            # Calculate score (weighted combination of metrics)
            score = self._calculate_score(metrics)
            
            if score > best_score:
                best_score = score
                best_architecture = architecture
        
        return best_architecture
    
    def _calculate_score(self, metrics):
        """Calculate architecture score."""
        # Weighted combination
        score = (
            metrics['bleu_score'] * 0.5 +
            (1000 - metrics['inference_time_ms']) / 1000 * 0.3 +
            (30 - metrics['model_size_mb']) / 30 * 0.2
        )
        return score
```

**Expected Benefits:**
- 10-20% improvement in efficiency
- Better size/quality trade-offs
- Automated optimization process

### 7. Continuous Evaluation Framework

**Objective:** Continuously monitor model quality in production.

**Implementation:**

```python
class ContinuousEvaluator:
    """Continuously evaluate model quality in production."""
    
    def __init__(self):
        self.reference_set = self._load_reference_set()
        self.evaluation_frequency = timedelta(hours=6)
    
    def evaluate_production_model(self, language_pair: str):
        """Evaluate current production model."""
        model = self._load_production_model(language_pair)
        
        # Translate reference set
        translations = []
        for source, reference in self.reference_set:
            translation = model.translate(source)
            translations.append((translation, reference))
        
        # Calculate metrics
        bleu_score = self._calculate_bleu(translations)
        inference_time = self._measure_inference_time(model)
        
        # Log metrics
        self._log_metrics({
            'language_pair': language_pair,
            'bleu_score': bleu_score,
            'inference_time_ms': inference_time,
            'timestamp': datetime.now().isoformat()
        })
        
        # Alert if degradation detected
        if bleu_score < self.baseline_bleu * 0.95:
            self._send_alert('Model quality degradation detected')
    
    def schedule_evaluations(self):
        """Schedule periodic evaluations."""
        # Run every 6 hours
        schedule.every(6).hours.do(self.evaluate_production_model)
```

---

## Conclusion

This design document provides a comprehensive blueprint for the MarianMT Model Training & Deployment Pipeline. The system is designed to be:

- **Automated:** Minimal manual intervention required
- **Scalable:** Supports adding new language pairs easily
- **Cost-Effective:** Optimized for AWS costs using spot instances
- **Reliable:** Robust error handling and disaster recovery
- **Maintainable:** Clear separation of concerns and modular design
- **Observable:** Comprehensive monitoring and logging

The pipeline enables BhashaLens to deliver high-quality offline translation for Indian languages while maintaining strict size and performance constraints for mobile deployment.
