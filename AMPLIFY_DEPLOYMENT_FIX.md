# AWS Amplify Deployment Fix

## Issues Identified

1. **Flutter SDK Download Timeout**: The build was timing out while downloading the Dart SDK during Flutter setup
2. **Inefficient Git Clone**: Using `git clone` for Flutter SDK is slow and unreliable
3. **Missing Cache Configuration**: Cache paths weren't properly configured
4. **PATH Not Persisting**: Environment variables weren't properly exported between build phases

## Fixes Applied

### 1. Updated `amplify.yml`

**Changes:**
- Replaced `git clone` with direct `wget` download of Flutter SDK tarball (much faster)
- Added proper PATH and PUB_CACHE environment variable exports
- Added `flutter doctor -v` for better debugging
- Improved cache configuration to include `.pub-cache`
- Added build output verification
- Used `--source-maps` flag for better debugging in production

### 2. Build Optimization

**Optimizations:**
- Using Flutter 3.24.0 stable (specific version for consistency)
- Using `canvaskit` renderer for better performance
- Enabling SKIA for improved rendering
- Proper caching of Flutter SDK and pub dependencies

## Next Steps

### Step 1: Configure Environment Variables in AWS Amplify Console

You need to add environment variables in the Amplify Console:

1. Go to AWS Amplify Console
2. Select your app: `bhashalens-web-main`
3. Go to **App settings** → **Environment variables**
4. Add the following variables:

```
GEMINI_API_KEY=<your-gemini-api-key>
AWS_API_GATEWAY_URL=https://e38c3iwchc.execute-api.us-east-1.amazonaws.com
AWS_REGION=us-east-1
AWS_ENABLE_CLOUD=true
FIREBASE_WEB_API_KEY=AIzaSyDphzCwAF7zkNAUcLLPbakHvytLp25r6oU
FIREBASE_WEB_APP_ID=1:705407154234:web:5ed3f38a275607fa915d03
FIREBASE_WEB_MESSAGING_SENDER_ID=705407154234
FIREBASE_WEB_PROJECT_ID=chicha123
FIREBASE_WEB_AUTH_DOMAIN=chicha123.firebaseapp.com
FIREBASE_WEB_STORAGE_BUCKET=chicha123.firebasestorage.app
FIREBASE_WEB_MEASUREMENT_ID=G-9FEPLCY5TW
```

### Step 2: Update Build Settings in Amplify Console

1. Go to **App settings** → **Build settings**
2. Verify the build specification is using the updated `amplify.yml`
3. If not, click **Edit** and paste the contents of the new `amplify.yml`

### Step 3: Increase Build Timeout (if needed)

1. Go to **App settings** → **General**
2. Under **Build timeout**, increase to **30 minutes** (default is 15)
3. This gives more time for the initial Flutter SDK download

### Step 4: Trigger a New Build

1. Go to the **main** branch in Amplify Console
2. Click **Redeploy this version** or push a new commit to trigger a build
3. Monitor the build logs for any errors

### Step 5: Verify Deployment

Once the build succeeds:

1. Access the Amplify URL: `https://main.d2inz5w2ysguf6.amplifyapp.com`
2. Test the following:
   - App loads correctly
   - Firebase authentication works
   - Translation features work
   - API Gateway connectivity works

## Alternative: Use Amplify's Flutter Support (Recommended)

AWS Amplify has built-in Flutter support. You can simplify the build by using Amplify's managed Flutter environment:

### Option A: Use Amplify's Flutter Runtime

Update `amplify.yml` to use Amplify's managed Flutter:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - 'cd bhashalens_app'
        - 'flutter pub get'
    build:
      commands:
        - 'cd bhashalens_app'
        - 'flutter build web --release'
  artifacts:
    baseDirectory: bhashalens_app/build/web
    files:
      - '**/*'
  cache:
    paths:
      - 'bhashalens_app/.dart_tool/**/*'
```

Then in Amplify Console:
1. Go to **App settings** → **Build image settings**
2. Select **Amplify Managed Image**
3. Choose **Flutter** as the framework

### Option B: Use Docker Build Image

Create a custom Docker image with Flutter pre-installed:

1. Create `Dockerfile.amplify`:

```dockerfile
FROM public.ecr.aws/docker/library/ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter doctor -v
RUN flutter config --no-analytics
RUN flutter config --enable-web
RUN flutter precache --web

WORKDIR /app
```

2. Build and push to ECR
3. Configure Amplify to use this custom image

## Troubleshooting

### Build Still Failing?

**Check these:**

1. **Disk Space**: Ensure build environment has enough space
   - Flutter SDK: ~1.5 GB
   - Dependencies: ~500 MB
   - Build output: ~50 MB

2. **Network Issues**: If download fails, try:
   - Using a different Flutter mirror
   - Increasing timeout
   - Using a cached version

3. **Memory Issues**: If build runs out of memory:
   - Reduce build concurrency
   - Use smaller build image
   - Optimize dependencies

### Common Errors

**Error: "Flutter command not found"**
- Solution: Ensure PATH is exported correctly in each phase

**Error: "pub get failed"**
- Solution: Check `pubspec.yaml` for invalid dependencies
- Run `flutter pub get` locally to verify

**Error: "Build timeout"**
- Solution: Increase build timeout in Amplify settings
- Optimize build by removing unnecessary dependencies

**Error: "Insufficient disk space"**
- Solution: Clean up build artifacts, use smaller Flutter version

## Cost Optimization

**Current Build Cost:**
- Build time: ~5-10 minutes (after optimization)
- Storage: ~2 GB (Flutter SDK + dependencies)
- Bandwidth: ~100 MB per build

**Estimated Monthly Cost:**
- Builds: 100 builds/month × $0.01/minute × 10 minutes = $10
- Storage: 2 GB × $0.023/GB = $0.05
- Bandwidth: 10 GB × $0.15/GB = $1.50
- **Total: ~$11.55/month**

**Optimization Tips:**
1. Use build caching (already configured)
2. Limit auto-builds to main branch only
3. Use manual deployments for testing
4. Consider using GitHub Actions for builds, then deploy to Amplify

## Monitoring

**Key Metrics to Watch:**
1. Build duration (target: < 10 minutes)
2. Build success rate (target: > 95%)
3. Deployment frequency
4. Cache hit rate

**Set up CloudWatch Alarms:**
1. Build failures > 2 in 1 hour
2. Build duration > 15 minutes
3. Deployment errors

## Next Steps After Successful Deployment

1. **Configure Custom Domain** (optional)
   - Purchase domain or use existing
   - Configure DNS in Route 53
   - Enable SSL/TLS via ACM

2. **Set up CI/CD Pipeline**
   - Configure branch-based deployments
   - Set up staging environment
   - Implement automated testing

3. **Performance Optimization**
   - Enable CloudFront caching
   - Optimize asset delivery
   - Implement lazy loading

4. **Security Hardening**
   - Configure WAF rules
   - Enable DDoS protection
   - Implement rate limiting

5. **Monitoring & Alerting**
   - Set up CloudWatch dashboards
   - Configure SNS notifications
   - Implement error tracking

## Support

If you continue to experience issues:

1. Check Amplify build logs for detailed error messages
2. Review Flutter doctor output for environment issues
3. Test build locally: `flutter build web --release`
4. Contact AWS Support if infrastructure issues persist

## References

- [AWS Amplify Flutter Documentation](https://docs.amplify.aws/flutter/)
- [Flutter Web Deployment Guide](https://docs.flutter.dev/deployment/web)
- [AWS Amplify Build Specification](https://docs.aws.amazon.com/amplify/latest/userguide/build-settings.html)
