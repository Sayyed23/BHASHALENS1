# BhashaLens AWS Infrastructure

This directory contains Infrastructure as Code (IaC) for deploying the BhashaLens cloud backend on AWS.

## Architecture Overview

The BhashaLens AWS infrastructure consists of:

- **API Gateway**: REST API with HTTPS endpoints for translation, assistance, and simplification
- **Lambda Functions**: Serverless compute for processing requests using Amazon Bedrock
- **Amazon Bedrock**: AI models (Claude 3 Sonnet, Titan Text, Titan Embeddings)
- **DynamoDB**: NoSQL database for user preferences, translation history, and language pack metadata
- **S3**: Object storage for language packs and models
- **CloudWatch**: Logging, monitoring, and alarms
- **IAM**: Roles and policies with least privilege access

## Prerequisites

### 1. AWS Account Setup

1. Create an AWS account if you don't have one
2. Configure AWS CLI with your credentials:
   ```bash
   aws configure
   ```
3. Ensure you have appropriate IAM permissions to create resources

### 2. Enable Amazon Bedrock Models

Amazon Bedrock models must be enabled in your AWS account before use:

1. Go to AWS Console → Amazon Bedrock → Model access
2. Request access to the following models:
   - Claude 3 Sonnet (`anthropic.claude-3-sonnet-20240229-v1:0`)
   - Titan Text Premier (`amazon.titan-text-premier-v1:0`)
   - Titan Embeddings (`amazon.titan-embed-text-v2:0`)
3. Wait for approval (usually instant for most models)

### 3. Install Terraform

Install Terraform (version >= 1.0):

```bash
# macOS
brew install terraform

# Windows (using Chocolatey)
choco install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

Verify installation:
```bash
terraform version
```

## Deployment Instructions

### Step 1: Initialize Terraform

Navigate to the terraform directory and initialize:

```bash
cd infrastructure/terraform
terraform init
```

This will download the required AWS provider plugins.

### Step 2: Review Configuration

Review and customize variables in `variables.tf` or create a `terraform.tfvars` file:

```hcl
# terraform.tfvars
aws_region  = "us-east-1"
environment = "production"
project_name = "bhashalens"

# Customize if needed
lambda_timeout = 30
lambda_memory_size = 512
cloudwatch_log_retention_days = 30
```

### Step 3: Plan Deployment

Preview the resources that will be created:

```bash
terraform plan
```

Review the output to ensure all resources are correct.

### Step 4: Deploy Infrastructure

Apply the Terraform configuration:

```bash
terraform apply
```

Type `yes` when prompted to confirm deployment.

Deployment typically takes 5-10 minutes.

### Step 5: Verify Deployment

After successful deployment, Terraform will output important information:

```
Outputs:

api_endpoint = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/production/v1"
api_endpoints = {
  assist = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/production/v1/assist"
  simplify = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/production/v1/simplify"
  translate = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/production/v1/translate"
}
cloudwatch_dashboard_url = "https://console.aws.amazon.com/cloudwatch/..."
```

Save these outputs for configuring the Flutter application.

## Testing the API

### Test Translation Endpoint

```bash
curl -X POST https://YOUR_API_ENDPOINT/v1/translate \
  -H "Content-Type: application/json" \
  -d '{
    "source_text": "Hello, how are you?",
    "source_lang": "en",
    "target_lang": "hi",
    "user_id": "test-user-123"
  }'
```

Expected response:
```json
{
  "translated_text": "नमस्ते, आप कैसे हैं?",
  "confidence": 0.85,
  "model": "anthropic.claude-3-sonnet-20240229-v1:0",
  "processing_time_ms": 1234
}
```

### Test Assistance Endpoint

```bash
curl -X POST https://YOUR_API_ENDPOINT/v1/assist \
  -H "Content-Type: application/json" \
  -d '{
    "request_type": "grammar",
    "text": "I goes to school yesterday",
    "language": "en"
  }'
```

### Test Simplification Endpoint

```bash
curl -X POST https://YOUR_API_ENDPOINT/v1/simplify \
  -H "Content-Type: application/json" \
  -d '{
    "text": "The implementation of quantum computing algorithms necessitates sophisticated error correction mechanisms.",
    "target_complexity": "simple",
    "language": "en",
    "explain": true
  }'
```

## Monitoring and Observability

### CloudWatch Dashboard

Access the CloudWatch dashboard to monitor:
- Lambda invocations and errors
- API Gateway requests and latency
- DynamoDB capacity usage
- Bedrock model invocations
- Custom processing time metrics

Dashboard URL is provided in Terraform outputs.

### CloudWatch Alarms

The following alarms are configured:
- Lambda function errors (threshold: 5 errors in 5 minutes)
- Lambda duration exceeding 5 seconds
- API Gateway 5XX errors (threshold: 10 errors in 5 minutes)
- API Gateway latency exceeding 5 seconds
- DynamoDB user and system errors
- Bedrock throttling and errors

Configure SNS topics to receive alarm notifications:

```bash
# Create SNS topic
aws sns create-topic --name bhashalens-alarms

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:bhashalens-alarms \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### CloudWatch Logs

View logs for each component:

```bash
# Translation Lambda logs
aws logs tail /aws/lambda/bhashalens-translation-handler --follow

# API Gateway logs
aws logs tail /aws/apigateway/bhashalens-api --follow

# Bedrock logs
aws logs tail /aws/bedrock/bhashalens --follow
```

## Cost Optimization

### Estimated Monthly Costs

Based on moderate usage (10,000 requests/month):

- **API Gateway**: ~$35 (10,000 requests)
- **Lambda**: ~$20 (compute time)
- **Bedrock**: ~$100-200 (model invocations, varies by model)
- **DynamoDB**: ~$5 (on-demand pricing)
- **S3**: ~$5 (storage and requests)
- **CloudWatch**: ~$10 (logs and metrics)

**Total**: ~$175-250/month

### Cost Reduction Strategies

1. **Use Reserved Capacity**: For predictable workloads, use DynamoDB reserved capacity
2. **Optimize Lambda Memory**: Adjust memory based on actual usage
3. **Implement Caching**: Cache frequent translations to reduce Bedrock calls
4. **Use S3 Lifecycle Policies**: Automatically archive old language packs to Glacier
5. **Set CloudWatch Log Retention**: Reduce retention period for non-critical logs
6. **Monitor Bedrock Usage**: Track and optimize model invocations

## Security Best Practices

### 1. Enable AWS CloudTrail

Track all API calls for auditing:

```bash
aws cloudtrail create-trail \
  --name bhashalens-trail \
  --s3-bucket-name bhashalens-cloudtrail-logs
```

### 2. Enable AWS Config

Monitor resource configuration changes:

```bash
aws configservice put-configuration-recorder \
  --configuration-recorder name=bhashalens-config,roleARN=arn:aws:iam::ACCOUNT_ID:role/config-role
```

### 3. Implement API Authentication

Add API Gateway authentication:
- AWS IAM authentication
- API Keys for rate limiting
- Cognito User Pools for user authentication

### 4. Enable VPC Endpoints

For enhanced security, deploy Lambda functions in VPC with VPC endpoints for AWS services.

### 5. Rotate IAM Credentials

Regularly rotate IAM access keys and use temporary credentials when possible.

## Disaster Recovery

### Backup Strategy

1. **DynamoDB**: Point-in-time recovery is enabled (35-day retention)
2. **S3**: Versioning is enabled for language packs bucket
3. **Lambda**: Code is stored in S3 and version-controlled in Git

### Recovery Procedures

#### Restore DynamoDB Table

```bash
aws dynamodb restore-table-to-point-in-time \
  --source-table-name bhashalens-translation-history \
  --target-table-name bhashalens-translation-history-restored \
  --restore-date-time 2024-01-01T00:00:00Z
```

#### Restore S3 Object Version

```bash
aws s3api list-object-versions \
  --bucket bhashalens-models-ACCOUNT_ID \
  --prefix language-packs/

aws s3api get-object \
  --bucket bhashalens-models-ACCOUNT_ID \
  --key language-packs/v1/hi-en/translation_model.bin \
  --version-id VERSION_ID \
  output.bin
```

## Updating Infrastructure

### Update Lambda Functions

After modifying Lambda code:

```bash
cd infrastructure/terraform
terraform apply
```

Terraform will detect changes and update only the modified resources.

### Update Configuration

Modify `variables.tf` or `terraform.tfvars`, then:

```bash
terraform plan
terraform apply
```

## Destroying Infrastructure

To remove all resources (use with caution):

```bash
terraform destroy
```

Type `yes` to confirm deletion.

**Note**: This will permanently delete all data in DynamoDB and S3 (unless deletion protection is enabled).

## Troubleshooting

### Issue: Bedrock Access Denied

**Solution**: Ensure Bedrock models are enabled in your AWS account (see Prerequisites).

### Issue: Lambda Timeout

**Solution**: Increase `lambda_timeout` variable in `variables.tf`.

### Issue: API Gateway 403 Error

**Solution**: Check IAM permissions and API Gateway resource policies.

### Issue: DynamoDB Throttling

**Solution**: Switch to provisioned capacity or increase on-demand limits.

### Issue: S3 Access Denied

**Solution**: Verify S3 bucket policy and IAM role permissions.

## Support and Maintenance

### Regular Maintenance Tasks

1. **Weekly**: Review CloudWatch alarms and metrics
2. **Monthly**: Analyze costs and optimize resources
3. **Quarterly**: Update Lambda runtimes and dependencies
4. **Annually**: Review and update security policies

### Getting Help

- AWS Support: https://console.aws.amazon.com/support/
- Terraform Documentation: https://www.terraform.io/docs
- Amazon Bedrock Documentation: https://docs.aws.amazon.com/bedrock/

## Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)

## License

This infrastructure code is part of the BhashaLens project.
