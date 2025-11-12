# Testing Infrastructure Improvements - Implementation Plan v2

**Branch**: `feature/testing-infrastructure-improvements`
**Status**: Planning Phase (Updated after Claude review)
**Priority**: HIGH (addresses critical PR #34 feedback)
**Version**: 2.0 (incorporates PR #35 review feedback)

---

## 🚨 CRITICAL UPDATE

**Based on Claude's PR #35 review**, we've identified BLOCKING issues that must be fixed before proceeding:

1. ❌ **TestDataBuilders.swift uses UTC** (lines 109, 127, 142) - Contradicts PR #34 timezone migration
2. ❌ **TestHelpers.swift uses UTC** - Systematic bias in all tests
3. ❌ **Missing test infrastructure for Repository/Data layers**
4. ❌ **Missing performance regression testing**
5. ❌ **Missing CI/CD integration strategy**

---

## 🎯 Objectives

Based on Claude's PR #34 review feedback + PR #35 review insights:

1. **FIX test infrastructure UTC usage FIRST** (Phase 0 - BLOCKING)
2. **Eliminate redundant/duplicate code** in Service and UseCase layers before testing
3. **Build timezone-specific test infrastructure** for comprehensive edge case coverage
4. **Achieve 80%+ business logic coverage, 90%+ Domain layer coverage** (per CLAUDE.md)
5. **Use real implementations, NOT mocks** (per MICRO-CONTEXTS/testing-strategy.md)
6. **Add regression protection** for 78 timezone fixes
7. **Test ALL layers**: Services, UseCases, Repositories, Data, ViewModels, Widget
8. **Performance regression testing** to validate N+1 optimizations

---

## 📋 Phase 0: Fix Test Infrastructure UTC Usage (BLOCKING)

> **CRITICAL**: Must be completed before any other phase. Current test infrastructure uses UTC, contradicting the PR #34 timezone migration.

### 0.1 Fix TestDataBuilders.swift

**File**: `RitualistTests/TestInfrastructure/TestDataBuilders.swift`

**Issues Found**:
- Lines 109, 127, 142: Using UTC timezone
- Test data created with UTC assumptions
- Mismatch with production code (now uses LOCAL)

**Required Changes**:
```swift
// BEFORE (UTC - WRONG):
timezone: "UTC"
CalendarUtils.startOfDayUTC(for: date)

// AFTER (LOCAL - CORRECT):
timezone: TimeZone.current.identifier
CalendarUtils.startOfDayLocal(for: date)
```

**Validation**:
- [ ] All test builders use LOCAL timezone by default
- [ ] Optional timezone parameter for cross-TZ testing
- [ ] No UTC assumptions in test data creation
- [ ] Build and verify existing tests still pass

### 0.2 Audit TestHelpers.swift for UTC Usage

**File**: `RitualistTests/TestInfrastructure/TestHelpers.swift`

**Audit Checklist**:
- [ ] Identify all date/time helper methods
- [ ] Check for UTC assumptions (TestDates, etc.)
- [ ] Add LOCAL variants where needed
- [ ] Document which helpers are UTC vs LOCAL and why

### 0.3 Verify CalendarUtils LOCAL Methods Availability

**File**: `RitualistCore/Sources/RitualistCore/Utilities/CalendarUtils.swift`

**Audit Checklist**:
- [ ] List all LOCAL methods available
- [ ] Identify missing LOCAL equivalents for UTC methods
- [ ] Document which UTC methods are deprecated
- [ ] Add any missing LOCAL helpers needed for testing

**Expected Output**:
- `test-infrastructure-audit.md` documenting current UTC usage
- Fixed TestDataBuilders.swift with LOCAL timezone
- Audited TestHelpers.swift with LOCAL variants
- CalendarUtils audit report

**Timeline**: 1 day (BLOCKING - must complete before Phase 1)

---

---

## ✅ Acceptance Criteria

Phase 0 is complete when:

1. ✅ TestDataBuilders.swift uses LOCAL timezone by default
2. ✅ Optional timezone parameter available for cross-TZ testing
3. ✅ TestHelpers.swift audited and fixed for UTC usage
4. ✅ CalendarUtils LOCAL methods documented and available
5. ✅ Validation tests added to prevent UTC regression
6. ✅ All existing tests still pass with LOCAL timezone
7. ✅ Documentation added for timezone parameter patterns
8. ✅ Build succeeds on iPhone 16, iOS 26 simulator

---

## 📊 Success Metrics

- **Zero UTC usage** in test data builders (except explicit cross-TZ tests)
- **100% of tests** use LOCAL timezone by default
- **All existing tests pass** after migration
- **Build time**: No regression in test execution time
- **Documentation**: Clear timezone parameter guidance for future tests

---

## 🔗 Related Work

- **PR #34**: Timezone migration (78 UTC → LOCAL fixes)
- **PR #35**: Testing infrastructure plan review
- **Parent Branch**: `feature/testing-infrastructure-improvements`

---

**This phase is BLOCKING for all subsequent testing work. Must complete before Phase 1 audit.**
