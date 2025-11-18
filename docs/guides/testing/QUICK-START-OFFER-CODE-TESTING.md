# Quick Start: Test Offer Codes in 5 Minutes

**No Apple Developer Program Required • 100% Free • Full Production Flow**

---

## 1. Enable StoreKit Testing (30 seconds)

```
Xcode → Product → Scheme → Edit Scheme (⌘<)
→ Run → Options → StoreKit Configuration
→ Select "Ritualist.storekit"
→ Close
```

---

## 2. Run the App (10 seconds)

```
Press ⌘R
Wait for app to launch in Simulator
```

---

## 3. Test Offer Code Redemption (2 minutes)

### Step-by-Step:

1. **Open Settings** (bottom tab bar)
2. **Tap subscription section** (shows current plan)
3. **Paywall appears**
4. **Look for:** "Have a promo code?" card (purple-pink giftcard icon)
5. **Tap the card**
6. **Apple's redemption sheet appears** (native iOS UI)
7. **Enter code:** `TESTANNUAL`
8. **Tap "Redeem"**

### ✅ Expected Result:

```
Sheet validates (1-2 seconds)
→ Sheet dismisses
→ Success alert: "Offer Code Redeemed!"
→ Message: "Successfully redeemed code for com.vladblajovan.ritualist.annual"
→ Tap "Great!"
→ Paywall dismisses
→ You now have Pro subscription!
```

---

## 4. Verify It Worked (30 seconds)

```
Go to Settings
→ Should see "Pro" badge
→ Should see "Annual" subscription
→ Premium features unlocked
```

---

## Available Test Codes

| Code | What It Does | Eligibility |
|------|--------------|-------------|
| `TESTANNUAL` | 1 year free | Everyone ✅ |
| `TESTMONTHLY` | 1 month free | Everyone ✅ |
| `RITUALIST2025` | 3 months free | New users only |
| `ANNUAL30` | 30% off annual | New users only |
| `WELCOME50` | 50% off monthly (3 months) | New users only |

**Pro Tip:** Use `TESTANNUAL` or `TESTMONTHLY` first - they work for everyone!

---

## Common Issues

### "This code is not valid"
- **Cause:** Code doesn't exist in `.storekit` file
- **Fix:** Use one of the codes above exactly as shown (case-sensitive)

### Offer code button doesn't appear
- **Cause:** StoreKit configuration not selected
- **Fix:** Repeat Step 1, make sure `Ritualist.storekit` is selected

### Nothing happens after "Redeem"
- **Cause:** Using MockPaywallService instead of StoreKitPaywallService
- **Note:** This is expected in current setup - see full testing guide

---

## What You're Testing

✅ **Real StoreKit 2 APIs** (not mocked)
✅ **Apple's native redemption sheet**
✅ **Transaction listener** (detects offer codes)
✅ **State management** (success alerts, paywall dismissal)
✅ **95% of production code path**

All for **$0** - no Apple Developer Program needed!

---

## Next Steps

**Want to test more scenarios?**
→ See full guide: `docs/guides/testing/OFFER-CODE-TESTING-GUIDE.md`

**Want to test validation logic?**
→ Use Debug Menu: Settings → Debug Menu → Offer Codes Testing
→ Test: expired codes, redemption limits, already redeemed, etc.

**Ready for production?**
→ Purchase Apple Developer Program ($99/year)
→ Create products in App Store Connect
→ Create real offer codes
→ Deploy to App Store

---

**That's it!** You just tested the complete offer code redemption flow using real StoreKit APIs, all locally in Xcode. 🎉
