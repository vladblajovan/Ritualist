# Detailed Xcode Build Configuration Setup

## Current Status
- ✅ Code infrastructure is ready (`BuildConfigurationService.swift`, etc.)
- ✅ Service layer is wired for build configurations
- ❌ Xcode project configurations need to be created manually

## Step-by-Step Xcode Setup

### Step 1: Open Project
1. Open `Ritualist.xcodeproj` in Xcode
2. In the Navigator, click on "Ritualist" (the blue project icon at the top)
3. Make sure you select the **PROJECT** "Ritualist" (not the target)

### Step 2: Duplicate Configurations
In the main editor, click the "Info" tab:

1. Under "Configurations" you'll see:
   ```
   Debug
   Release
   ```

2. **Create Debug-AllFeatures:**
   - Click the "+" button below the configurations list
   - Choose "Duplicate 'Debug' Configuration"
   - Name it: `Debug-AllFeatures`

3. **Create Debug-Subscription:**
   - Click "+" again
   - Choose "Duplicate 'Debug' Configuration"  
   - Name it: `Debug-Subscription`

4. **Create Release-AllFeatures:**
   - Click "+" again
   - Choose "Duplicate 'Release' Configuration"
   - Name it: `Release-AllFeatures`

5. **Create Release-Subscription:**
   - Click "+" again
   - Choose "Duplicate 'Release' Configuration"
   - Name it: `Release-Subscription`

### Step 3: Add Compiler Flags
Now select the **TARGET** "Ritualist" and go to "Build Settings":

1. **Search for "Other Swift Flags"** in the filter box
2. You'll see a setting called "Other Swift Flags"

For each configuration:

#### Debug-AllFeatures & Release-AllFeatures:
- Click on the row for your configuration
- Double-click the empty field
- Add: `-D ALL_FEATURES_ENABLED`

#### Debug-Subscription & Release-Subscription:
- Click on the row for your configuration  
- Double-click the empty field
- Add: `-D SUBSCRIPTION_ENABLED`

### Step 4: Create Schemes (Optional but Recommended)
1. Go to **Product → Scheme → Manage Schemes**
2. Click "+" to create new schemes

Create these schemes:
- **Ritualist-AllFeatures**: 
  - Run: Debug-AllFeatures
  - Archive: Release-AllFeatures
- **Ritualist-Subscription**:
  - Run: Debug-Subscription  
  - Archive: Release-Subscription

### Step 5: Test Setup
1. Select "Ritualist-AllFeatures" scheme
2. Build (⌘+B) - should succeed
3. Select "Ritualist-Subscription" scheme
4. Build (⌘+B) - should succeed

## Verification Commands
After setup, run from terminal:
```bash
cd /Users/vladblajovan/Developer/GitHub/Ritualist
./verify-build-configs.sh
```

## Expected Behavior After Setup

### All Features Configuration:
- No paywall prompts shown anywhere
- `vm.hasAdvancedAnalytics` returns `true`
- `vm.canCreateMoreHabits` returns `true`  
- All premium features available

### Subscription Configuration:
- Paywall prompts shown for premium features
- Feature gating based on user subscription status
- Limited habits for free users

## Troubleshooting

**If builds fail:**
1. Clean build folder: Product → Clean Build Folder
2. Check compiler flags are exactly: `-D ALL_FEATURES_ENABLED` or `-D SUBSCRIPTION_ENABLED`
3. Ensure flags are set on the TARGET (not project)

**If behavior doesn't change:**
1. Verify you're using the correct scheme
2. Check the scheme's Run configuration matches your build config
3. Add `print(BuildConfig.debugInfo)` to verify flag detection