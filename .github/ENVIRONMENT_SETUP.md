# GitHub Environments Setup Guide

This guide explains how to set up TestFlight and App Store environments for deployment secrets and configuration.

## Creating Environments

### 1. TestFlight Environment

**Purpose:** Beta testing deployments via TestFlight

**Setup Steps:**
1. Go to **Settings → Environments**
2. Click **New environment**
3. Name: `TestFlight`
4. Click **Configure environment**

**Recommended Settings:**
- **Deployment branches:** Selected branches only → `main`, `develop`
- **Environment secrets:** Add the following secrets:
  - `APP_STORE_CONNECT_API_KEY_ID` - App Store Connect API Key ID
  - `APP_STORE_CONNECT_ISSUER_ID` - App Store Connect Issuer ID
  - `APP_STORE_CONNECT_API_PRIVATE_KEY` - Private key content (base64)
  - `MATCH_PASSWORD` - Fastlane Match password (if using)
  - `CERTIFICATES_GIT_URL` - Certificates repository URL (if using Match)

### 2. App Store Environment

**Purpose:** Production deployments to App Store

**Setup Steps:**
1. Go to **Settings → Environments**
2. Click **New environment**
3. Name: `AppStore`
4. Click **Configure environment**

**Recommended Settings:**
- **Deployment branches:** Selected branches only → `main`
- **Required reviewers:** (Optional) Add yourself for manual approval before production deploy
- **Wait timer:** (Optional) 5 minutes - gives time to cancel accidental deploys
- **Environment secrets:** Same as TestFlight (or separate keys for production)

## Environment Variables

Both environments can use these environment variables:

### Build Configuration
- `BUILD_CONFIGURATION` - Debug-AllFeatures, Release-AllFeatures, Debug-Subscription, Release-Subscription
- `SCHEME` - Ritualist-AllFeatures or Ritualist-Subscription

### App Store Connect
- `APP_BUNDLE_ID` - com.example.Ritualist
- `TEAM_ID` - Your Apple Developer Team ID
- `APP_STORE_CONNECT_API_KEY_ID` - API Key ID from App Store Connect
- `APP_STORE_CONNECT_ISSUER_ID` - Issuer ID from App Store Connect
- `APP_STORE_CONNECT_API_PRIVATE_KEY` - Base64-encoded private key

### Code Signing (if using Fastlane Match)
- `MATCH_PASSWORD` - Password for Match encryption
- `CERTIFICATES_GIT_URL` - Git URL for certificates storage
- `MATCH_TYPE` - appstore, adhoc, or development

## Using Environments in Workflows

Example workflow using environments:

```yaml
jobs:
  deploy-testflight:
    name: Deploy to TestFlight
    runs-on: macos-latest
    environment: TestFlight  # Uses TestFlight environment secrets

    steps:
    - uses: actions/checkout@v4

    - name: Build and Deploy
      env:
        API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
      run: |
        # Build and upload to TestFlight
        fastlane beta
```

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Use separate API keys** for TestFlight vs App Store (if possible)
3. **Enable required reviewers** for App Store environment
4. **Rotate secrets regularly** (every 3-6 months)
5. **Use GitHub's secret scanning** to detect leaked secrets

## Deployment Workflow Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    tags:
      - 'v*'  # Trigger on version tags (v1.0.0, v1.1.0, etc.)

jobs:
  deploy-testflight:
    name: Deploy to TestFlight
    runs-on: macos-latest
    environment: TestFlight

    steps:
    - uses: actions/checkout@v4

    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: latest-stable

    - name: Build and Upload to TestFlight
      env:
        API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
        ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
        API_PRIVATE_KEY: ${{ secrets.APP_STORE_CONNECT_API_PRIVATE_KEY }}
      run: |
        # Your build and upload commands here
        # Example with Fastlane: fastlane beta
        echo "Building and uploading to TestFlight..."
```

## Next Steps

1. Create both environments in GitHub Settings
2. Add necessary secrets to each environment
3. Create deployment workflows that use these environments
4. Test with a non-production deploy first

## References

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [App Store Connect API Keys](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)
- [Fastlane Match](https://docs.fastlane.tools/actions/match/)
