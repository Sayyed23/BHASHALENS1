# BhashaLens AWS Infrastructure - Quick Start Guide

This guide will help you deploy the BhashaLens AWS infrastructure in under 15 minutes.

## Prerequisites Checklist

- [ ] AWS Account created
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] Terraform installed (version >= 1.0)
- [ ] Amazon Bedrock model access enabled (see below)

## Step 1: Enable Amazon Bedrock Models (5 minutes)

1. Log in to AWS Console
2. Navigate to **Amazon Bedrock** → **Model access**
3. Click **Manage model access**
4. Enable the following models:
   - ✅ Claude 3 Sonnet
   - ✅ Titan Text Premier
   - ✅ Titan Embeddings
5. Click **Save changes**
6. Wait for approval (usually instant)

## Step 2: Deploy Infrastructure (5 minutes)

### Option A: Automated Deployment (Recommended)

```bash
cd infrastructure
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Check prerequisites
- Initialize Terraform
- Show deployment plan
- Deploy infrastructure
- Display outputs

### Option B: Manual Deployment

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

Type `yes` when prompted.

## Step 3: Save Outputs (1 minute)

After deployment, save these values:

```
API Endpoint: https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/production/v1
S3 Bucket: bhashalens-models-xxxxxxxxxxxx
CloudWatch Dashboard: https://console.aws.amazon.com/cloudwatch/...
```

## Step 4: Test API (2 minutes)

Test the translation endpoint:

```bash
# Replace YOUR_API_ENDPOINT with the actual endpoint from outputs
curl -X POST https://YOUR_API_ENDPOINT/v1/translate \
  -H "Content-Type: application/json" \
  -d '{
    "source_text": "Hello, how are you?",
    "source_lang": "en",
    "target_lang": "hi"
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

## Step 5: Configure Flutter App (2 minutes)

Update your Flutter app's `.env` file:

```env
# AWS Configuration
AWS_API_ENDPOINT=https://YOUR_API_ENDPOINT/v1
AWS_REGION=us-east-1
AWS_S3_BUCKET=bhashalens-models-xxxxxxxxxxxx

# Enable cloud features
ENABLE_CLOUD_TRANSLATION=true
ENABLE_CLOUD_ASSISTANCE=true
ENABLE_CLOUD_SIMPLIFICATION=true
```

## What's Deployed?

✅ **API Gateway** - REST API with HTTPS endpoints  
✅ **Lambda Functions** - Translation, Assistance, Simplification handlers  
✅ **Amazon Bedrock** - Claude 3 Sonnet, Titan models  
✅ **DynamoDB** - 3 tables with encryption enabled  
✅ **S3** - 2 buckets with versioning and encryption  
✅ **CloudWatch** - Dashboard, logs, and alarms  
✅ **IAM** - Roles and policies with least privilege  

## Monitoring

Access CloudWatch Dashboard:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=bhashalens-dashboard
```

View Lambda logs:
```bash
aws logs tail /aws/lambda/bhashalens-translation-handler --follow
```

## Cost Estimate

**Monthly cost for moderate usage (10,000 requests):**
- API Gateway: ~$35
- Lambda: ~$20
- Bedrock: ~$100-200
- DynamoDB: ~$5
- S3: ~$5
- CloudWatch: ~$10

**Total: ~$175-250/month**

## Troubleshooting

### Issue: "Access Denied" when calling Bedrock

**Solution**: Enable Bedrock model access in AWS Console (Step 1)

### Issue: "Terraform init failed"

**Solution**: Check internet connection and AWS credentials

### Issue: "Lambda timeout"

**Solution**: Increase timeout in `variables.tf`:
```hcl
lambda_timeout = 60  # Increase from 30 to 60 seconds
```

### Issue: API returns 403 error

**Solution**: Check IAM permissions and API Gateway configuration

## Next Steps

1. **Upload Language Packs**: Upload model files to S3 bucket
2. **Configure Alarms**: Set up SNS notifications for CloudWatch alarms
3. **Enable Authentication**: Add API Gateway authentication (API Keys or Cognito)
4. **Test Integration**: Test Flutter app with cloud backend
5. **Monitor Usage**: Review CloudWatch dashboard regularly

## Cleanup

To remove all infrastructure:

```bash
cd infrastructure/terraform
terraform destroy
```

⚠️ **Warning**: This will permanently delete all data!

## Support

- 📖 Full documentation: `infrastructure/README.md`
- 🐛 Issues: Check CloudWatch logs
- 💬 AWS Support: https://console.aws.amazon.com/support/

## Security Checklist

- [ ] Enable AWS CloudTrail for audit logging
- [ ] Set up SNS notifications for CloudWatch alarms
- [ ] Implement API Gateway authentication
- [ ] Review IAM policies regularly
- [ ] Enable MFA for AWS root account
- [ ] Rotate IAM credentials periodically

---

**Deployment Time**: ~15 minutes  
**Difficulty**: Beginner-friendly  
**Cost**: ~$175-250/month for moderate usage
