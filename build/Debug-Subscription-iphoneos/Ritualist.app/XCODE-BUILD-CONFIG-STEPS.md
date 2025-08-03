# Xcode Build Configuration Setup Steps

## Overview
This document provides step-by-step instructions for setting up the build configurations and compiler flags needed for the subscription control system.

## Step 1: Create Build Configurations

1. Open `Ritualist.xcodeproj` in Xcode
2. Select the project root (Ritualist) in the navigator
3. Select the "Ritualist" project (not target) in the main editor
4. Go to the "Info" tab
5. Under "Configurations", you should see:
   - Debug
   - Release

### Add New Configurations:

6. Click the "+" button under Configurations
7. Select "Duplicate 'Debug' Configuration"
8. Name it: `Debug-AllFeatures`
9. Click the "+" button again
10. Select "Duplicate 'Debug' Configuration" 
11. Name it: `Debug-Subscription`
12. Click the "+" button again
13. Select "Duplicate 'Release' Configuration"
14. Name it: `Release-AllFeatures`
15. Click the "+" button again
16. Select "Duplicate 'Release' Configuration"
17. Name it: `Release-Subscription`

## Step 2: Add Compiler Flags

For each configuration, select the "Ritualist" target and go to "Build Settings":

### Debug-AllFeatures Configuration:
1. Search for "Swift Compiler - Custom Flags"
2. Find "Other Swift Flags"
3. Add: `-D ALL_FEATURES_ENABLED`

### Debug-Subscription Configuration:
1. Search for "Swift Compiler - Custom Flags"
2. Find "Other Swift Flags"  
3. Add: `-D SUBSCRIPTION_ENABLED`

### Release-AllFeatures Configuration:
1. Search for "Swift Compiler - Custom Flags"
2. Find "Other Swift Flags"
3. Add: `-D ALL_FEATURES_ENABLED`

### Release-Subscription Configuration:
1. Search for "Swift Compiler - Custom Flags"
2. Find "Other Swift Flags"
3. Add: `-D SUBSCRIPTION_ENABLED`

## Step 3: Create/Update Schemes

1. Go to Product → Scheme → Manage Schemes
2. Click "+" to create new schemes for each configuration:

### Create Schemes:
- **Ritualist-AllFeatures**: Use Debug-AllFeatures for Run, Release-AllFeatures for Archive
- **Ritualist-Subscription**: Use Debug-Subscription for Run, Release-Subscription for Archive

3. For each scheme:
   - Edit Scheme → Run → Build Configuration: Set to appropriate debug config
   - Edit Scheme → Archive → Build Configuration: Set to appropriate release config

## Step 4: Test Configurations

1. Select "Ritualist-AllFeatures" scheme
2. Build (⌘+B) - should compile successfully with all features enabled
3. Select "Ritualist-Subscription" scheme  
4. Build (⌘+B) - should compile successfully with subscription gating

## Expected Behavior

### All Features Enabled Configurations:
- No paywall prompts shown
- All premium features available
- Unlimited habit creation
- Advanced analytics always visible

### Subscription Configurations:
- Paywall prompts shown for premium features
- Feature gating based on subscription status
- Limited habits for free users
- Analytics gated behind subscription

## Verification

After setup, you can verify the configuration is working by checking:
```swift
print(BuildConfig.debugInfo)
```

This should output different messages based on the active configuration.