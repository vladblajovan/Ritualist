# Build Configuration Guide

Quick reference for when to use which build scheme and configuration in the Ritualist project.

---

## 🎯 Quick Decision Tree

```
What are you doing?
│
├─ Local development / feature work
│  └─ Use: Ritualist-AllFeatures (Debug-AllFeatures)
│
├─ Testing the paywall flow
│  └─ Use: Ritualist-Subscription (Debug-Subscription)
│
├─ TestFlight beta release
│  └─ Use: Ritualist-AllFeatures (Release-AllFeatures)
│
└─ App Store production release
   └─ Use: Ritualist-Subscription (Release-Subscription)
```

---

## 📱 Available Schemes

### 1. Ritualist-AllFeatures

**Purpose:** Development, TestFlight, and internal testing

**Behavior:**
- ✅ All premium features unlocked
- ✅ No paywall shown
- ✅ Unlimited habits
- ✅ All analytics and insights available
- ✅ Mock paywall service (instant "purchases")

**When to use:**
- Daily development work
- TestFlight releases for beta testers
- Taking App Store screenshots
- QA testing premium features
- Demo/presentation builds

**Configurations:**
- `Debug-AllFeatures` - Local development
- `Release-AllFeatures` - TestFlight uploads

**Compiler Flag:** `ALL_FEATURES_ENABLED`

---

### 2. Ritualist-Subscription

**Purpose:** Production releases and paywall testing

**Behavior:**
- ⚠️ Freemium model active
- ⚠️ 5 habit limit for free tier
- ⚠️ Paywall shown at limits
- ⚠️ Premium features require subscription
- ✅ Real StoreKit integration (when enabled)

**When to use:**
- App Store production releases
- Testing subscription purchase flow
- Testing free tier limitations
- Validating paywall UI/UX
- Pre-production testing

**Configurations:**
- `Debug-Subscription` - Local paywall testing
- `Release-Subscription` - App Store submissions

**Compiler Flag:** `SUBSCRIPTION_ENABLED`

---

## 🔧 How to Switch Schemes

### In Xcode

1. Click the scheme dropdown (next to the Run/Stop buttons)
2. Select the desired scheme:
   - `Ritualist-AllFeatures` or
   - `Ritualist-Subscription`
3. Build and run (⌘+R)

### From Command Line

```bash
# Build AllFeatures configuration
xcodebuild -project Ritualist.xcodeproj \
  -scheme Ritualist-AllFeatures \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug-AllFeatures \
  build

# Build Subscription configuration
xcodebuild -project Ritualist.xcodeproj \
  -scheme Ritualist-Subscription \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug-Subscription \
  build
```

---

## 📦 Distribution Checklist

### TestFlight Release

- [ ] Select `Ritualist-AllFeatures` scheme
- [ ] Choose `Release-AllFeatures` configuration
- [ ] Product → Archive
- [ ] Upload to App Store Connect
- [ ] Submit for TestFlight review
- [ ] **Result:** Beta testers get all features unlocked

### App Store Release

- [ ] Select `Ritualist-Subscription` scheme
- [ ] Choose `Release-Subscription` configuration
- [ ] Product → Archive
- [ ] Upload to App Store Connect
- [ ] Submit for App Store review
- [ ] **Result:** Production users see freemium model with paywall

---

## 🧪 Testing Scenarios

### Scenario 1: Testing New Premium Feature

**Goal:** Develop and test a new premium analytics feature

**Steps:**
1. Use `Ritualist-AllFeatures` (Debug-AllFeatures)
2. Develop feature assuming premium access
3. Test with unlimited data
4. Switch to `Ritualist-Subscription` (Debug-Subscription)
5. Verify paywall blocks non-premium users
6. Test "Upgrade to Pro" flow

### Scenario 2: Testing Paywall Purchase Flow

**Goal:** Validate subscription purchase experience

**Steps:**
1. Use `Ritualist-Subscription` (Debug-Subscription)
2. Start as free user (5 habits max)
3. Try to create 6th habit
4. Verify paywall appears
5. Test purchase flow with .storekit file
6. Verify premium access granted after "purchase"

### Scenario 3: Preparing App Store Screenshots

**Goal:** Capture screenshots showing all features

**Steps:**
1. Use `Ritualist-AllFeatures` (Release-AllFeatures)
2. Populate with test data
3. All features visible and accessible
4. Take screenshots for App Store listing

---

## 🏗️ Build Configuration Details

### What Changes Between Configurations?

| Aspect | AllFeatures | Subscription |
|--------|-------------|--------------|
| **Habit Limit** | Unlimited | 5 for free tier |
| **Paywall** | Never shown | Shown at limits |
| **Advanced Analytics** | Always available | Premium only |
| **Personality Insights** | Always available | Premium only |
| **Custom Reminders** | Always available | Premium only |
| **Data Export** | Always available | Premium only |
| **PaywallService** | MockPaywallService | StoreKitPaywallService* |
| **FeatureGatingService** | Always returns true | Checks subscription |

*When StoreKit integration is enabled (currently commented out)

### Under the Hood

**AllFeatures Mode:**
```swift
// BuildConfigurationService returns
allFeaturesEnabled = true
subscriptionEnabled = false

// FeatureGatingService
canCreateMoreHabits(_) → true (always)
hasAdvancedAnalytics → true (always)
hasCustomReminders → true (always)

// PaywallService
MockPaywallService (simulates instant purchases)
```

**Subscription Mode:**
```swift
// BuildConfigurationService returns
allFeaturesEnabled = false
subscriptionEnabled = true

// FeatureGatingService
canCreateMoreHabits(5) → false (free tier limit)
hasAdvancedAnalytics → userProfile.isPremiumUser
hasCustomReminders → userProfile.isPremiumUser

// PaywallService
StoreKitPaywallService (real StoreKit integration)
// Currently: MockPaywallService until StoreKit enabled
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ Wrong: Using AllFeatures for App Store Submission

```
Problem: Users get all features free without subscribing
Impact: No revenue, breaks business model
Fix: Always use Ritualist-Subscription for App Store
```

### ❌ Wrong: Using Subscription for TestFlight

```
Problem: Beta testers hit paywall, can't test premium features
Impact: Poor beta feedback, incomplete testing
Fix: Use Ritualist-AllFeatures for TestFlight
```

### ❌ Wrong: Manual Code Changes Between Builds

```
Problem: Forgetting to revert changes before release
Impact: Wrong behavior shipped to production
Fix: Use schemes - never modify code for builds
```

### ❌ Wrong: Testing Only in AllFeatures Mode

```
Problem: Paywall flow never tested
Impact: Broken purchase experience in production
Fix: Always test both configurations before release
```

---

## 🔍 Verification Checklist

Before each release, verify the correct configuration:

### Pre-TestFlight Checklist

- [ ] Scheme: `Ritualist-AllFeatures`
- [ ] Configuration: `Release-AllFeatures`
- [ ] Run app - all features accessible without paywall
- [ ] Archive shows "AllFeatures" in scheme name
- [ ] Version number matches VERSION file
- [ ] Build number auto-increments from git count

### Pre-App Store Checklist

- [ ] Scheme: `Ritualist-Subscription`
- [ ] Configuration: `Release-Subscription`
- [ ] Run app - free tier limited to 5 habits
- [ ] Paywall appears when creating 6th habit
- [ ] Archive shows "Subscription" in scheme name
- [ ] Version number matches VERSION file
- [ ] Build number higher than previous release
- [ ] StoreKit integration enabled (when ready)

---

## 📝 Quick Reference Card

Print this and keep near your desk:

```
┌──────────────────────────────────────────────────┐
│         RITUALIST BUILD CONFIGURATIONS            │
├──────────────────────────────────────────────────┤
│                                                   │
│  DEVELOPMENT                                      │
│  → Ritualist-AllFeatures (Debug-AllFeatures)     │
│  → All features unlocked, no paywall             │
│                                                   │
│  TESTFLIGHT                                       │
│  → Ritualist-AllFeatures (Release-AllFeatures)   │
│  → Beta testers get full access                  │
│                                                   │
│  APP STORE                                        │
│  → Ritualist-Subscription (Release-Subscription) │
│  → Freemium model, paywall active                │
│                                                   │
│  PAYWALL TESTING                                  │
│  → Ritualist-Subscription (Debug-Subscription)   │
│  → Test purchase flow locally                    │
│                                                   │
└──────────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### First Time Setup

1. **Open project in Xcode:**
   ```bash
   open Ritualist.xcodeproj
   ```

2. **Select a scheme:**
   - For development: Choose `Ritualist-AllFeatures`
   - For paywall testing: Choose `Ritualist-Subscription`

3. **Select a simulator:**
   - Recommended: iPhone 17 (iOS 26)

4. **Build and run:**
   - Press ⌘+R or click Run button

### Daily Development Workflow

**Morning:**
```
1. git pull origin main
2. Select Ritualist-AllFeatures scheme
3. Build and run (⌘+R)
4. Start coding
```

**Before PR:**
```
1. Test with Ritualist-AllFeatures
2. Switch to Ritualist-Subscription
3. Verify paywall still works
4. Commit and push
```

**Release Day:**
```
TestFlight:
1. Ritualist-AllFeatures
2. Release-AllFeatures configuration
3. Archive (⌘+B then Product > Archive)
4. Upload to App Store Connect

App Store (later):
1. Ritualist-Subscription
2. Release-Subscription configuration
3. Archive
4. Upload to App Store Connect
```

---

## 🆘 Troubleshooting

### "I can't create more than 5 habits in development"

**Problem:** Using Subscription scheme in development

**Solution:**
1. Switch to `Ritualist-AllFeatures` scheme
2. Clean build folder (⌘+Shift+K)
3. Build and run (⌘+R)

### "TestFlight users complaining about paywall"

**Problem:** Uploaded Subscription build to TestFlight

**Solution:**
1. Select `Ritualist-AllFeatures` scheme
2. Archive with Release-AllFeatures configuration
3. Upload new build to TestFlight

### "Paywall not showing in production"

**Problem:** Uploaded AllFeatures build to App Store

**Solution:**
1. Immediately submit Subscription build
2. Update version number before submitting
3. Always use Ritualist-Subscription for App Store

### "Build won't compile after switching schemes"

**Problem:** Build artifacts from previous scheme

**Solution:**
1. Product → Clean Build Folder (⌘+Shift+K)
2. Close Xcode
3. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/Ritualist-*`
4. Reopen project
5. Build again

---

## 📚 Related Documentation

- **BUILD-CONFIGURATION-STRATEGY.md** - In-depth analysis and industry comparisons
- **STOREKIT-IMPLEMENTATION-PLAN.md** - StoreKit integration roadmap
- **STOREKIT-SETUP-GUIDE.md** - Activation instructions (when ready)
- **VERSIONING.md** - Version and build number management

---

## 💡 Pro Tips

1. **Use Xcode Behaviors** to auto-switch scheme based on task
   - Xcode → Behaviors → Edit Behaviors
   - Set scheme when starting to code vs. testing

2. **Create Scheme Shortcuts**
   - ⌘+Control+1: Switch to AllFeatures
   - ⌘+Control+2: Switch to Subscription
   - Xcode → Preferences → Key Bindings

3. **Set Default Scheme** per workspace
   - Your most common scheme: AllFeatures
   - Xcode remembers last used scheme

4. **Use Build Scheme Notes** in Xcode
   - Remind yourself which scheme is for what
   - Visible in scheme dropdown

5. **CI/CD Integration**
   - Test both schemes in CI pipeline
   - Ensures both configurations always build
   - Catch config-specific issues early

---

## 🎓 Training New Team Members

When onboarding someone new:

1. Show them this guide
2. Have them build both schemes
3. Demonstrate the behavioral differences
4. Walk through a TestFlight vs App Store release
5. Review the verification checklists together

**Key concepts to emphasize:**
- Schemes = purpose (TestFlight vs App Store)
- Never manually change code for builds
- Always test both configurations
- AllFeatures for beta, Subscription for production

---

## ✅ Summary

**Two schemes, two purposes:**

| Scheme | Purpose | Features | Distribution |
|--------|---------|----------|--------------|
| **AllFeatures** | Development & Beta | All unlocked | TestFlight |
| **Subscription** | Production | Freemium model | App Store |

**Golden rule:**
> If users are paying (or should pay), use Subscription.
> If users are testing (and shouldn't pay), use AllFeatures.

**Always remember:**
- Switch schemes, don't modify code
- Test both before release
- AllFeatures for TestFlight
- Subscription for App Store

---

*Last updated: 2025-01-09*
*For questions or issues, see BUILD-CONFIGURATION-STRATEGY.md for detailed analysis*
