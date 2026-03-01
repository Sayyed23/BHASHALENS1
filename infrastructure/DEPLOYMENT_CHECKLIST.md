# BhashaLens AWS Infrastructure Deployment Checklist

Use this checklist to ensure a successful deployment of the BhashaLens AWS infrastructure.

## Pre-Deployment

### AWS Account Setup
- [ ] AWS account created
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS credentials configured (`aws configure`)
- [ ] IAM user has appropriate permissions (AdministratorAccess or custom policy)
- [ ] MFA enabled on AWS root account

### Bedrock Model Access
- [ ] Logged into AWS Console
- [ ] Navigated to Amazon Bedrock → Model access
- [ ] Enabled Claude 3 Sonnet model
- [ ] Enabled Titan Text Premier model
- [ ] Enabled Titan Embeddings model
- [ ] Model access approved (check status)

### Development Tools
- [ ] Terraform installed (>= 1.0)
- [ ] Git installed
- [ ] Code editor/IDE ready
- [ ] Terminal/command line access

## Deployment

### Infrastructure Deployment
- [ ] Cloned repository
- [ ] Navigated to `infrastructure/terraform` directory
- [ ] Reviewed `variables.tf` for configuration options
- [ ] Created `terraform.tfvars` (optional, for custom values)
- [ ] Ran `terraform init` successfully
- [ ] Ran `terraform plan` and reviewed output
- [ ] Ran `terraform apply` and confirmed with "yes"
- [ ] Deployment completed without errors
- [ ] Saved Terraform outputs (API endpoint, S3 bucket, etc.)

### Verification
- [ ] API Gateway endpoint accessible
- [ ] Lambda functions created and active
- [ ] DynamoDB tables created with encryption enabled
- [ ] S3 buckets created with versioning and encryption
- [ ] CloudWatch dashboard accessible
- [ ] CloudWatch log groups created
- [ ] IAM roles and policies created

### Testing
- [ ] Tested translation endpoint with curl/Postman
- [ ] Tested assistance endpoint
- [ ] Tested simplification endpoint
- [ ] Verified responses are correct
- [ ] Checked CloudWatch logs for Lambda invocations
- [ ] Verified DynamoDB entries (if user_id provided)

## Post-Deployment

### Monitoring Setup
- [ ] Accessed CloudWatch dashboard
- [ ] Reviewed default alarms
- [ ] Created SNS topic for alarm notifications
- [ ] Subscribed email to SNS topic
- [ ] Confirmed email subscription
- [ ] Tested alarm notifications (optional)

### Security Configuration
- [ ] Reviewed IAM roles and policies
- [ ] Enabled AWS CloudTrail for audit logging
- [ ] Enabled AWS Config for compliance monitoring
- [ ] Reviewed S3 bucket policies
- [ ] Verified encryption at rest for all data stores
- [ ] Confirmed HTTPS enforcement for API Gateway

### Application Integration
- [ ] Updated Flutter app `.env` file with API endpoint
- [ ] Updated Flutter app with AWS region
- [ ] Updated Flutter app with S3 bucket name
- [ ] Enabled cloud features in app configuration
- [ ] Tested Flutter app with cloud backend
- [ ] Verified offline-to-online transitions work

### Documentation
- [ ] Documented API endpoint for team
- [ ] Documented S3 bucket name and structure
- [ ] Documented CloudWatch dashboard URL
- [ ] Created runbook for common operations
- [ ] Documented troubleshooting steps

## Ongoing Maintenance

### Weekly Tasks
- [ ] Review CloudWatch alarms
- [ ] Check Lambda error rates
- [ ] Monitor API Gateway latency
- [ ] Review DynamoDB capacity usage

### Monthly Tasks
- [ ] Review AWS costs and optimize
- [ ] Update Lambda runtimes if needed
- [ ] Review and rotate IAM credentials
- [ ] Check for Terraform updates
- [ ] Review CloudWatch log retention

### Quarterly Tasks
- [ ] Security audit of IAM policies
- [ ] Review and update Bedrock model versions
- [ ] Performance optimization review
- [ ] Disaster recovery drill
- [ ] Update documentation

### Annual Tasks
- [ ] Comprehensive security review
- [ ] Architecture review and optimization
- [ ] Cost analysis and budget planning
- [ ] Update compliance documentation

## Rollback Plan

If deployment fails or issues arise:

1. **Immediate Rollback**:
   ```bash
   cd infrastructure/terraform
   terraform destroy
   ```

2. **Partial Rollback** (specific resources):
   ```bash
   terraform destroy -target=aws_lambda_function.translation
   ```

3. **State Recovery**:
   ```bash
   terraform state list
   terraform state show <resource>
   ```

## Emergency Contacts

- **AWS Support**: https://console.aws.amazon.com/support/
- **Terraform Support**: https://www.terraform.io/docs
- **Team Lead**: [Add contact]
- **DevOps Engineer**: [Add contact]

## Cost Monitoring

### Expected Monthly Costs
- API Gateway: $35
- Lambda: $20
- Bedrock: $100-200
- DynamoDB: $5
- S3: $5
- CloudWatch: $10
- **Total**: ~$175-250/month

### Cost Alerts
- [ ] Set up AWS Budget for $300/month
- [ ] Enable cost anomaly detection
- [ ] Review AWS Cost Explorer weekly

## Compliance

- [ ] GDPR compliance reviewed (if applicable)
- [ ] Data retention policies configured
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] User consent mechanisms in place

## Success Criteria

✅ All infrastructure deployed successfully  
✅ API endpoints responding correctly  
✅ CloudWatch monitoring active  
✅ Security best practices implemented  
✅ Flutter app integrated with cloud backend  
✅ Documentation complete  
✅ Team trained on operations  

---

**Last Updated**: [Date]  
**Deployed By**: [Name]  
**Environment**: Production  
**Region**: us-east-1
