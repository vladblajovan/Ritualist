# GitHub Issues Audit

**Last Updated:** December 22, 2025
**Total Issues:** 2 open, 28+ closed
**Status:** Ready for App Store release

---

## Open Issues (2)

| # | Title | Priority | Notes |
|---|-------|----------|-------|
| #123 | Add @MainActor to PaywallService protocol for Swift 6 concurrency safety | Low | Technical debt - Swift 6 preparation, not blocking |
| #121 | Add automated tests for schema migration | Low | V9→V10 migration tests, nice-to-have |

---

## Recently Closed Issues

### Session: December 22, 2025

| # | Title | Reason |
|---|-------|--------|
| #122 | test: Add automated tests for CloudKit sync | Completed - unit tests added |
| #115 | Add unit tests for timezone handling race conditions | Completed |
| #102 | Refactor: Reduce RootTabViewModel responsibilities | Closed - deferred |
| #101 | Refactor: Standardize UserDefaults access | Closed - deferred |
| #100 | Refactor: Extract migration detection logic | Closed - deferred |
| #91 | Refactor RootTabView sheet state management | Closed - deferred |
| #90 | Audit and remove remaining hardcoded delays | Closed - deferred |
| #86 | Refactor: Create centralized ReminderOrchestrator | Closed - deferred |
| #82 | Export/Import sheet dismisses on first tap | Fixed |
| #79 | test: Add automated tests for CloudKit sync and schema migration | Completed |
| #78 | feat: Add CloudKit error handling and status monitoring | Completed |
| #77 | refactor: Audit relationship access patterns | Completed |
| #74 | Architecture Review: Category Storage Strategy | Closed - no action needed |
| #72 | Extract TodaysSummaryCard animation logic | Closed - deferred |
| #70 | Refactor OverviewViewModel race condition | Fixed |

### Earlier Session: December 21, 2025

| # | Title | Reason |
|---|-------|--------|
| #107 | Consider: Use actor isolation instead of NSLock | Not an issue - current implementation correct |
| #106 | Refactor: Register observer before synchronize() | Theoretical race condition, not practical |
| #76 | Fix: Update log message and migration description | Already fixed |
| #52 | Documentation: Fix inconsistent CalendarUtils header comment | Trivial, fixed |
| #51 | **P1: Fix non-atomic timezone history truncation** | **Fixed in PR #120** |

### Older Fixes

| # | Title | Reason |
|---|-------|--------|
| #62 | Phase 7: Activate Offer Codes in Production | Deferred - requires Apple Developer Program |
| #58 | Update README.md | Completed |
| #57 | Add SchemaV8 → V9 migration tests | Completed |
| #56 | Add DST transition test coverage | Completed |
| #55 | Cache timezone data in UI | Closed - low priority |
| #54 | Localize timezone strings | Closed - low priority |
| #53 | Add unit tests for DefaultTimezoneService | Completed |
| #50 | P0: Fix global state in CalendarUtils | Fixed |
| #49 | P0: Fix calendar cache thread safety | Fixed |
| #48 | Cache UserProfile in TimezoneService | Closed - low priority |

---

## Summary

### App Store Readiness: ✅ READY

All critical and high-priority issues have been resolved:
- ✅ P0 bugs fixed (calendar thread safety, global state)
- ✅ P1 bugs fixed (timezone history truncation)
- ✅ CloudKit sync working and tested
- ✅ Privacy manifest added
- ✅ Legal documents (Privacy Policy, Terms) linked
- ✅ App Store compliance requirements met

### Remaining Technical Debt (Non-blocking)

The 2 open issues are both low priority and do not block release:
1. **#123** - Swift 6 concurrency preparation (future-proofing)
2. **#121** - Additional migration test coverage (nice-to-have)

### Post-Release Improvements (v1.1+)

Several refactoring issues were closed as "deferred" - these can be revisited post-release:
- RootTabViewModel responsibilities (#102)
- UserDefaults standardization (#101)
- Sheet state management (#91)
- Hardcoded delays (#90)

---

## Version History

| Date | Open | Closed | Notes |
|------|------|--------|-------|
| Dec 22, 2025 | 2 | 28+ | Ready for release |
| Dec 21, 2025 | 19 | 5 | Initial audit |
