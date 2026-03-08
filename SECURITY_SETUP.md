# BhashaLens Security Setup Guide

## 🔒 Protecting Secrets and API Keys

This guide explains how to properly manage secrets and API keys in the BhashaLens project to prevent them from being exposed on GitHub.

## Files That Contain Secrets

### 1. Environment Variables (.env)
**Location:** `bhashalens_app/.env`

**Contains:**
- Firebase API keys and configuration
- Gemini API key
- HuggingFace token

**Setup:**
1. Copy `.env.example` to `.env`
2. Fill in your actual API keys
3. **NEVER commit `.env` to git** (already in .gitignore)

```bash
cd bhashalens_app
cp .env.example .env
# Edit .env with your actual keys
```

### 2. Firebase Configuration Files

#### Android: google-services.json
**Location:** `bhashalens_app/android/app/google-services.json`

**Setup:**
1. Download from Firebase Console
2. Copy the example file:
   ```bash
   cp bhashalens_app/android/app/google-services.json.example bhashalens_app/android/app/google-services.json
   ```
3. Replace with your actual Firebase configuration
4. **NEVER commit the real file** (already in .gitignore)

#### iOS: GoogleService-Info.plist
**Location:** `bhashalens_app/ios/Runner/GoogleService-Info.plist`

**Setup:**
1. Download from Firebase Console
2. Place in `bhashalens_app/ios/Runner/`
3. **NEVER commit this file** (already in .gitignore)

### 3. Terraform Variables
**Location:** `infrastructure/terraform/terraform.tfvars`

**Contains:**
- AWS configuration
- Environment-specific settings

**Setup:**
1. Copy the example file:
   ```bash
   cd infrastructure/terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Customize for your deployment
3. **NEVER commit terraform.tfvars** (already in .gitignore)

### 4. AWS Credentials
**Location:** `~/.aws/credentials` (system-wide)

**Setup:**
Follow the guide in `infrastructure/AWS_CREDENTIALS_SETUP.md`

**NEVER store AWS credentials in the repository!**

## What's Protected by .gitignore

The following files and patterns are automatically ignored:

```
# Environment files
.env
.env.*
*.env

# Firebase
google-services.json
GoogleService-Info.plist
firebase-adminsdk-*.json
serviceAccountKey.json

# AWS
*.pem
*.key
*.crt
credentials
terraform.tfvars
*.tfvars

# Terraform state (may contain secrets)
.terraform/
*.tfstate
*.tfstate.*
```

## Removing Secrets Already Committed

If you've already committed secrets to git, follow these steps:

### Option 1: Remove from latest commit (if not pushed)
```bash
# Remove the file from git tracking
git rm --cached bhashalens_app/.env
git rm --cached bhashalens_app/android/app/google-services.json

# Commit the removal
git commit -m "Remove sensitive files from tracking"
```

### Option 2: Remove from git history (if already pushed)
```bash
# Use git filter-branch or BFG Repo-Cleaner
# WARNING: This rewrites history!

# Using BFG (recommended)
# Download from: https://rtyley.github.io/bfg-repo-cleaner/
java -jar bfg.jar --delete-files .env
java -jar bfg.jar --delete-files google-services.json
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (coordinate with team!)
git push --force
```

### Option 3: Rotate all exposed secrets
**CRITICAL:** If secrets were pushed to GitHub, assume they are compromised!

1. **Firebase:** Regenerate API keys in Firebase Console
2. **Gemini API:** Regenerate in Google AI Studio
3. **HuggingFace:** Regenerate token in HuggingFace settings
4. **AWS:** Rotate IAM credentials

## Example Files Included

The repository includes sanitized example files:

- `bhashalens_app/.env.example` - Environment variables template
- `bhashalens_app/android/app/google-services.json.example` - Firebase Android config template
- `infrastructure/terraform/terraform.tfvars.example` - Terraform variables template

## Verification Checklist

Before committing, verify:

- [ ] `.env` is not in `git status`
- [ ] `google-services.json` is not in `git status`
- [ ] `terraform.tfvars` is not in `git status`
- [ ] No API keys visible in `git diff`
- [ ] Only `.example` files are tracked

```bash
# Check what will be committed
git status

# Check for secrets in staged files
git diff --cached | grep -i "api.*key\|secret\|password\|token"
```

## GitHub Security Features

Enable these GitHub features for additional protection:

1. **Secret Scanning:** Automatically detects committed secrets
2. **Dependabot Alerts:** Monitors for vulnerable dependencies
3. **Branch Protection:** Require reviews before merging

## Best Practices

1. **Never hardcode secrets** in source code
2. **Use environment variables** for all sensitive data
3. **Rotate secrets regularly** (every 90 days)
4. **Use different secrets** for dev/staging/production
5. **Review commits** before pushing
6. **Enable 2FA** on all service accounts
7. **Use AWS Secrets Manager** or similar for production

## Emergency Response

If secrets are exposed:

1. **Immediately rotate** all exposed credentials
2. **Review access logs** for unauthorized usage
3. **Update all environments** with new credentials
4. **Document the incident**
5. **Review security practices** to prevent recurrence

## Additional Resources

- [Firebase Security Best Practices](https://firebase.google.com/docs/projects/api-keys)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

## Support

For security concerns, contact the development team immediately.

**DO NOT** discuss specific secrets in public channels or issues!
