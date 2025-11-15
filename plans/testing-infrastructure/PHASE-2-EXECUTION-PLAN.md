# Phase 2: Code Consolidation - Execution Plan

**Branch**: `feature/phase-2-consolidation`
**Date**: November 13, 2025 (Updated: November 15, 2025)
**Based On**: Phase 1 Comprehensive Audits (PR #37)
**Total Estimated Time**: ~~12-14 weeks~~ **9 weeks (revised)**
**Strategy**: Hybrid Bottom-Up with Quick Wins → **Revised: High-Impact Focus Only**

---

## 🎯 Executive Summary

Phase 1 audits identified **~1,819 lines** of consolidation opportunities across 4 layers.

**REVISED APPROACH (Nov 15, 2025):** Focus on high-impact fixes only, skip cosmetic UseCase consolidation.

**Current Progress: 599 of ~1,200 lines (50% complete) ✅**

| Layer | Quality | Lines to Consolidate | Completed | Remaining | Status | Revised Plan |
|-------|---------|---------------------|-----------|-----------|--------|--------------|
| **Data** | 8.5/10 ⭐ | ~303 lines (19%) | 157 lines | 146 lines | 🔄 Week 1-3 | Continue |
| **Repositories** | 6/10 | ~281 lines (49%) | 241 lines | 40 lines | ✅ Week 3 | Complete ✅ |
| **UseCases** | 5/10 ⚠️ | ~~735 lines (51%)~~ | 20 lines | **100 lines** | ⬜ Week 9 | **REDUCED SCOPE** |
| **Services** | 6.5/10 | ~500 lines (29%) | 181 lines | 319 lines | ⬜ Week 4-8 | Continue |
| **ViewModels** | 9.5/10 ✅ | 0 lines (perfect!) | N/A | N/A | ✅ Perfect | No changes |
| **TOTAL** | 7.1/10 | **~1,200** | **599** | **~605** | 🔄 **50%** | **9 weeks total** |

---

## 📋 DECISION LOG: Revised Approach (November 15, 2025)

### Why We're Skipping UseCase Layer Consolidation (Weeks 4-7)

**Original Plan:** Consolidate 63 thin wrapper UseCases into gateway classes (~735 lines, 4 weeks)

**Decision:** **SKIP THIS WORK** - Focus on high-impact fixes only

### Rationale:

#### ✅ Thin Wrappers Are Not Problems
- They work correctly
- Tests pass
- Architecture is clean (proper layer separation)
- They're just verbose (not broken)

#### ⚠️ Gateway Pattern Has Downsides
- Introduces new architectural concept to learn/maintain
- Requires churn if business logic needs to be added later
- **Inflexible:** If a thin wrapper needs to become a proper UseCase with validation/orchestration, must convert back
- Gateway pattern is premature optimization for a non-problem

#### 🎯 Better ROI Elsewhere
The **real value** in Phase 2 has been:
1. ✅ **Week 1:** Extracted business logic from DataSources (actual violation)
2. ✅ **Week 1:** Fixed N+1 query pattern (95% performance improvement)
3. ✅ **Week 3:** PersonalityAnalysisRepository refactoring (80% business logic violation)

These were **measurable architecture/performance fixes**, not cosmetic cleanup.

#### 🚀 Services Layer Has Real Issues
- Duplicate code across 3 services (`isLogCompleted()` in 3 places)
- Parallel sync/async hierarchies (actual duplicate implementations)
- Misclassified services doing UseCase work (real violations)

#### ⏱️ Time Savings
- **Original Plan:** 12 weeks total (3 complete + 9 remaining)
- **Revised Plan:** 9 weeks total (3 complete + 6 remaining)
- **Saved:** 3 weeks to focus on actual testing (Phase 3)

### Revised Success Criteria:

**Original Goals:**
- ~~108 → 53 UseCases (-51% reduction)~~ ❌ Not valuable
- ~~Introduce Gateway pattern~~ ❌ Unnecessary complexity

**Revised Goals:**
- ✅ Fix all **architecture violations** (business logic in wrong layers)
- ✅ Eliminate **actual duplicate code** (not just verbose wrappers)
- ✅ Improve **performance** (N+1 queries, slow operations)
- ✅ Get to **Phase 3 (testing)** faster

### What We're Keeping from Original Plan:

**HIGH-IMPACT WORK ONLY:**
1. ✅ Weeks 1-3: Critical fixes, performance, Repository refactoring (COMPLETE)
2. ⬜ Week 4: Extract shared utilities from Services (eliminate duplication)
3. ⬜ Week 5-6: Consolidate deprecated Services (remove parallel hierarchies)
4. ⬜ Week 7-8: Fix misclassified Services (architecture compliance)
5. ⬜ Week 9: PersonalityAnalysis UseCase cleanup (complete Week 3 work)

**TOTAL:** ~600 remaining lines of **actual problems**, not cosmetic cleanup

---

## ✅ Completed Work

### Phase 1: Comprehensive Audits (PR #37)
**Status**: ✅ Complete
**Documentation**: `docs/analysis/phase-1/`
- Cross-layer analysis documenting ~1,819 lines of consolidation opportunities
- Quality ratings and prioritization for all layers
- Architecture violation detection and remediation plans

### Phase 2, Week 1: Quick Wins (PR #39)
**Status**: ✅ Complete
**Date**: November 13, 2025
**Lines Reduced**: 289 lines

**Completed Tasks**:
1. ✅ **CategoryDefinitionsService Extraction**
   - Extracted 88 lines of predefined category data
   - Removed business logic from DataSource layer
   - 50% reduction in CategoryLocalDataSource size

2. ✅ **HabitMaintenanceService Extraction**
   - Extracted 36 lines of orphan cleanup logic
   - Proper error handling and service layer separation

3. ✅ **N+1 Query Optimization**
   - Implemented batch query in PersonalityAnalysisRepository
   - 95% query reduction (20 queries → 1 query)
   - Measurable performance improvement

4. ✅ **Obsolete UseCase Deletion**
   - Deleted `UpdateProfileSubscription` (obsolete)
   - Deleted `UpdateUserSubscription` (obsolete)
   - 20 lines removed

5. ✅ **Unused Service Deletion**
   - Deleted 4 services with zero dependencies
   - ~145 lines removed

**Quality Gates**: All passed ✅
- All tests passing
- All 4 build configurations succeed
- SwiftLint clean
- No architecture violations

### Phase 2, Week 2: Data & Repository Layer Optimizations (PR #41)
**Status**: ✅ Complete
**Date**: November 13, 2025
**Lines Reduced**: 69 lines

**Completed Tasks**:
1. ✅ **Day 1-2: Duplicate Mapping Elimination**
   - Added shared `updateFromEntity()` method to SchemaV8
   - Eliminated 28 duplicate property assignment lines
   - Single source of truth for entity-to-model mapping

2. ✅ **Day 3-4: CategoryLocalDataSource Performance**
   - Optimized 4 query methods with database-level filtering
   - `getCategory(by id)`: O(n) → O(1) (10x faster)
   - `categoryExists(id)`: 20x faster existence check
   - `getActiveCategories()`: Database filtering (3x faster)

3. ✅ **Day 5: Repository API Cleanup**
   - Removed redundant `HabitRepository.create()` method
   - Eliminated API confusion and maintenance burden
   - 6 lines removed (protocol + implementation + usages)

**Performance Impact**:
- 10-20x faster category queries
- Eliminated duplicate logic
- Cleaner API surface

**Quality Gates**: All passed ✅

### Phase 2, Week 3: PersonalityAnalysis Repository Refactoring (PR #43)
**Status**: ✅ Complete
**Date**: November 14, 2025
**Lines Reduced**: 241 lines ⭐ **EXCEEDED TARGET (estimated 225)**

**Completed Tasks**:
1. ✅ **PersonalityPreferencesDataSource Extraction**
   - Created dedicated DataSource for personality analysis preferences
   - Removed UserDefaults access from repository layer
   - Proper data layer separation
   - 48 new lines

2. ✅ **CalculateConsecutiveTrackingDaysService Creation**
   - Extracted consecutive day calculation logic from repository
   - Proper service layer placement for calculation logic
   - 43 new lines

3. ✅ **PersonalityAnalysisUseCases Expansion**
   - Created 6 new use cases for proper orchestration
   - Moved business logic from repository to use case layer
   - Clean separation of concerns
   - +136 lines added

4. ✅ **DataThresholdValidator Refactoring**
   - Resolved circular dependency
   - Consolidated validation logic
   - Improved architecture compliance

5. ✅ **PersonalityAnalysisRepositoryImpl Simplification**
   - **Reduced from 359 → 118 lines (-241 lines, -67% reduction!)**
   - Exceeded plan target by 7% (241 vs 225 lines)
   - Now a proper thin data access layer
   - Removed dependencies on 3 repositories, 2 services, and 1 UseCase

**Architecture Impact**:
- Repository layer violations eliminated
- Proper use case orchestration established
- Clean dependency direction restored
- Business logic in correct layers

**Bonus Work**:
- Notification UX improvements
- Deep link coordinator enhancements
- Comprehensive debug logging

**Quality Gates**: All passed ✅

**Total Progress**: 599 of ~1,819 lines (32.9% complete)

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

### ~~🔨 Week 4-7: UseCase Layer (The Big Consolidation)~~ ❌ **SKIPPED** (See Decision Log)

**Original Goal**: Consolidate 63 thin wrapper UseCases into gateway classes

**Decision (Nov 15, 2025)**: **SKIPPED** - Thin wrappers are verbose but not broken. Focus on high-impact fixes only.

**Rationale**:
- Thin wrappers work correctly and maintain clean architecture
- Gateway pattern introduces complexity without solving actual problems
- Better ROI focusing on Services layer (real duplication, real violations)
- Saves 4 weeks → faster path to Phase 3 (testing)

**See Decision Log above for full rationale.**

---

### ⚙️ **Week 4-8: Service Layer (High-Impact Fixes)** ⬅️ **REVISED FOCUS**

**Goal**: Consolidate duplicate services, extract utilities, refactor architecture

#### Week 4: Service P1 - Extract Shared Utilities (Phase 2.4b)

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

#### Week 5-6: Service P2 - Consolidate Deprecated Services (Phase 2.4c)

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

#### Week 7-8: Service P3 - Architecture Refactoring (Phase 2.4d)

**Complex refactoring** - Misclassified services

**Week 7: HabitCompletionCheckService → UseCase**
1. Rename to `ShouldShowNotificationUseCase`
2. Move to `UseCases/Implementations/Notifications/`
3. Update callers
4. Testing

**Week 8: PersonalityAnalysisScheduler & PaywallService**
1. Move PersonalityAnalysisScheduler logic to UseCase implementations
2. Delete scheduler class
3. Remove `@Observable` state from PaywallService
4. Move state management to ViewModel
5. Final comprehensive testing

**Files Affected**: 3 services refactored/deleted
**Impact**: ~300 lines moved to proper layers
**Estimated Time**: 2 weeks

---

#### Week 9: PersonalityAnalysis UseCase Cleanup (Complete Week 3 Work)

**Goal**: Finish PersonalityAnalysis refactoring by cleaning up UseCase layer

**Tasks**:
1. Delete 5 thin wrapper UseCases that delegate to PersonalityAnalysisScheduler
   - `StartAnalysisSchedulingUseCase`
   - `StopAnalysisSchedulingUseCase`
   - `TriggerAnalysisUseCase`
   - `ForceAnalysisUseCase`
   - `ShouldRunAnalysisUseCase`
2. Move remaining scheduler logic into proper UseCase implementations
3. Update DI registrations
4. Update any callers
5. Comprehensive testing

**Files Affected**: PersonalityAnalysisUseCases.swift
**Impact**: 5 UseCases deleted, ~100 lines removed
**Estimated Time**: 1 week

**Rationale**: Completes the PersonalityAnalysis repository refactoring from Week 3. These are the ONLY UseCase consolidations we're doing - they're completing existing work, not starting new consolidation.

---

## 📊 Progress Tracking

### Week-by-Week Milestones (REVISED):

| Week | Phase | Deliverable | Lines Reduced | Status |
|------|-------|-------------|---------------|--------|
| 1 | Quick Wins | All P0 tasks complete | 289 | ✅ Complete (PR #39) |
| 2 | Data + Repos | Data layer optimizations | 69 | ✅ Complete (PR #41) |
| 3 | Repository Refactoring | PersonalityAnalysis extraction | 241 ⭐ | ✅ Complete (PR #43) |
| ~~4-7~~ | ~~UseCases~~ | ~~Thin wrappers consolidated~~ | ~~735~~ | ❌ **SKIPPED** |
| 4 | Services P1 | Extract shared utilities | ~150 | ⬜ Pending |
| 5-6 | Services P2 | Consolidate deprecated services | ~250 | ⬜ Pending |
| 7-8 | Services P3 | Architecture refactoring | ~100 | ⬜ Pending |
| 9 | UseCases (targeted) | PersonalityAnalysis cleanup | ~100 | ⬜ Pending |
| **TOTAL** | | **Phase 2 Complete** | **~1,200** | 🔄 In Progress (599/1,200 = **50%**) |

### Quality Gates (Must Pass at Each Week):

- ✅ All tests passing
- ✅ All 4 build configurations succeed
- ✅ SwiftLint clean
- ✅ No architecture violations
- ✅ Performance benchmarks stable/improved
- ✅ Documentation updated

---

## 🎯 Success Criteria (REVISED)

### Overall Goals:

1. **Code Reduction**: ~~1,819 lines~~ → **~1,200 lines consolidated** (focus on high-impact only)
2. **Architecture Quality**: Improve from 7.1/10 → **8.5/10** (realistic target)
3. **Layer Quality**:
   - Data: 8.5/10 → 9.5/10 ✅
   - Repositories: 6/10 → **9.0/10** (nearly complete)
   - UseCases: ~~5/10 → 8.5/10~~ → **Keep at 5/10** (thin wrappers are verbose but not broken)
   - Services: 6.5/10 → **8.5/10** (eliminate duplication and violations)
   - ViewModels: 9.5/10 ✅ (maintain - perfect)

4. **Zero Regressions**: All existing functionality preserved ✅
5. **Performance**: N+1 queries eliminated, slow operations improved ✅
6. **Architecture Violations Fixed**: Business logic in correct layers ⬅️ **PRIMARY GOAL**
7. **Duplicate Code Eliminated**: Single source of truth for shared logic ⬅️ **PRIMARY GOAL**
8. **Faster to Phase 3**: Get to testing sooner (9 weeks vs 12 weeks) ⬅️ **NEW GOAL**

---

## ⚠️ Risks & Mitigation (REVISED)

### Risk 1: Breaking ViewModels (High Impact)
**Mitigation**: ViewModels are perfect - DO NOT TOUCH ✅
**Validation**: Run ViewModel tests after every change

### Risk 2: PersonalityAnalysis Cross-Cutting Changes
**Status**: ✅ Repository layer complete (Week 3)
**Remaining**: Week 8-9 (Services + UseCases cleanup)
**Mitigation**: Coordinate changes carefully, use existing patterns from Week 3

### Risk 3: DI Registration Errors
**Mitigation**: Test build after every DI change ✅
**Validation**: All 4 configurations must build

### ~~Risk 4: Thin Wrapper Consolidation Complexity~~ ❌ ELIMINATED
**Original Risk**: Gateway pattern complexity, refactoring churn
**Resolution**: **SKIPPED** - Thin wrappers remain, no risk introduced

---

## 📝 Next Steps (REVISED)

### Current Status: Week 3 Complete ✅ - Ready for Week 4

1. ✅ **Week 1 Complete** - PR #39 merged (289 lines)
2. ✅ **Week 2 Complete** - PR #41 merged (69 lines)
3. ✅ **Week 3 Complete** - PR #43 merged (241 lines) ⭐ **EXCEEDED TARGET**
   - ✅ Created PersonalityPreferencesDataSource (48 new lines)
   - ✅ Created CalculateConsecutiveTrackingDaysService (43 new lines)
   - ✅ Created 6 new UseCases in PersonalityAnalysisUseCases (+136 lines)
   - ✅ Fixed DataThresholdValidator circular dependency
   - ✅ PersonalityAnalysisRepositoryImpl reduced from 359 → 118 lines (-67%)
4. ~~⬜ Week 4-7: UseCase Layer Consolidation~~ ❌ **SKIPPED** (See Decision Log)
5. ⬜ **Week 4: Service Layer P1** - Extract shared utilities (~150 lines)
   - **NEXT IMMEDIATE TASK** ⬅️
   - Create HabitLogCompletionValidator
   - Extract CalendarUtils.habitWeekday()
   - Extract FeatureGatingConstants
6. ⬜ **Week 5-6: Service Layer P2** - Consolidate deprecated services (~250 lines)
7. ⬜ **Week 7-8: Service Layer P3** - Architecture refactoring (~100 lines)
8. ⬜ **Week 9: PersonalityAnalysis UseCase Cleanup** - Complete Week 3 work (~100 lines)

### Immediate Next Actions:

1. **Begin Week 4: Extract Shared Utilities from Services**
   - Create `HabitLogCompletionValidator` utility
   - Extract `isLogCompleted()` from 3 duplicate services
   - Add `CalendarUtils.habitWeekday()` method
   - Create `FeatureGatingConstants` for error messages
   - Update 5 services to use new utilities
   - **Expected Impact**: ~150 lines of duplication eliminated

2. **Continue progress tracking** - Update plan after each week
3. **Document lessons learned** - Capture insights from completed work

---

**Plan Status**: In Progress (**50% complete**) 🔄 ⬅️ **REVISED**
**Last PR**: PR #43 (PersonalityAnalysis Repository Refactoring - merged Nov 14)
**Completed**: 599 of ~1,200 lines ⬅️ **REVISED TARGET**
**Estimated Completion**: Week 9 (remaining **6 weeks**) ⬅️ **3 WEEKS SAVED**
**Next Action**: Begin Week 4 - Extract Shared Utilities from Services (P1)
