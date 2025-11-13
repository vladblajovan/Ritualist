# Phase 2: Code Consolidation - Execution Plan

**Branch**: `feature/phase-2-consolidation`
**Date**: November 13, 2025
**Based On**: Phase 1 Comprehensive Audits (PR #37)
**Total Estimated Time**: 12-14 weeks
**Strategy**: Hybrid Bottom-Up with Quick Wins

---

## 🎯 Executive Summary

Phase 1 audits identified **~1,819 lines** of consolidation opportunities across 4 layers:

| Layer | Quality | Lines to Consolidate | Estimated Time |
|-------|---------|---------------------|----------------|
| **Data** | 8.5/10 ⭐ | ~303 lines (19%) | 5-7 days |
| **Repositories** | 6/10 | ~281 lines (49%) | 2-3 days |
| **UseCases** | 5/10 ⚠️ | ~735 lines (51%) | 15-17 days |
| **Services** | 6.5/10 | ~500 lines (29%) | 12-13 days |
| **ViewModels** | 9.5/10 ✅ | 0 lines (perfect!) | 0 days |
| **TOTAL** | 7.1/10 | **~1,819 lines** | **12-14 weeks** |

---

## 🧠 Ultra-Thinking: Execution Order Analysis

### Critical Insights:

1. **ViewModels are perfect (9.5/10)** - NO CHANGES NEEDED ✅
2. **Data layer is best (8.5/10)** - Minimal issues, clean architecture
3. **UseCases are worst (5/10)** - 58% thin wrappers, highest priority
4. **PersonalityAnalysis feature** - Issues across ALL 4 layers (cross-cutting concern)
5. **Dependencies matter** - Services depend on UseCases, UseCases depend on Repositories

### Execution Strategies Considered:

#### ❌ Option A: Strict Bottom-Up (Data → Repos → UseCases → Services)
**Pros**: Maintains clean dependencies, safest
**Cons**: Delays high-value UseCase consolidation, slow visible progress
**Verdict**: Too slow, delays most impactful work

#### ❌ Option B: Quick Wins First (All P0s across all layers)
**Pros**: Fast momentum, visible impact immediately
**Cons**: Jumps between layers, might create inconsistencies
**Verdict**: Too chaotic, risks breaking dependencies

#### ❌ Option C: Feature-Based (Fix PersonalityAnalysis across all layers)
**Pros**: Fixes one feature completely
**Cons**: Touches all layers simultaneously, very risky
**Verdict**: Too risky, complex coordination

#### ✅ Option D: Hybrid Bottom-Up with Quick Wins (CHOSEN)
**Pros**:
- Quick wins (P0) for immediate momentum
- Bottom-up for safety and clean dependencies
- Isolates risky changes
- Maximizes parallel work opportunities

**Cons**: Slightly more complex tracking
**Verdict**: Best balance of speed, safety, and impact

---

## 📅 Detailed Execution Plan

### 🚀 **Week 1: Foundation + Quick Wins (P0 across all layers)**

**Goal**: Execute all P0 (Priority 0) tasks - fastest wins with highest impact

#### Day 1: Data Layer P0 - Business Logic Extraction (Phase 2.1)
**Target**: `CategoryLocalDataSource.swift`, `HabitLocalDataSource.swift`

**Tasks**:
1. Create `CategoryDefinitionsService`
   - Extract predefined category data (88 lines)
   - Extract personality weights
   - Write comprehensive tests
   - Register in DI

2. Create `HabitMaintenanceService`
   - Extract orphan cleanup logic (36 lines)
   - Add proper error handling
   - Write tests

**Files Affected**: 2 DataSources, 2 new Services
**Impact**: 124 lines extracted, 50% reduction in CategoryLocalDataSource
**Estimated Time**: Full day
**Validation**: All existing tests pass, new tests added

---

#### Day 2: Repository Layer P0 - N+1 Query Fix (Phase 2.2a)
**Target**: `PersonalityAnalysisRepositoryImpl.swift` (Lines 285-294)

**Task**: Replace loop with batch query
```swift
// BEFORE: ❌
for habit in activeHabits {
    let habitLogs = try await logRepository.logs(for: habit.id)
    ...
}

// AFTER: ✅
let habitIds = activeHabits.map(\.id)
let logsByHabitId = try await getBatchLogs.execute(...)
```

**Files Affected**: 1 Repository
**Impact**: 95% query reduction (20 queries → 1 query)
**Estimated Time**: 2 hours
**Validation**: Performance tests confirm query reduction

---

#### Day 2 (Afternoon): UseCase Layer P0 - Delete Obsolete UseCases (Phase 2.3a)
**Target**: `UserUseCases.swift`

**Tasks**:
1. Delete `UpdateProfileSubscription` (obsolete no-op)
2. Delete `UpdateUserSubscription` (obsolete no-op)
3. Search codebase for usage (confirm zero)
4. Remove from DI registrations

**Files Affected**: 1 file
**Impact**: ~20 lines removed
**Estimated Time**: 1 hour
**Validation**: Grep confirms zero usage, all tests pass

---

#### Day 3: Service Layer P0 - Delete Unused Services (Phase 2.4a)
**Target**: Delete 4 services with zero dependencies

**Tasks**:
1. Delete `HabitAnalyticsService.swift` (already deprecated)
2. Delete `MockFeatureGatingService.swift` (duplicate)
3. Delete `MockFeatureGatingBusinessService.swift` (violates testing strategy)
4. Delete `PaywallBusinessService.swift` (unused duplicate)
5. Remove from DI registrations
6. Run full test suite

**Files Affected**: 4 Services
**Impact**: ~200 lines removed
**Estimated Time**: 2 hours
**Validation**: All tests pass, grep confirms zero usage

---

#### Day 4-5: Validation & Documentation
**Tasks**:
1. Run full test suite (all tests must pass)
2. Run all 4 build configurations
3. Performance benchmarks (N+1 fix validation)
4. Update CHANGELOG.md
5. Create PR for Week 1 work
6. Document lessons learned

**Deliverables**:
- All P0 tasks complete
- 344 lines removed/extracted
- Zero test failures
- PR ready for review

---

### 📦 **Week 2-3: Data + Repository Layers Complete**

**Goal**: Finish Data layer cleanup, extract PersonalityAnalysisRepository business logic

#### Week 2, Day 1-2: Data Layer P1 - Duplicate Mapping (Phase 2.1b)
**Target**: `HabitLocalDataSource.swift` (Lines 48-76)

**Task**: Use `SchemaV8.fromEntity()` instead of manual mapping
**Files Affected**: 1 DataSource
**Impact**: 35 lines removed, single source of truth
**Estimated Time**: 1-2 days

---

#### Week 2, Day 3-4: Data Layer P2 - Performance Optimization (Phase 2.1c)
**Target**: `CategoryLocalDataSource.swift`

**Tasks**:
1. Add predicate filter to `getActiveCategories()`
2. Add predicate filter to `getCustomCategories()`

**Files Affected**: 1 DataSource
**Impact**: Database-level filtering (performance improvement)
**Estimated Time**: 1-2 days

---

#### Week 2, Day 5: Repository Layer P1 - Convenience Methods (Phase 2.2b)
**Target**: `OnboardingRepositoryImpl.swift`, `ProfileRepositoryImpl.swift`

**Tasks**:
1. Delete `markOnboardingCompleted()` (move to UseCase)
2. Make `loadProfile()` return optional (move default creation to UseCase)
3. Make `getOnboardingState()` return optional

**Files Affected**: 2 Repositories
**Impact**: ~26 lines removed
**Estimated Time**: 2 hours

---

#### Week 3: Repository Layer P2 - PersonalityAnalysis Extraction (Phase 2.2c)

**MAJOR REFACTORING** - Extract 225 lines from PersonalityAnalysisRepository

**Day 1-2: Create New Components**
1. `GetHabitAnalysisInputUseCase` (58 lines)
2. `CalculateConsecutiveTrackingDaysService` (23 lines)
3. `GetSelectedHabitSuggestionsUseCase` (15 lines)
4. `EstimateDaysToEligibilityUseCase` (17 lines)
5. `PersonalityPreferencesDataSource` (29 lines)

**Day 3-4: Consolidate with Existing**
6. Merge validation logic with `ValidateAnalysisEligibilityUseCase` (existing)
7. Merge threshold logic with `DataThresholdValidator` (existing)

**Day 5: Integration & Testing**
- Update PersonalityAnalysisRepository to use new components
- Update DI registrations
- Comprehensive testing

**Files Affected**: 1 Repository, 3 new UseCases, 1 new Service, 1 new DataSource, 2 existing components
**Impact**: Repository reduced from 359 → 134 lines (-63%)
**Estimated Time**: 5 days

---

### 🔨 **Week 4-7: UseCase Layer (The Big Consolidation)**

**Goal**: Consolidate 63 thin wrapper UseCases (58% of layer)

#### Week 4-5: UseCase P1 - High-Value Consolidation (Phase 2.3b)
**Target**: Files with 100% thin wrappers

**Day 1-2: Create Gateway Classes**
1. `HabitCompletionServiceGateway` (consolidates 4 UseCases from HabitCompletionUseCases.swift)
2. `ProfileRepositoryGateway` (consolidates 2 UseCases from ProfileUseCases.swift)
3. `SubscriptionServiceGateway` (consolidates 6 UseCases from UserUseCases.swift)
4. `PaywallServiceGateway` (consolidates 6 UseCases from PaywallUseCases.swift)
5. `MigrationServiceGateway` (consolidates 1 UseCase from MigrationUseCases.swift)

**Day 3-4: Delete Thin Wrappers**
- Delete 19 thin wrapper classes
- Update ViewModels to use gateways
- Update DI registrations

**Day 5: Testing & Validation**
- Comprehensive test suite
- Verify architecture compliance

**Files Affected**: 5 files, 19 UseCases deleted, 5 gateways created
**Impact**: ~240 lines removed
**Estimated Time**: 2 weeks

---

#### Week 6: UseCase P2 - Medium-Value Consolidation (Phase 2.3c)
**Target**: Files with 67-87% thin wrappers

**Day 1-3: Create Gateway Classes**
1. `ServiceGateway` (consolidates 7 of 8 from ServiceBasedUseCases.swift)
2. `TipRepositoryGateway` (consolidates 3 of 4 from TipUseCases.swift)
3. `iCloudSyncGateway` (consolidates 3 of 4 from iCloudSyncUseCases.swift)
4. `OnboardingRepositoryGateway` (consolidates 2 of 3 from OnboardingUseCases.swift)
5. `DebugServiceGateway` (consolidates 2 of 3 from DebugUseCases.swift)

**Day 4-5: Integration & Testing**
- Delete 17 thin wrapper classes
- Update callers
- Testing

**Files Affected**: 5 files, 17 UseCases deleted, 5 gateways created
**Impact**: ~225 lines removed
**Estimated Time**: 1 week

---

#### Week 7: UseCase P4 - PersonalityAnalysis Refactoring (Phase 2.3d)
**Target**: PersonalityAnalysisUseCases.swift

**Tasks**:
1. Delete 5 thin wrapper UseCases that delegate to PersonalityAnalysisScheduler
2. Move PersonalityAnalysisScheduler logic to proper UseCase implementations
3. Consolidate scheduling logic into existing AnalyzePersonalityUseCase
4. Update DI registrations

**Files Affected**: PersonalityAnalysisUseCases.swift, PersonalityAnalysisScheduler.swift
**Impact**: 5 UseCases deleted, ~100 lines removed, eliminates circular dependency
**Estimated Time**: 1 week

---

### ⚙️ **Week 8-12: Service Layer (Final Cleanup)**

**Goal**: Consolidate duplicate services, extract utilities, refactor architecture

#### Week 8: Service P1 - Extract Shared Utilities (Phase 2.4b)

**Day 1-2: Create Utilities**
1. `HabitLogCompletionValidator` - Extract `isLogCompleted()` from 3 services (45 lines)
2. Add `CalendarUtils.habitWeekday()` - Extract `getHabitWeekday()` from 2 services (8 lines)
3. `FeatureGatingConstants` - Extract duplicate error messages (100+ lines)

**Day 3-5: Refactor Services**
- Update 3 services to use HabitLogCompletionValidator
- Update 2 services to use CalendarUtils.habitWeekday()
- Update feature gating to use constants
- Testing

**Files Affected**: 3 new utilities, 5 services updated
**Impact**: ~150 lines deduplication
**Estimated Time**: 1 week

---

#### Week 9-10: Service P2 - Consolidate Deprecated Services (Phase 2.4c)

**Target**: Sync/Async parallel hierarchies

**Tasks**:
1. Migrate UseCases from `FeatureGatingService` → `FeatureGatingBusinessService`
2. Migrate UseCases from `DefaultFeatureGatingService` → `DefaultFeatureGatingBusinessService`
3. Migrate UseCases from `BuildConfigFeatureGatingService` → `BuildConfigFeatureGatingBusinessService`
4. Delete `ScheduleAwareCompletionCalculator.swift` (pure wrapper)
5. Delete 3 sync variant services
6. Update DI registrations
7. Comprehensive testing

**Files Affected**: 4 Services deleted, multiple UseCases updated
**Impact**: ~250 lines removed, 50% reduction in feature gating services
**Estimated Time**: 2 weeks

---

#### Week 11-12: Service P3 - Architecture Refactoring (Phase 2.4d)

**Complex refactoring** - Misclassified services

**Week 11: HabitCompletionCheckService → UseCase**
1. Rename to `ShouldShowNotificationUseCase`
2. Move to `UseCases/Implementations/Notifications/`
3. Update callers
4. Testing

**Week 12: PersonalityAnalysisScheduler & PaywallService**
1. Move PersonalityAnalysisScheduler logic to UseCase implementations
2. Delete scheduler class
3. Remove `@Observable` state from PaywallService
4. Move state management to ViewModel
5. Final comprehensive testing

**Files Affected**: 3 services refactored/deleted
**Impact**: ~300 lines moved to proper layers
**Estimated Time**: 2 weeks

---

## 📊 Progress Tracking

### Week-by-Week Milestones:

| Week | Phase | Deliverable | Lines Reduced | Status |
|------|-------|-------------|---------------|--------|
| 1 | Quick Wins | All P0 tasks complete | ~344 | ⬜ Pending |
| 2-3 | Data + Repos | Layers complete | ~587 | ⬜ Pending |
| 4-7 | UseCases | Thin wrappers consolidated | ~735 | ⬜ Pending |
| 8-12 | Services | Final cleanup | ~500 | ⬜ Pending |
| **TOTAL** | | **Phase 2 Complete** | **~1,819** | ⬜ Pending |

### Quality Gates (Must Pass at Each Week):

- ✅ All tests passing
- ✅ All 4 build configurations succeed
- ✅ SwiftLint clean
- ✅ No architecture violations
- ✅ Performance benchmarks stable/improved
- ✅ Documentation updated

---

## 🎯 Success Criteria

### Overall Goals:

1. **Code Reduction**: ~1,819 lines consolidated (35% reduction)
2. **Architecture Quality**: Improve from 7.1/10 → 9.0/10
3. **Layer Quality**:
   - Data: 8.5/10 → 9.5/10
   - Repositories: 6/10 → 9/10
   - UseCases: 5/10 → 8.5/10
   - Services: 6.5/10 → 9/10
   - ViewModels: 9.5/10 (maintain)

4. **Zero Regressions**: All existing functionality preserved
5. **Performance**: N+1 queries eliminated, performance improved
6. **Testability**: Improved test coverage with real implementations

---

## ⚠️ Risks & Mitigation

### Risk 1: Breaking ViewModels (High Impact)
**Mitigation**: ViewModels are perfect - DO NOT TOUCH
**Validation**: Run ViewModel tests after every change

### Risk 2: PersonalityAnalysis Cross-Cutting Changes
**Mitigation**: Coordinate changes across layers carefully
**Strategy**: Fix bottom-up (Data → Repos → UseCases → Services)

### Risk 3: DI Registration Errors
**Mitigation**: Test build after every DI change
**Validation**: All 4 configurations must build

### Risk 4: Thin Wrapper Consolidation Complexity
**Mitigation**: Create gateways incrementally, one file at a time
**Validation**: Test suite run after each gateway creation

---

## 📝 Next Steps

1. **Review this plan** with team/stakeholders
2. **Create Week 1 tracking issue** with detailed tasks
3. **Start Phase 2.1 (Data Layer P0)** - CategoryDefinitionsService extraction
4. **Set up progress tracking** (GitHub project board)
5. **Document lessons learned** after each week

---

**Plan Status**: Ready for Execution ✅
**Branch**: `feature/phase-2-consolidation`
**Estimated Completion**: Week 12 (3 months)
**Next Action**: Begin Week 1, Day 1 - Data Layer P0
