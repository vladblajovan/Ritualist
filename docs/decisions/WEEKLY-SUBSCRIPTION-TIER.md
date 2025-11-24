# Weekly Subscription Tier Decision

**Date**: November 24, 2025
**Status**: **IMPLEMENTED**
**Decision**: Weekly subscription tier **WILL** be offered at launch

---

## Background

The `SubscriptionPlan` enum in `RitualistCore/Sources/RitualistCore/Enums/Paywall/SubscriptionPlan.swift` includes a `.weekly` case:

```swift
public enum SubscriptionPlan: String, Codable, CaseIterable {
    case free
    case weekly     // ← Defined but not implemented
    case monthly
    case annual
    case lifetime
}
```

However, no corresponding product is configured in:
- `StoreKitConstants.swift` (no weekly product ID)
- `Ritualist.storekit` (local testing configuration)
- App Store Connect (production products)

---

## Current Product Lineup (Launch v1.0)

| Tier | Product ID | Price | Duration | Trial |
|------|-----------|-------|----------|-------|
| **Weekly** | `com.vladblajovan.ritualist.weekly` | $2.99 | 1 week | None |
| **Monthly** | `com.vladblajovan.ritualist.monthly` | $9.99 | 1 month | None |
| **Annual** | `com.vladblajovan.ritualist.annual` | $49.99 | 1 year | 7 days |
| **Lifetime** | `com.vladblajovan.ritualist.lifetime` | $99.99 | Forever | N/A |

---

## Why Weekly Tier IS Implemented

### 1. Lower Barrier to Entry
- **$2.99/week** is more accessible than $9.99/month upfront
- Reduces commitment anxiety for new users
- Easier to convert free users who are hesitant about monthly billing

### 2. User Testing Opportunity
- Users can **test premium for just one week**
- Perfect for evaluating habit tracking effectiveness
- Can upgrade to monthly/annual after seeing value

### 3. Pricing Psychology
- **Weekly price anchoring**: Makes monthly seem like better value ($9.99 vs $12.96/month)
- Creates a pricing ladder: Weekly → Monthly → Annual → Lifetime
- Users perceive more choice = better experience

### 4. Revenue Diversification
- Captures users who prefer weekly billing cycles
- Potential for higher conversion among budget-conscious users
- Weekly renewals provide consistent cash flow

### 5. Competitive Advantage
- Some users specifically search for weekly subscription apps
- Flexibility in billing appeals to gig economy workers
- Positions Ritualist as user-friendly and flexible

---

## Decision Rationale

**At launch (v1.0), we offer a complete 4-tier model**:

1. **Weekly** ($2.99) - Lowest commitment, trial option
2. **Monthly** ($9.99) - Standard entry point
3. **Annual** ($49.99 + 7-day trial) - Best value, long-term users
4. **Lifetime** ($99.99) - One-time purchase, super fans

This lineup is:
- ✅ **Accessible** - Multiple price points for different budgets
- ✅ **Flexible** - Users can choose their commitment level
- ✅ **Strategic** - Weekly makes monthly seem like better value
- ✅ **Comprehensive** - Covers all user segments

---

## Implementation Details

**Completed in PR #80**:

1. ✅ **Added product ID**: `com.vladblajovan.ritualist.weekly` to `StoreKitConstants.swift`
2. ✅ **Configured StoreKit**: Added weekly product to `Ritualist.storekit` ($2.99/week)
3. ✅ **Updated constants**: Added weekly to `subscriptionProducts` array
4. ✅ **Updated mapping**: `subscriptionPlan(for:)` now returns `.weekly` for weekly product ID
5. ✅ **Documentation**: Updated activation checklist with weekly product setup instructions

**Next Steps** (App Store Connect):
1. ⏳ Create weekly subscription product in App Store Connect
2. ⏳ Configure pricing: $2.99/week
3. ⏳ Add to Ritualist Premium subscription group
4. ⏳ Submit for Apple review
5. ⏳ Test in TestFlight with sandbox account

**UI Note**: PaywallView already loads products dynamically from StoreKit, so weekly tier will automatically appear when configured in App Store Connect.

---

## Code Impact

### Current State

**SubscriptionPlan enum** has `.weekly` case but it's **never returned** by any service:

```swift
// StoreKitConstants.swift:98-109
public static func subscriptionPlan(for productID: String) -> SubscriptionPlan {
    switch productID {
    case monthly:
        return .monthly
    case annual:
        return .annual
    case lifetime:
        return .lifetime
    default:
        return .free
    // NOTE: .weekly is never returned
    }
}
```

**UI handles `.weekly` gracefully** (defensive coding):

```swift
// SubscriptionManagementSectionView.swift
case .weekly:
    Text("Your weekly subscription gives you access to all premium features.")
```

**No breaking changes** - the enum case exists for future use without causing issues.

---

## Recommendation

### Action: **Keep enum case, document decision**

**DO**:
- ✅ Keep `.weekly` case in `SubscriptionPlan` enum (future-proofing)
- ✅ Document this decision in PR #80
- ✅ Mark as "NOT IMPLEMENTED" in status docs
- ✅ Revisit post-launch based on user feedback

**DON'T**:
- ❌ Remove `.weekly` case (would require enum migration)
- ❌ Implement weekly tier at launch (YAGNI - premature optimization)
- ❌ Block PR merge on weekly tier decision

---

## Summary

**Decision**: Weekly subscription tier is **intentionally not implemented** at launch.

**Reasoning**:
- Focus on proven 3-tier model (Monthly, Annual, Lifetime)
- Avoid pricing complexity and decision paralysis
- Weekly commitment too short for habit formation
- Can add later if user demand exists

**Code Status**:
- `.weekly` enum case exists (future-proofing)
- No product ID configured
- No StoreKit product created
- No App Store Connect product
- UI handles gracefully (defensive coding)

**Next Steps**:
- Launch with 3-tier model
- Monitor user feedback and metrics
- Revisit weekly tier decision in v1.1+ if data supports it

---

**Status**: 🟢 DOCUMENTED
**Impact**: None (no blocking issues for PR #80)
**Future**: Open to reconsideration based on market data

---

*Document Version: 1.0*
*Created: November 24, 2025*
*Author: Claude Code + Vlad Blajovan*
*Related PR: #80 (StoreKit2 Production Activation)*
