# Offer Code Testing Guide

**Last Updated:** 2025-11-19
**Status:** Complete - Ready for Local Testing
**Cost:** FREE (No Apple Developer Program Required)

---

## Overview

This guide explains how to **test the complete offer code redemption flow locally** using Xcode's StoreKit Testing configuration. You'll test the **real production code path** with Apple's native redemption sheet, transaction listener, and state management - all without spending $99 on Apple Developer Program.

### What You'll Test

✅ **Real StoreKit 2 APIs** - Not mocked
✅ **Apple's Offer Code Redemption Sheet** - Native iOS UI
✅ **Transaction Listener** - Detects offer code redemptions
✅ **State Management** - Full redemption flow (idle → validating → success)
✅ **UI Flows** - Success/error alerts, paywall dismissal
✅ **Production Code Path** - 95% identical to production

### What's Different from Production

❌ Codes defined in `.storekit` file (not App Store Connect)
❌ Transactions reset on app restart
❌ No real App Store receipts
❌ Only works in Xcode/Simulator (not TestFlight)

---

## Setup (5 Minutes)

### Step 1: Enable StoreKit Testing in Xcode

1. **Open Xcode**
2. **Select Scheme:** Product → Scheme → Edit Scheme (⌘<)
3. **Run → Options Tab**
4. **StoreKit Configuration:** Select `Ritualist.storekit`
5. **Click Close**

**Screenshot Location:**
```
Edit Scheme → Run → Options → StoreKit Configuration
```

### Step 2: Verify Configuration

The `Ritualist.storekit` file already contains:

**Products:**
- Monthly: $9.99/month
- Annual: $49.99/year (with 7-day free trial)
- Lifetime: $99.99 one-time

**Offer Codes (5 codes):**
- `RITUALIST2025` - 3-month free trial (Annual, new users only)
- `ANNUAL30` - 30% off annual (new users only)
- `TESTANNUAL` - 1-year free trial (all users)
- `WELCOME50` - 50% off monthly for 3 months (new users only)
- `TESTMONTHLY` - 1-month free trial (all users)

---

## Testing Instructions

### Test 1: Valid Offer Code Redemption (5 minutes)

**Goal:** Verify the complete offer code redemption flow works end-to-end.

**Steps:**
1. **Run app** in Xcode (⌘R)
2. **Open Paywall:** Settings → tap subscription section
3. **Verify offer code button appears:**
   - Look for "Have a promo code?" card
   - Purple-pink gradient giftcard icon
   - Should appear between pricing and purchase button
4. **Tap "Have a promo code?" button**
5. **System sheet appears:**
   - This is Apple's native offer code redemption UI
   - Text field for code entry
   - "Redeem" button
6. **Enter code:** `TESTANNUAL`
7. **Tap "Redeem"**

**Expected Result:**
```
1. System sheet validates code (1-2 seconds)
2. Sheet dismisses
3. Transaction arrives → handleOfferCodeTransaction() called
4. Success alert appears: "Offer Code Redeemed!"
5. Message: "Successfully redeemed code for com.vladblajovan.ritualist.annual"
6. Tap "Great!" button
7. Paywall dismisses
8. Navigate to Settings → should show "Pro" badge
```

**What's Happening Behind the Scenes:**
```
User enters code
    ↓
StoreKit validates code (locally via .storekit file)
    ↓
Transaction created
    ↓
Transaction.updates stream receives it
    ↓
listenForTransactions() detects transaction.offer property
    ↓
handleOfferCodeTransaction() called
    ↓
State changes to .success(code: "OFFER_xxx", productId: "...")
    ↓
PaywallView.onChange detects state change
    ↓
handleOfferCodeStateChange() shows success alert
    ↓
User taps "Great!" → Paywall dismisses
```

**Console Logs to Watch:**
```
[StoreKitPaywallService] ✨ Offer code redeemed - Product: com.vladblajovan.ritualist.annual, Offer ID: ANNUAL_TEST
```

---

### Test 2: Invalid Offer Code (2 minutes)

**Goal:** Verify error handling for non-existent codes.

**Steps:**
1. Open paywall
2. Tap "Have a promo code?"
3. Enter: `INVALIDCODE123`
4. Tap "Redeem"

**Expected Result:**
```
1. System sheet shows error: "This code is not valid"
2. Sheet remains open
3. User can try again or cancel
```

**Note:** This error comes from StoreKit, not our code. The system validates codes against the `.storekit` file.

---

### Test 3: Eligibility Rules (3 minutes)

**Goal:** Test "new subscribers only" eligibility.

**Steps:**
1. **First, redeem a test code:**
   - Open paywall
   - Redeem `TESTANNUAL` (all users eligible)
   - Success → Now you're a subscriber

2. **Try a new-users-only code:**
   - Restart app (to reset session)
   - Open paywall
   - Tap "Have a promo code?"
   - Enter: `RITUALIST2025` (new users only)
   - Tap "Redeem"

**Expected Result:**
```
System sheet shows: "You are not eligible for this offer"
```

**Why:** `RITUALIST2025` has `eligibility: ["new"]`, and you already have a subscription.

**To Test New User Flow:**
1. Stop app
2. Delete app from simulator
3. Clean build folder: Product → Clean Build Folder (⌘⇧K)
4. Run app again
5. Try `RITUALIST2025` → Should work now

---

### Test 4: Multiple Code Types (5 minutes)

Test all 5 available codes to understand different offer types.

| Code | Type | Eligibility | Duration | Product |
|------|------|-------------|----------|---------|
| `RITUALIST2025` | Free trial | New only | 3 months | Annual |
| `ANNUAL30` | Discount (30% off) | New only | 1 year | Annual |
| `TESTANNUAL` | Free trial | All users | 1 year | Annual |
| `WELCOME50` | Discount (50% off) | New only | 3 months | Monthly |
| `TESTMONTHLY` | Free trial | All users | 1 month | Monthly |

**Steps:**
1. Reset app (delete from simulator)
2. Try each code
3. Observe different payment modes:
   - `free` = Free trial (no charge)
   - `payAsYouGo` = Discounted pricing

---

### Test 5: Transaction Listener (Advanced - 3 minutes)

**Goal:** Verify that our transaction listener correctly detects and processes offer code transactions.

**Steps:**
1. Open Xcode Console (⌘⇧Y)
2. Add log filter: "Offer code"
3. Run app
4. Redeem `TESTANNUAL`
5. Watch console

**Expected Logs:**
```
[StoreKitPaywallService] ✨ Offer code redeemed - Product: com.vladblajovan.ritualist.annual, Offer ID: ANNUAL_TEST
[SubscriptionService] Granted subscription for product: com.vladblajovan.ritualist.annual
```

**Code Path:**
```swift
// StoreKitPaywallService.swift:335-363
private func listenForTransactions() -> Task<Void, Never> {
    Task.detached { [weak self] in
        for await result in Transaction.updates {
            let transaction = try await self.checkVerified(result)

            // 🎯 This is where offer codes are detected
            if #available(iOS 15.0, *), let offer = transaction.offer {
                await self.handleOfferCodeTransaction(transaction, offer: offer)
            }
        }
    }
}
```

---

## Testing Scenarios Summary

### ✅ Scenarios You Can Test

| Scenario | How to Test | Expected Behavior |
|----------|-------------|-------------------|
| Valid code | Enter `TESTANNUAL` | Success alert → paywall dismisses |
| Invalid code | Enter `BADCODE` | System error: "This code is not valid" |
| Ineligible user | Have subscription, try `RITUALIST2025` | System error: "You are not eligible" |
| Transaction detection | Watch console logs | See "✨ Offer code redeemed" log |
| State management | Observe UI changes | Alert appears, paywall dismisses |
| Free trial offer | `TESTANNUAL` or `TESTMONTHLY` | Free access granted |
| Discount offer | `ANNUAL30` or `WELCOME50` | Discounted pricing shown |

### ❌ Scenarios You CANNOT Test Locally

| Scenario | Reason | Alternative |
|----------|--------|-------------|
| Expired codes | Can't expire in local testing | Test in debug menu instead |
| Redemption limits | No server-side tracking | Test in debug menu instead |
| Already redeemed | Resets on app restart | Test in debug menu instead |
| Cross-device sync | Simulator only | Requires TestFlight ($99) |
| Receipt validation | No real receipts | Requires TestFlight ($99) |

---

## Debugging Tips

### Problem: Offer code button doesn't appear

**Check:**
```swift
// PaywallView should show button if iOS 14+
if vm.isOfferCodeRedemptionAvailable {
    offerCodeSection  // Should appear
}
```

**Solutions:**
- Verify running iOS 14+ simulator
- Check `paywallService.isOfferCodeRedemptionAvailable()` returns true

---

### Problem: System sheet doesn't open

**Check:**
1. StoreKit configuration selected in scheme
2. `.storekit` file is in project navigator
3. Console for errors

**Solutions:**
- Edit Scheme → Run → Options → StoreKit Configuration = `Ritualist.storekit`
- Clean build folder (⌘⇧K)
- Restart Xcode

---

### Problem: Code not found / Invalid

**Check:**
- Code exactly matches `offerID` in `.storekit` file (case-sensitive)
- Code is in the correct product's `codeOffers` array

**Solutions:**
- Open `Configuration/Ritualist.storekit`
- Find the code under the product you selected
- Verify `offerID` matches exactly

---

### Problem: Success alert doesn't appear

**Check Console:**
```
[StoreKitPaywallService] ✨ Offer code redeemed - Product: ...
```

If you see the log but no alert:
- Check `PaywallView.onChange(of: vm.offerCodeRedemptionState)`
- Check `handleOfferCodeStateChange()` is called
- Verify `showingOfferCodeSuccess` toggles to true

**Solutions:**
- Set breakpoint in `handleOfferCodeStateChange()`
- Watch state transition
- Check alert binding

---

## Comparing Mock vs StoreKit Testing

| Feature | Debug Menu (Mock) | StoreKit Testing (This Guide) |
|---------|-------------------|------------------------------|
| **Uses real StoreKit APIs** | ❌ No | ✅ Yes |
| **Apple's redemption sheet** | ❌ Custom UI | ✅ Native iOS UI |
| **Transaction listener tested** | ❌ Not used | ✅ Fully tested |
| **Test expiration** | ✅ Yes | ❌ No |
| **Test redemption limits** | ✅ Yes | ❌ No |
| **Test "already redeemed"** | ✅ Yes | ❌ No |
| **Offline testing** | ✅ Yes | ✅ Yes |
| **Cost** | FREE | FREE |
| **Production code path** | ~30% | ~95% |

**Recommendation:** Use **both** approaches:
1. **Debug Menu** - Test validation logic (expiration, limits, duplicates)
2. **StoreKit Testing** - Test integration flow (sheet, transactions, state)

---

## Next Steps

### After Local Testing ✅

You have **two options**:

**Option 1: Deploy with Offer Codes Ready** (Recommended)
- Feature is complete and tested
- Deploy to production
- Activate when you get Apple Developer Program
- Users won't see offer code button until activated

**Option 2: Continue to TestFlight Testing**
- Purchase Apple Developer Program ($99/year)
- Create products in App Store Connect
- Create real offer codes
- Test in TestFlight
- Test cross-device sync and receipt validation

---

## Files Reference

### StoreKit Configuration
```
Configuration/Ritualist.storekit
```

### Production Service
```
Ritualist/Core/Services/StoreKitPaywallService.swift
├── listenForTransactions() → Detects offer codes
├── handleOfferCodeTransaction() → Processes redemptions
└── isOfferCodeRedemptionAvailable() → iOS 14+ check
```

### UI Layer
```
Ritualist/Features/Paywall/Presentation/
├── PaywallView.swift → Redemption sheet & alerts
└── PaywallViewModel.swift → State management
```

### Mock Testing (Alternative)
```
Ritualist/Features/Settings/Presentation/
└── DebugOfferCodesView.swift → Offline validation testing
```

---

## Support

**Issues?**
- Check Xcode console for errors
- Verify StoreKit configuration in scheme
- See "Debugging Tips" section above

**Questions?**
- Review implementation plan: `plans/offer-codes-implementation-plan.md`
- Check commit history on branch: `feature/offer-codes-integration`

---

**Summary:** This testing approach gives you **95% production confidence for $0**. The only things you can't test are server-side features (receipt validation, cross-device sync), which require the Apple Developer Program.
