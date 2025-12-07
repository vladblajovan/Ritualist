# App Store Submission Readiness Analysis

**Project**: Ritualist
**Analysis Date**: December 6, 2025
**Version Analyzed**: 0.4.1 (Build 234)
**Target Category**: Productivity
**Target Age Rating**: 9+
**Target Markets**: Worldwide

---

## Executive Summary

| Category | Status | Risk Level |
|----------|--------|------------|
| **Technical Requirements** | Ready | Low |
| **Privacy & Legal** | NEEDS WORK | HIGH |
| **IAP/Subscription** | Pending (known) | Medium |
| **Metadata & Assets** | NEEDS WORK | Medium |
| **App Functionality** | Ready | Low |

**Overall Assessment**: App is technically sound but requires **Privacy Policy**, **Terms of Service**, and **subscription disclosure text** before submission.

---

## Critical Blockers (Must Fix Before Submission)

### 1. Missing Privacy Policy & Terms of Service Links in App

**Status**: **BLOCKER** - Will cause rejection
**Guideline**: [5.1.1 Data Collection and Storage](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage)

**Current State**:
- No Privacy Policy link in Settings
- No Terms of Service link in Settings
- No legal links in Paywall view

**Required Actions**:
1. Create Privacy Policy document (must include):
   - Data collected: Location (for geofence reminders), habits, user profile, iCloud sync
   - Data usage: Local habit tracking, location-based reminders, cross-device sync
   - Data storage: On-device + iCloud private database
   - Third-party sharing: None (no analytics, no ads)
   - Data retention/deletion: User can delete all data via Settings
   - Contact information for privacy inquiries

2. Create Terms of Service document (must include):
   - Auto-renewable subscription terms
   - Pricing and billing cycle information
   - Cancellation policy (managed through App Store)
   - Refund policy (Apple's standard policy)

3. Add "Legal" section to Settings screen:
   ```swift
   Section("Legal") {
       Link("Privacy Policy", destination: URL(string: "https://ritualist.app/privacy")!)
       Link("Terms of Service", destination: URL(string: "https://ritualist.app/terms")!)
   }
   ```

4. Add URLs to App Store Connect:
   - Privacy Policy URL (required field)
   - Support URL (required field)

**Rejection Risk**: 100% without this

---

### 2. Missing Auto-Renewable Subscription Disclosure

**Status**: **BLOCKER** - Will cause rejection
**Guideline**: [3.1.2 Subscriptions](https://developer.apple.com/app-store/review/guidelines/#subscriptions)

**Current State** (PaywallView.swift):
- Only shows: "7-day free trial, then $49.99. Cancel anytime."
- Missing required disclosure text

**Required Apple-Mandated Disclosure** (must appear near purchase button):
```
Subscriptions automatically renew unless cancelled at least 24 hours before
the end of the current period. Your account will be charged for renewal within
24 hours prior to the end of the current period. You can manage and cancel
your subscriptions by going to your account settings in the App Store after purchase.
```

**Also Required**:
- Link to Privacy Policy from paywall
- Link to Terms of Use from paywall

**Implementation Location**: Add to `purchaseSection` in PaywallView.swift

**Rejection Risk**: High - Apple specifically checks for this

---

### 3. App Store Connect Privacy Nutrition Labels

**Status**: **NEEDS PREPARATION** - Required at submission
**Guideline**: [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

**Data Your App Collects** (for nutrition label):

| Data Type | Collected | Linked to User | Used for Tracking |
|-----------|-----------|----------------|-------------------|
| Precise Location | Yes | Yes (iCloud) | No |
| Coarse Location | Yes | Yes (iCloud) | No |
| Name | Yes | Yes (iCloud) | No |
| Photos (Avatar) | Yes | Yes (iCloud) | No |
| User Content (Habits) | Yes | Yes (iCloud) | No |
| Identifiers (iCloud ID) | Yes | Yes | No |

**What to declare in App Store Connect**:
- Location: "App Functionality" (for geofence reminders)
- Contact Info (Name): "App Functionality"
- User Content: "App Functionality"
- Photos: "App Functionality" (avatar only)

**NOT collected**:
- No analytics
- No crash reporting (unless you add it)
- No advertising identifiers
- No device identifiers sent to servers

---

## High Priority Issues

### 4. Missing PrivacyInfo.xcprivacy Manifest

**Status**: **RECOMMENDED** - May cause issues
**Guideline**: [Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

Apple now requires privacy manifests for apps that access certain APIs.

**APIs your app uses that may require declaration**:
- `UserDefaults` - Used for app settings
- Location APIs - Used for geofencing

**Action**: Create `PrivacyInfo.xcprivacy` file declaring:
- NSPrivacyAccessedAPITypes for UserDefaults (if required)
- Location usage purposes

---

### 5. Subscription Terms Not Fully Displayed

**Status**: **HIGH** - Common rejection reason

**Missing from PaywallView**:
- [ ] Price per billing period clearly shown for all plans
- [ ] Subscription length clearly stated (Weekly/Monthly/Annual)
- [ ] Auto-renewal disclosure text
- [ ] Links to Terms & Privacy Policy

**Current PaywallView shows**:
- Product prices ✓
- Duration badges ✓
- Trial info for annual ✓
- ❌ Full subscription terms disclosure
- ❌ Legal links

---

## Medium Priority Issues

### 6. Screenshot Requirements (App Store Connect)

**Status**: **TODO** - Required at submission
**Guideline**: [Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)

**Mandatory Screenshots** (as of September 2024):
- **iPhone 6.9"** (iPhone 16 Pro Max): 1320 × 2868 or 1290 × 2796 pixels - **REQUIRED**
- **iPad 13"** (if supporting iPad): 2064 × 2752 pixels

**Content Requirements**:
- Must show actual app interface
- No device frames/hands holding devices
- No placeholder content
- Screenshots should demonstrate key features

**Recommended Screens to Capture**:
1. Dashboard with habits
2. Habit detail/completion
3. Statistics/insights
4. Settings/customization
5. Paywall (showing premium features)

---

### 7. App Description & Keywords

**Status**: **TODO** - Required at submission

**App Description Requirements**:
- 170-4000 characters
- Clearly describe app functionality
- Mention subscription features
- Avoid keyword stuffing

**Keywords** (100 character limit):
Suggested: `habit,tracker,routine,goals,productivity,reminder,location,geofence,daily,wellness`

---

### 8. Support URL Requirement

**Status**: **TODO** - Required at submission

You need a support URL where users can get help. Options:
- https://ritualist.app/support
- Email link (mailto:support@ritualist.app)
- GitHub issues page

---

## Low Priority / Nice to Have

### 9. Accessibility Testing

**Status**: **RECOMMENDED**

Before submission, test:
- [ ] VoiceOver navigation
- [ ] Dynamic Type (larger text sizes)
- [ ] Reduce Motion compatibility
- [ ] Color contrast ratios

Apple's new Accessibility Nutrition Labels (iOS 26+) let you declare accessibility features.

---

### 10. Localization

**Status**: **OPTIONAL**

Currently English only. For better App Store visibility in international markets, consider:
- Spanish (large market)
- French, German (European markets)
- Japanese (high engagement market)

Can be added post-launch.

---

## Technical Verification

### Build Requirements ✓

| Requirement | Status | Details |
|-------------|--------|---------|
| Xcode Version | ✓ | Xcode 26.1.1 (exceeds requirement) |
| iOS SDK | ✓ | iOS 18+ SDK |
| Deployment Target | ✓ | iOS 18.0 |
| Architecture | ✓ | arm64 |

**Note**: Apps must be built with Xcode 16+ and iOS 18 SDK as of April 2025.

---

### Entitlements ✓

| Entitlement | Status | Notes |
|-------------|--------|-------|
| Push Notifications | ✓ | `aps-environment: development` (will be auto-converted for production) |
| iCloud (CloudKit) | ✓ | `iCloud.com.vladblajovan.Ritualist` |
| iCloud Key-Value Store | ✓ | For onboarding state sync |
| App Groups | ✓ | `group.com.vladblajovan.Ritualist` (widget sharing) |

---

### Background Modes ✓

| Mode | Status | Justification |
|------|--------|---------------|
| `location` | ✓ | Geofence monitoring for location-based habit reminders |
| `remote-notification` | ✓ | Silent push for iCloud sync updates |

---

### Location Permission Strings ✓

| Key | Value |
|-----|-------|
| `NSLocationWhenInUseUsageDescription` | "Ritualist needs your location to send reminders when you arrive at specific places." |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | "Ritualist monitors your location in the background to send habit reminders when you enter or leave specific areas." |

These are clear, specific, and explain the benefit to the user. ✓

---

### IAP Configuration ✓

| Product ID | Type | Status |
|------------|------|--------|
| `com.vladblajovan.ritualist.weekly` | Auto-renewable | Pending approval (known) |
| `com.vladblajovan.ritualist.monthly` | Auto-renewable | Pending approval (known) |
| `com.vladblajovan.ritualist.annual` | Auto-renewable | Pending approval (known) |
| `com.vladblajovan.ritualist.lifetime` | Non-consumable | Pending approval (known) |

**Subscription Group**: `ritualist_pro`

**Note**: You mentioned IAP products are pending due to address/banking setup. This is a known blocker.

---

### App Icon ✓

| Requirement | Status |
|-------------|--------|
| Size 1024x1024 | ✓ |
| PNG format | ✓ |
| No transparency | ✓ (verified) |
| No rounded corners | ✓ (iOS applies them) |
| Dark mode variant | ✓ |
| Tinted variant | ✓ |

---

## Age Rating Questionnaire Answers

For **9+ rating**, answer these questions:

| Question | Answer | Notes |
|----------|--------|-------|
| Cartoon/Fantasy Violence | None | |
| Realistic Violence | None | |
| Sexual Content | None | |
| Profanity/Crude Humor | None | |
| Mature/Suggestive Themes | None | |
| Horror/Fear Themes | None | |
| Medical/Treatment Info | None | (habits are general, not medical) |
| Alcohol/Tobacco/Drug Use | None | |
| Gambling | None | |
| User-Generated Content | Yes (mild) | User creates habit names |
| Unrestricted Web Access | No | |

**Expected Rating**: 9+ (due to user-generated content)

---

## Pre-Submission Checklist

### Critical (Must Complete)

- [ ] **Create Privacy Policy** and host at ritualist.app/privacy
- [ ] **Create Terms of Service** and host at ritualist.app/terms
- [ ] **Add Legal section** to Settings with Privacy/Terms links
- [ ] **Add subscription disclosure text** to PaywallView
- [ ] **Add Privacy/Terms links** to PaywallView
- [ ] **Complete App Store Connect privacy labels**
- [ ] **Wait for IAP products approval** (in progress)

### High Priority

- [ ] Create Privacy Manifest file (PrivacyInfo.xcprivacy)
- [ ] Prepare 6.9" iPhone screenshots (minimum 3-5)
- [ ] Write App Store description
- [ ] Set up Support URL
- [ ] Fill out age rating questionnaire

### Before Final Submit

- [ ] TestFlight beta test with 5-10 users
- [ ] Test all IAP flows with sandbox accounts
- [ ] Test location permissions flow
- [ ] Test restore purchases
- [ ] Verify iCloud sync works
- [ ] Version bump to 1.0.0

---

## Estimated Timeline

| Task | Time | Priority |
|------|------|----------|
| Privacy Policy + Terms | 1-2 hours | Critical |
| Add legal links to app | 30 min | Critical |
| Subscription disclosure | 30 min | Critical |
| Privacy labels in ASC | 30 min | Critical |
| Screenshots | 2-3 hours | High |
| App description | 1 hour | High |
| Privacy manifest | 30 min | Medium |
| TestFlight testing | 1-2 weeks | High |

**Total estimated time**: 1-2 days of work + 1-2 weeks TestFlight

---

## References

- [App Store Review Guidelines (November 2025)](https://developer.apple.com/app-store/review/guidelines/)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)
- [In-App Purchase Guidelines](https://developer.apple.com/design/human-interface-guidelines/in-app-purchase)
- [Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)

---

**Report Generated**: December 6, 2025
**Next Review**: After legal documents are added
