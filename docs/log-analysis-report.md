# Log Analysis Report

**Date:** 2025-12-06
**Analyzed By:** Claude Code

## Executive Summary

The codebase uses a centralized `DebugLogger` system consistently. After this analysis:
- **Fixed:** 8 print statements converted to DebugLogger
- **Total logs:** ~478 log statements across the codebase
- **Widget code:** Still uses print statements (acceptable - widgets have limited logging infrastructure)

---

## 1. Print Statement Cleanup (Completed)

### Fixed in Main App (`Ritualist/`)
| File | Change |
|------|--------|
| `StoreKitSubscriptionService.swift` | 3 print statements → DebugLogger (StoreKit timeout fallback) |

### Fixed in Core (`RitualistCore/`)
| File | Change |
|------|--------|
| `PaywallService.swift` | 1 print statement → DebugLogger (mock redemption sheet) |
| `MockOfferCodeStorageService.swift` | 1 print statement → DebugLogger (failed code loading) |
| `SecurePremiumCache.swift` | 1 print statement → DebugLogger (Keychain save failure) |

### Intentionally Left Unchanged
| File | Reason |
|------|--------|
| `MigrationPlan.swift` | Print statements are in commented-out example code |
| `RitualistWidget/*` | Widget extensions have separate logging needs; limited context |
| `Scripts/*.swift` | Build/validation scripts, not runtime code |
| `DebugMenuView.swift` | Uses `Logger()` directly for debug menu specific output |

---

## 2. Log Distribution by Level

| Level | Count | Purpose |
|-------|-------|---------|
| `.info` | 189 | Normal operations, state changes |
| `.debug` | 133 | Development diagnostics (filtered in production) |
| `.warning` | 95 | Recoverable issues, fallback paths |
| `.error` | 58 | Failed operations requiring attention |
| `.critical` | 3 | Fatal issues (persistence failures) |

**Note:** Production builds only log `.error` and `.critical` (see `DebugLogger.swift:105`)

---

## 3. Log Distribution by Category

### High-Volume Categories (Potential Noise)
| Category | Count | Assessment |
|----------|-------|------------|
| `.system` | 153 | **Mixed** - includes app lifecycle (relevant) + startup details (verbose) |
| `.dataIntegrity` | 121 | **Relevant** - critical for debugging sync/migration issues |
| `.ui` | 67 | **Noisy** - many tab switch/reload logs that pollute console |
| `.location` | 47 | **Relevant** - geofence operations need audit trail |
| `.notifications` | 32 | **Relevant** - notification scheduling is complex |

### Low-Volume Categories (Appropriate)
| Category | Count | Assessment |
|----------|-------|------------|
| `.subscription` | 15 | Appropriate for IAP operations |
| `.personality` | 7 | Appropriate for AI feature |
| `.performance` | 1 | **Underutilized** - should have more performance logging |

---

## 4. Candidates for Removal/Downgrade

### High Priority: Tab Switch Logs (Noisy)
These fire every time user switches tabs - too verbose:

```
Ritualist/Features/Overview/Presentation/OverviewView.swift:217
  "Tab switch detected: Reloading overview data" (level: .debug)

Ritualist/Features/Habits/Presentation/HabitsView.swift:33
  "Tab switch detected: Reloading habits data" (level: .debug)

Ritualist/Features/Dashboard/Presentation/DashboardView.swift:70
  "Tab switch detected: Reloading dashboard data" (level: .debug)

Ritualist/Features/Settings/Presentation/SettingsView.swift:29
  "Tab switch detected: Reloading settings data" (level: .debug)

Ritualist/Features/Dashboard/Presentation/DashboardViewModel.swift:374
  "Dashboard load skipped - data already loaded" (level: .debug)

Ritualist/Features/Dashboard/Presentation/DashboardViewModel.swift:391
  "Dashboard cache invalidated for tab switch" (level: .debug)
```

**Recommendation:** Remove or make conditional on a verbose debug flag.

---

### Medium Priority: Widget Refresh Logs
These fire frequently and aren't actionable:

```
Ritualist/Core/Services/WidgetRefreshService.swift:24
  "Refreshing all widgets: RemainingHabitsWidget" (level: .debug)

Ritualist/Core/Services/WidgetRefreshService.swift:26
  "Widget refresh command sent" (level: .debug)
```

**Recommendation:** Keep only error cases.

---

### Medium Priority: Quick Action Logs
Every quick action logs multiple times:

```
Ritualist/Application/RootTabView.swift:292-392
  Multiple "Quick Action: ..." logs for same action flow
```

**Recommendation:** Consolidate to single log per action completion.

---

### Low Priority: iCloud Sync Logs
These are useful for debugging but verbose during normal operation:

```
Ritualist/Application/RootTabViewModel.swift:67
  "iCloud KV sync timed out" (level: .debug)

Ritualist/Application/RootTabViewModel.swift:430
  "Skipping sync toast - CloudKit sync not active" (level: .debug)
```

**Recommendation:** Keep - useful for debugging sync issues.

---

## 5. Logs to Keep (Super Relevant)

### Critical Operations
- All `.critical` and `.error` level logs
- Persistence container initialization
- Migration operations (MigrationLogger)
- Premium status verification
- Data deduplication results

### Security-Related
- StoreKit verification results
- Premium cache updates
- Keychain operations

### User-Impacting
- Notification scheduling failures
- Geofence event processing
- Backup/restore operations

---

## 6. Recommendations Summary

| Priority | Action | Impact |
|----------|--------|--------|
| **High** | Remove 6 tab switch debug logs | Reduces console noise significantly |
| **Medium** | Consolidate Quick Action logs | Cleaner action tracking |
| **Medium** | Remove widget refresh success logs | Less noise during normal use |
| **Low** | Add more `.performance` logging | Better performance diagnostics |

---

## 7. Widget Logging (Separate Concern)

The widget extension (`RitualistWidget/`) uses `print()` statements extensively. This is acceptable because:
1. Widgets run in a separate process
2. Widget debugging requires different tooling (Console.app)
3. No DI container available in widget context

**Future Enhancement:** Consider creating a lightweight widget-specific logger.
