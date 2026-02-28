# AWS Powers Guide for BhashaLens in Kiro

## Overview

This guide explains which AWS Powers to enable in Kiro for developing and deploying the BhashaLens application. AWS Powers provide integrated access to AWS services directly within your development workflow.

## Required AWS Powers

### 1. AWS Bedrock Power

**Purpose**: Access Amazon Bedrock foundation models for cloud-enhanced translation, assistance, and simplification.

**Why Needed**:
- Claude 3 Sonnet for high-quality contextual translation
- Titan Text for lightweight text generation
- Titan Embeddings for semantic search and conversation context

**How to Enable in Kiro**:
```bash
# Open Kiro Powers panel
# Search for "AWS Bedrock" or "Bedrock"
# Click "Install" or "Enable"
```

**Usage in BhashaLens**:
- Enhanced translation quality for complex text
- Context-aware assistance responses
- Advanced text simplification and explanation
- Conversation continuity through embeddings

**Configuration Needed**:
- AWS credentials (Access Key ID, Secret Access Key)
- AWS region (e.g., us-east-1, us-west-2)
- Bedrock model access (request access to Claude 3 and Titan models)

---

### 2. AWS Lambda Power

**Purpose**: Deploy and manage serverless Lambda functions for API endpoints.

**Why Needed**:
- Translation request handler
- Assistance request handler
- Simplification request handler
- Sync operations handler

**How to Enable in Kiro**:
```bash
# Open Kiro Powers panel
# Search for "AWS Lambda"
# Click "Install" or "Enable"
```

**Usage in BhashaLens**:
- Create Lambda functions for each API endpoint
- Deploy function code from Kiro
- Monitor function logs and metrics
- Update functions during development

**Configuration Needed**:
- AWS credentials
- IAM role with Lambda execution permissions
- Lambda function runtime (Python 3.11)

---

### 3. AWS DynamoDB Power

**Purpose**: Manage NoSQL database tables for user data and metadata.

**Why Needed**:
- Store user preferences
- Store translation history (with consent)
- Store language pack metadata
- Track API usage and analytics

**How to Enable in Kiro**:
```bash
# Open Kiro Powers panel
# Search for "AWS DynamoDB" or "DynamoDB"
# Click "Install" or "Enable"
```

**Usage in BhashaLens**:
- Create and manage tables
- Query and scan operations
- Monitor table metrics
- Configure backup and recovery

**Tables to Create**:
```
UserPreferences (PK: user_id)
TranslationHistory (PK: user_id, SK: timestamp)
LanguagePackMetadata (PK: pack_id)
```

**Configuration Needed**:
- AWS credentials
- IAM role with DynamoDB permissions
- Billing mode (on-demand recommended)

---

### 4. AWS S3 Power

**Purpose**: Store and distribute language packs, models, and user-generated content.

**Why Needed**:
- Host language pack downloads
- Store LLM model files
- Store temporary OCR images
- Backup and archival

**How to Enable in Kiro**:
```bash
# Open Kiro Powers panel
# Search for "AWS S3" or "S3"
# Click "Install" or "Enable"
```

**Usage in BhashaLens**:
- Upload language packs
- Generate pre-signed URLs for downloads
- Configure bucket policies
- Enable versioning and encryption

**Buckets to Create**:
```
bhashalens-models (language packs and LLM models)
bhashalens-user-data (user uploads, with encryption)
bhashalens-backups (database backups)
```

**Configuration Needed**:
- AWS credentials
- IAM role with S3 permissions
- Encryption at rest (AES-256)
- Lifecycle policies for cost optimization

---

### 5. AWS API Gateway Power

**Purpose**: Create and manage REST API endpoints for mobile app communication.

**Why Needed**:
- Expose Lambda functions as HTTP endpoints
- Handle authentication and authorization
- Rate limiting and throttling
- Request/response transformation

**How to Enable in Kiro**:
```bash
# Open Kiro Powers panel
# Search for "AWS API Gateway"
# Click "Install" or "Enable"
```

**Usage in BhashaLens**:
- Create REST API
- Define resources and methods
- Configure CORS for mobile app
- Deploy to stages (dev, staging, prod)

**Endpoints to Create**:
```
POST /v1/translate
POST /v1/assist
POST /v1/simplify
POST /v1/sync/preferences
POST /v1/sync/history
GET  /v1/language-packs
GET  /v1/language-packs/{pack-id}/download
```

**Configuration Needed**:
- AWS credentials
- IAM role with API Gateway permissions
- API key or JWT authentication
- Usage plans and rate limits

---

### 6. AWS CloudWatch Power

**Purpose**: Monitor application logs, metrics, and set up alarms.

**Why Needed**:
- Lambda function logs
- API Gateway access logs
- Custom application metrics
- Performance monitoring
- Error tracking and alerting

**How to Enable in Kiro**:
```bash
# Open Kiro Powers panel
# Search for "AWS CloudWatch"
# Click "Install" or "Enable"
```

**Usage in BhashaLens**:
- View Lambda function logs
- Create custom metrics dashboards
- Set up alarms for errors and latency
- Monitor API usage and costs

**Metrics to Track**:
- Lambda invocation count and duration
- API Gateway request count and latency
- DynamoDB read/write capacity
- S3 request count and data transfer
- Bedrock API usage and costs

**Configuration Needed**:
- AWS credentials
- IAM role with CloudWatch permissions
- Log retention policies
- Alarm notification targets (SNS, email)

---

### 7. AWS IAM Power

**Purpose**: Manage identity and access management for AWS resources.

**Why Needed**:
- Create service roles for Lambda functions
- Configure least-privilege access policies
- Manage API keys and credentials
- Set up cross-service permissions

**How to Enable in Kiro**:
```bash
# Open Kiro Powers panel
# Search for "AWS IAM"
# Click "Install" or "Enable"
```

**Usage in BhashaLens**:
- Create Lambda execution role
- Create API Gateway invocation role
- Configure Bedrock access policies
- Manage user access credentials

**Roles to Create**:
```
BhashaLensLambdaExecutionRole
BhashaLensAPIGatewayRole
BhashaLensBedrockAccessRole
```

**Configuration Needed**:
- AWS root account or admin credentials
- Understanding of IAM policies and roles

---

## Optional AWS Powers (Recommended)

### 8. AWS CloudFormation / Terraform Power

**Purpose**: Infrastructure as Code for reproducible deployments.

**Why Needed**:
- Automate infrastructure provisioning
- Version control infrastructure changes
- Consistent deployments across environments
- Easy rollback and disaster recovery

**Usage**: Define all AWS resources in code and deploy with a single command.

---

### 9. AWS X-Ray Power

**Purpose**: Distributed tracing for debugging and performance optimization.

**Why Needed**:
- Trace requests across Lambda, API Gateway, DynamoDB
- Identify performance bottlenecks
- Debug errors in distributed system
- Visualize service dependencies

**Usage**: Enable X-Ray tracing on Lambda functions and API Gateway to see end-to-end request flows.

---

### 10. AWS CloudFront Power

**Purpose**: Content Delivery Network for fast language pack distribution.

**Why Needed**:
- Reduce language pack download latency
- Lower S3 data transfer costs
- Cache frequently accessed content
- Global edge locations for users worldwide

**Usage**: Create CloudFront distribution pointing to S3 bucket with language packs.

---

## Setup Instructions

### Step 1: Install AWS CLI

```bash
# Install AWS CLI (if not already installed)
# Windows
choco install awscli

# Verify installation
aws --version
```

### Step 2: Configure AWS Credentials

```bash
# Configure AWS credentials
aws configure

# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)
```

### Step 3: Enable Powers in Kiro

1. Open Kiro IDE
2. Navigate to Powers panel (View → Powers or Ctrl+Shift+P → "Powers")
3. Search for each AWS Power listed above
4. Click "Install" or "Enable" for each power
5. Follow any additional configuration prompts

### Step 4: Verify Power Installation

```bash
# In Kiro terminal, test AWS access
aws sts get-caller-identity

# Should return your AWS account information
```

### Step 5: Request Bedrock Model Access

1. Go to AWS Console → Amazon Bedrock
2. Navigate to "Model access"
3. Request access to:
   - Claude 3 Sonnet
   - Titan Text Premier
   - Titan Embeddings
4. Wait for approval (usually instant for Titan, may take time for Claude)

---

## Power Usage Examples

### Example 1: Deploy Lambda Function

```python
# In Kiro, with AWS Lambda Power enabled
# Create file: lambda/translation_handler.py

import json
import boto3

bedrock = boto3.client('bedrock-runtime')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    source_text = body['source_text']
    target_lang = body['target_lang']
    
    # Call Bedrock for translation
    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-sonnet-20240229-v1:0',
        body=json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1024,
            "messages": [{
                "role": "user",
                "content": f"Translate to {target_lang}: {source_text}"
            }]
        })
    )
    
    result = json.loads(response['body'].read())
    translated_text = result['content'][0]['text']
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'translated_text': translated_text
        })
    }
```

```bash
# Deploy using Kiro AWS Lambda Power
# Right-click on lambda/translation_handler.py
# Select "Deploy to AWS Lambda"
# Or use command palette: "AWS Lambda: Deploy Function"
```

### Example 2: Create DynamoDB Table

```bash
# In Kiro terminal, with AWS DynamoDB Power enabled
aws dynamodb create-table \
    --table-name BhashaLens-UserPreferences \
    --attribute-definitions \
        AttributeName=user_id,AttributeType=S \
    --key-schema \
        AttributeName=user_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

### Example 3: Upload Language Pack to S3

```bash
# In Kiro terminal, with AWS S3 Power enabled
aws s3 cp language_packs/hi-en/ \
    s3://bhashalens-models/language-packs/v1/hi-en/ \
    --recursive \
    --storage-class STANDARD
```

### Example 4: Query CloudWatch Logs

```bash
# In Kiro terminal, with AWS CloudWatch Power enabled
aws logs tail /aws/lambda/bhashalens-translation \
    --follow \
    --format short
```

---

## Cost Estimation

### Monthly Cost Estimate (1000 active users)

**Compute (Lambda)**:
- 100,000 requests/month
- 1GB memory, 5s average duration
- Cost: ~$8/month

**Storage (S3)**:
- 10GB language packs
- 1000 downloads/month
- Cost: ~$1/month

**Database (DynamoDB)**:
- On-demand pricing
- 100,000 read/write requests/month
- Cost: ~$2/month

**AI/ML (Bedrock)**:
- Claude 3 Sonnet: $3 per 1M input tokens, $15 per 1M output tokens
- 10,000 requests/month, avg 500 tokens each
- Cost: ~$30/month

**API Gateway**:
- 100,000 requests/month
- Cost: ~$0.35/month

**Total Estimated Cost**: ~$41/month for 1000 active users

**Cost Optimization Tips**:
- Use on-device models as primary (free)
- Route to cloud only for complex requests
- Cache Bedrock responses
- Use CloudFront CDN for language pack distribution
- Implement request batching where possible

---

## Security Best Practices

1. **Never commit AWS credentials to version control**
   - Use environment variables or AWS Secrets Manager
   - Add `.env` and `aws-credentials.json` to `.gitignore`

2. **Use IAM roles with least privilege**
   - Grant only necessary permissions
   - Use separate roles for different services
   - Regularly audit and rotate credentials

3. **Enable encryption everywhere**
   - S3: Server-side encryption (AES-256)
   - DynamoDB: Encryption at rest
   - API Gateway: HTTPS only
   - Lambda: Environment variable encryption

4. **Implement rate limiting**
   - API Gateway usage plans
   - Lambda reserved concurrency
   - DynamoDB auto-scaling

5. **Monitor and alert**
   - CloudWatch alarms for errors
   - Cost anomaly detection
   - Security Hub for compliance

---

## Troubleshooting

### Issue: "Access Denied" errors

**Solution**:
- Check IAM role permissions
- Verify AWS credentials are configured correctly
- Ensure Bedrock model access is approved

### Issue: Lambda timeout errors

**Solution**:
- Increase Lambda timeout (max 15 minutes)
- Optimize code for faster execution
- Use async/await for I/O operations

### Issue: High Bedrock costs

**Solution**:
- Implement response caching
- Use Titan models for simpler tasks (cheaper than Claude)
- Route more requests to on-device models
- Implement request batching

### Issue: S3 download slow

**Solution**:
- Enable CloudFront CDN
- Use S3 Transfer Acceleration
- Compress language packs with ZSTD

---

## Next Steps

1. Enable all required AWS Powers in Kiro
2. Configure AWS credentials
3. Request Bedrock model access
4. Create initial infrastructure (Lambda, DynamoDB, S3, API Gateway)
5. Deploy test Lambda function
6. Test end-to-end flow from Android app to AWS
7. Set up monitoring and alarms
8. Implement cost tracking and optimization

---

## Additional Resources

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/)
- [CloudWatch User Guide](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/)

---

## Support

For issues with AWS Powers in Kiro:
- Check Kiro documentation
- Visit Kiro community forums
- Contact Kiro support

For AWS-specific issues:
- AWS Support (if you have a support plan)
- AWS Forums
- Stack Overflow (tag: amazon-web-services)
