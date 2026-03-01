# AWS Credentials Setup Guide

This guide explains how to connect your AWS credentials to deploy the BhashaLens infrastructure.

## Method 1: AWS CLI Configuration (Recommended)

This is the easiest and most secure method for local development.

### Step 1: Install AWS CLI

**Windows:**
```bash
# Download and run the MSI installer from:
# https://awscli.amazonaws.com/AWSCLIV2.msi

# Or using winget:
winget install Amazon.AWSCLI
```

**macOS:**
```bash
brew install awscli
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Step 2: Get Your AWS Credentials

1. Log in to AWS Console: https://console.aws.amazon.com/
2. Click your username (top right) → Security credentials
3. Scroll to "Access keys" section
4. Click "Create access key"
5. Choose "Command Line Interface (CLI)"
6. Click "Next" → "Create access key"
7. **Save your credentials**:
   - Access Key ID: `AKIAIOSFODNN7EXAMPLE`
   - Secret Access Key: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

⚠️ **Important**: Never share or commit these credentials to Git!

### Step 3: Configure AWS CLI

Run the configuration command:

```bash
aws configure
```

Enter your credentials when prompted:

```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

### Step 4: Verify Configuration

Test your credentials:

```bash
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

✅ **You're ready to deploy!** Terraform will automatically use these credentials.

---

## Method 2: Environment Variables

Use this method for CI/CD pipelines or temporary credentials.

### Windows (PowerShell):

```powershell
$env:AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
$env:AWS_DEFAULT_REGION="us-east-1"
```

### Windows (Command Prompt):

```cmd
set AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
set AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
set AWS_DEFAULT_REGION=us-east-1
```

### macOS/Linux (Bash):

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"
```

### Verify:

```bash
aws sts get-caller-identity
```

---

## Method 3: AWS Credentials File (Manual)

If you prefer to manually edit the credentials file:

### Location:

- **Windows**: `C:\Users\USERNAME\.aws\credentials`
- **macOS/Linux**: `~/.aws/credentials`

### Create/Edit the file:

```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Create/Edit config file:

**Location**: `~/.aws/config` (or `C:\Users\USERNAME\.aws\config` on Windows)

```ini
[default]
region = us-east-1
output = json
```

---

## Method 4: IAM Role (For EC2/Cloud Environments)

If deploying from an EC2 instance or AWS Cloud9:

1. Create an IAM role with required permissions
2. Attach the role to your EC2 instance
3. No credentials needed - AWS SDK automatically uses the role

**Required IAM Permissions:**
- `AmazonAPIGatewayAdministrator`
- `AWSLambda_FullAccess`
- `AmazonDynamoDBFullAccess`
- `AmazonS3FullAccess`
- `CloudWatchFullAccess`
- `IAMFullAccess`
- `AmazonBedrockFullAccess`

---

## Method 5: AWS SSO (Single Sign-On)

For organizations using AWS SSO:

### Step 1: Configure SSO

```bash
aws configure sso
```

Follow the prompts:
```
SSO start URL [None]: https://my-sso-portal.awsapps.com/start
SSO Region [None]: us-east-1
```

### Step 2: Login

```bash
aws sso login --profile bhashalens
```

### Step 3: Use the profile

```bash
export AWS_PROFILE=bhashalens
```

Or specify in Terraform:

```bash
terraform apply -var="aws_profile=bhashalens"
```

---

## Security Best Practices

### 1. Use IAM User with Minimal Permissions

Don't use root account credentials. Create a dedicated IAM user:

```bash
# Create IAM user
aws iam create-user --user-name bhashalens-deployer

# Attach policies
aws iam attach-user-policy \
  --user-name bhashalens-deployer \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create access key
aws iam create-access-key --user-name bhashalens-deployer
```

### 2. Enable MFA (Multi-Factor Authentication)

1. Go to IAM → Users → Your user → Security credentials
2. Enable MFA device
3. Use MFA-protected credentials for sensitive operations

### 3. Rotate Credentials Regularly

```bash
# Create new access key
aws iam create-access-key --user-name your-username

# Update your configuration
aws configure

# Delete old access key
aws iam delete-access-key \
  --user-name your-username \
  --access-key-id OLD_ACCESS_KEY_ID
```

### 4. Never Commit Credentials to Git

The `.gitignore` file already excludes:
- `*.tfvars` (except examples)
- `.aws/`
- `credentials`
- `.env`

### 5. Use AWS Secrets Manager for Production

For production deployments, store credentials in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name bhashalens/api-keys \
  --secret-string '{"api_key":"your-secret-key"}'
```

---

## Troubleshooting

### Error: "Unable to locate credentials"

**Solution**: Run `aws configure` and enter your credentials.

### Error: "The security token included in the request is invalid"

**Solution**: Your credentials are incorrect or expired. Run `aws configure` again.

### Error: "Access Denied" when running Terraform

**Solution**: Your IAM user lacks required permissions. Attach necessary policies.

### Error: "Region not specified"

**Solution**: Set default region:
```bash
aws configure set region us-east-1
```

### Error: "Credential should be scoped to a valid region"

**Solution**: Ensure your region is valid (e.g., `us-east-1`, not `us-east-1a`).

---

## Quick Start Checklist

- [ ] Install AWS CLI
- [ ] Create AWS account (if needed)
- [ ] Get Access Key ID and Secret Access Key
- [ ] Run `aws configure` and enter credentials
- [ ] Verify with `aws sts get-caller-identity`
- [ ] Enable Bedrock model access in AWS Console
- [ ] Navigate to `infrastructure/terraform/`
- [ ] Run `terraform init`
- [ ] Run `terraform plan`
- [ ] Run `terraform apply`

---

## Next Steps

After configuring credentials:

1. **Enable Bedrock Models**: Go to AWS Console → Bedrock → Model access
2. **Deploy Infrastructure**: Run `./infrastructure/deploy.sh`
3. **Test API Endpoints**: Use curl commands from README.md
4. **Configure Flutter App**: Update with API endpoint from Terraform outputs

---

## Additional Resources

- [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

---

## Support

If you encounter issues:
1. Check AWS CLI version: `aws --version` (should be v2.x)
2. Verify credentials: `aws sts get-caller-identity`
3. Check IAM permissions in AWS Console
4. Review CloudWatch logs for deployment errors
