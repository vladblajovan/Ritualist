# GitHub Issues Audit

**Date:** December 22, 2025
**Total Issues Reviewed:** 24
**Issues Closed:** 5
**Issues Remaining:** 19

---

## Issues Closed

| # | Title | Reason |
|---|-------|--------|
| #107 | Consider: Use actor isolation instead of NSLock | Issue itself stated "Not an issue" - current NSLock implementation is correct |
| #106 | Refactor: Register observer before synchronize() | Theoretical race condition that cannot occur in practice |
| #76 | Fix: Update log message and migration description | Already fixed - code now uses dynamic version string |
| #52 | Documentation: Fix inconsistent CalendarUtils header comment | Trivial documentation issue |
| #51 | **P1: Fix non-atomic timezone history truncation** | **Fixed in PR #120** |

---

## Issues Remaining (19)

### Bugs (1)

| # | Title | Priority | Notes |
|---|-------|----------|-------|
| #82 | Export/Import sheet dismisses on first tap | Medium | SwiftUI timing issue with UIDocumentPickerViewController. Works on second tap. |

### Testing (5)

| # | Title | Priority | Notes |
|---|-------|----------|-------|
| #115 | Add unit tests for timezone handling race conditions and throttling | Medium | Tests for `needsRefreshAfterLoad` pattern and notification throttling |
| #79 | Add automated tests for CloudKit sync and schema migration | Medium | V9→V10 migration and CloudKit integration tests |
| #57 | Add SchemaV8 → V9 migration tests | Low | Older migration, less critical |
| #56 | Add DST transition test coverage | Medium | Important for timezone reliability |
| #53 | Add comprehensive unit tests for DefaultTimezoneService | Medium | Core timezone functionality |

### Refactoring / Code Quality (8)

| # | Title | Priority | Notes |
|---|-------|----------|-------|
| #102 | Reduce RootTabViewModel responsibilities (SRP violation) | Medium | ViewModel handles 8+ responsibilities |
| #101 | Standardize UserDefaults access with injectable service | Low | 30+ direct `.standard` accesses found |
| #100 | Extract migration detection logic to dedicated UseCase | Low | Move logic from ViewModel to Domain layer |
| #91 | Refactor RootTabView sheet state management using enum | Low | Replace 5+ boolean states with enum |
| #90 | Audit and remove remaining hardcoded delays | Medium | Replace `Task.sleep`/`asyncAfter` with callbacks |
| #86 | Create centralized ReminderOrchestrator | Low | Coordinate notifications and geofences |
| #72 | Extract TodaysSummaryCard animation logic | Low | Minor code organization |
| #70 | Refactor OverviewViewModel to prevent race condition | Medium | viewingDate/summary synchronization |

### Performance (2)

| # | Title | Priority | Notes |
|---|-------|----------|-------|
| #55 | Cache timezone data in UI to reduce profile loads | Low | Optimization opportunity |
| #48 | Cache UserProfile in TimezoneService to reduce disk I/O | Medium | P2 performance improvement |

### Features / Enhancements (3)

| # | Title | Priority | Notes |
|---|-------|----------|-------|
| #78 | Add CloudKit error handling and status monitoring | Medium | User-facing sync status and error feedback |
| #74 | Architecture Review: Category Storage Strategy | Low | In-memory vs pure DB approach |
| #54 | Localize timezone strings in Advanced Settings | Low | i18n enhancement, good first issue |

---

## Recommendations

### Before App Store Release

1. **Consider fixing #82** (Export/Import sheet dismiss) - Poor UX but functional on second tap
2. **#78 CloudKit error handling** - Users need feedback when sync fails

### Post-Release / v1.1

1. **Testing issues** (#115, #79, #56, #53) - Add test coverage for confidence
2. **Refactoring** (#102, #90, #70) - Improve code quality and maintainability
3. **Performance** (#48) - Profile caching for better responsiveness

### Backlog / Nice-to-Have

- #101, #100, #91, #86, #72 - Code organization improvements
- #74 - Architecture review (no immediate action needed)
- #54, #55, #57 - Low priority enhancements

---

## Summary by Category

```
Bugs:        1 remaining
Testing:     5 remaining
Refactoring: 8 remaining
Performance: 2 remaining
Features:    3 remaining
─────────────────────────
Total:      19 remaining
```

---

## Actions Taken in This Audit

1. Closed 5 irrelevant/outdated/fixed issues
2. Fixed P1 bug #51 (timezone history truncation)
3. Categorized and prioritized remaining 19 issues
4. Identified pre-release vs post-release priorities
