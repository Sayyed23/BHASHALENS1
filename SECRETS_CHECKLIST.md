# 🔒 Secrets Protection Checklist

## Quick Reference: What's Protected

### ✅ Files That Are Ignored (Safe)

These files contain secrets but are **NOT tracked by git**:

- `bhashalens_app/.env` - API keys and tokens
- `bhashalens_app/android/app/google-services.json` - Firebase Android config
- `bhashalens_app/ios/Runner/GoogleService-Info.plist` - Firebase iOS config
- `infrastructure/terraform/terraform.tfvars` - AWS configuration
- `infrastructure/terraform/*.tfstate` - Terraform state (may contain secrets)

### ✅ Example Files (Safe to Commit)

These are templates with placeholder values:

- `bhashalens_app/.env.example`
- `bhashalens_app/android/app/google-services.json.example`
- `infrastructure/terraform/terraform.tfvars.example`

### ⚠️ What Was Removed

The following file was **removed from git tracking**:

- `bhashalens_app/android/app/google-services.json` (contained real Firebase credentials)

## Before Every Commit

Run this command to check for secrets:

```bash
# Check what will be committed
git status

# Search for potential secrets in staged files
git diff --cached | grep -iE "api.*key|secret|password|token|credential"
```

## Setup Instructions

### 1. Environment Variables (.env)

```bash
cd bhashalens_app
cp .env.example .env
# Edit .env with your actual keys
```

### 2. Firebase Configuration

```bash
# Android
cp bhashalens_app/android/app/google-services.json.example \
   bhashalens_app/android/app/google-services.json
# Download real file from Firebase Console and replace

# iOS
# Download GoogleService-Info.plist from Firebase Console
# Place in bhashalens_app/ios/Runner/
```

### 3. Terraform Variables

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS settings
```

### 4. AWS Credentials

Follow: `infrastructure/AWS_CREDENTIALS_SETUP.md`

## Verification Commands

```bash
# Verify .env is ignored
git check-ignore bhashalens_app/.env
# Should output: bhashalens_app/.gitignore:16:.env

# Verify google-services.json is ignored
git check-ignore bhashalens_app/android/app/google-services.json
# Should output: bhashalens_app/.gitignore:21:google-services.json

# Verify terraform.tfvars is ignored
git check-ignore infrastructure/terraform/terraform.tfvars
# Should output: infrastructure/.gitignore:4:*.tfvars

# Check if any secrets are tracked
git ls-files | grep -iE "\.env$|google-services\.json$|\.tfvars$"
# Should return nothing (empty)
```

## Emergency: Secrets Were Committed

If you accidentally committed secrets:

### 1. Not Pushed Yet (Easy Fix)

```bash
# Remove from staging
git reset HEAD bhashalens_app/.env

# Or remove from last commit
git rm --cached bhashalens_app/.env
git commit --amend
```

### 2. Already Pushed (Requires History Rewrite)

```bash
# Remove from git history (WARNING: Rewrites history!)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch bhashalens_app/.env" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (coordinate with team!)
git push --force --all
```

### 3. Rotate All Exposed Secrets

**CRITICAL:** If pushed to GitHub, assume secrets are compromised!

- **Firebase:** Regenerate API keys in Firebase Console
- **Gemini API:** Regenerate in Google AI Studio  
- **HuggingFace:** Regenerate token in HuggingFace settings
- **AWS:** Rotate IAM credentials

## Protected Patterns

The `.gitignore` files protect these patterns:

```
# Environment
.env
.env.*
*.env

# Firebase
google-services.json
GoogleService-Info.plist
firebase-adminsdk-*.json

# AWS
*.pem
*.key
*.crt
credentials
*.tfvars

# Terraform
.terraform/
*.tfstate
*.tfstate.*
```

## GitHub Security Features

Enable in repository settings:

- ✅ Secret scanning
- ✅ Dependabot alerts
- ✅ Branch protection rules
- ✅ Require pull request reviews

## Additional Documentation

- **Full Guide:** `SECURITY_SETUP.md`
- **AWS Setup:** `infrastructure/AWS_CREDENTIALS_SETUP.md`
- **AWS Integration:** `bhashalens_app/AWS_INTEGRATION_README.md`

## Quick Test

```bash
# This should show NO sensitive files
git status | grep -iE "\.env|google-services\.json|\.tfvars"
```

---

**Remember:** When in doubt, don't commit! Review changes carefully before pushing.
