# @Query Integration with Clean Architecture - Deep Analysis

**Date**: 2025-11-07
**Context**: Investigating how SwiftData's `@Query` macro can be integrated while preserving Clean Architecture principles

## Executive Summary

SwiftData's `@Query` provides automatic reactivity and eliminates manual state synchronization. However, integrating it with Clean Architecture (View → ViewModel → UseCase → Repository) creates tension between **automatic reactivity** and **architectural boundaries**.

**Key Question**: Can we leverage `@Query`'s power while maintaining separation of concerns, testability, and domain independence?

**Answer**: Yes, through **hybrid architecture** - selective use of @Query where it provides maximum value while preserving Clean Architecture for business logic.

---

## Current Architecture Analysis

### 1. Existing Layer Structure

```
┌──────────────────────────────────────────────┐
│ View Layer (SwiftUI)                         │
│ - Uses @State ViewModel                      │
│ - No direct SwiftData access                 │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│ ViewModel Layer (@MainActor @Observable)     │
│ - Manages UI state                           │
│ - Calls UseCases for operations             │
│ - Manually syncs with database               │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│ UseCase Layer (Business Logic)               │
│ - Single responsibility operations           │
│ - Calls Repositories                         │
│ - Pure business logic                        │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│ Repository Layer (Protocol)                  │
│ - Repository Protocol (Domain)               │
│ - RepositoryImpl (Data)                      │
│ - Returns Domain entities                    │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│ DataSource Layer (@ModelActor)               │
│ - HabitLocalDataSource                       │
│ - Background ModelContext                    │
│ - Fetches SwiftData models                   │
│ - Converts to Domain entities                │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│ SwiftData Layer                              │
│ - ActiveHabitModel (SchemaV7.HabitModel)     │
│ - ModelContainer (injected at app level)     │
│ - Persistence & migrations                   │
└──────────────────────────────────────────────┘
```

### 2. Data Flow Example

**Reading Habits (Current)**:
```swift
// View
OverviewView
  └─ vm.habitsData                    // UI reads ViewModel state
      └─ await loadHabitsData.execute()   // ViewModel calls UseCase
          └─ habitRepository.fetchAllHabits()   // UseCase calls Repository
              └─ local.fetchAll()                // Repository calls DataSource
                  └─ modelContext.fetch(FetchDescriptor<ActiveHabitModel>)  // SwiftData query
                      └─ habits.compactMap { try $0.toEntity() }  // Convert to Domain
```

**Problem**: Every step is manual, no automatic updates, requires explicit `await load()` calls.

### 3. ModelContainer Setup

**File**: `RitualistApp.swift` (Line 26)
```swift
RootAppView()
    .modelContainer(persistenceContainer.container)  // ← SwiftData environment available!
```

**Key insight**: ModelContainer IS already in SwiftUI environment! Views CAN access `@Query` if they want.

### 4. SwiftData Model Details

**Type Alias Chain**:
```swift
// ActiveSchema.swift
ActiveHabitModel = HabitModelV7

// SchemaV7.swift
HabitModelV7 = SchemaV7.HabitModel

// SchemaV7.swift
@Model
public final class HabitModel {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var colorHex: String
    // ... full SwiftData model with @Relationship, etc.
}
```

**Key insight**: `ActiveHabitModel` is a fully-fledged @Model class that @Query can use!

---

## @Query Capabilities & Constraints

### What @Query Gives You (FREE!)

1. **Automatic Updates**: View refreshes when database changes
2. **No Manual Syncing**: No `await load()` calls needed
3. **Declarative Filtering**: Built-in predicate support
4. **Performance**: SwiftData optimizes queries automatically
5. **Zero Boilerplate**: One line of code = reactive database access

**Example**:
```swift
@Query(filter: #Predicate<ActiveHabitModel> { $0.isActive == true },
       sort: \ActiveHabitModel.displayOrder)
var habits: [ActiveHabitModel]  // ← Automatically updates!
```

### What @Query Costs You

1. **View-Data Coupling**: View depends directly on SwiftData models
2. **Domain Leakage**: SwiftData types (ActiveHabitModel) in View layer
3. **Testing Complexity**: Need SwiftData test container to test Views
4. **Migration Burden**: Schema changes affect Views directly
5. **Business Logic Bypass**: Temptation to skip UseCases

---

## The Core Tension

### Clean Architecture Principle
> "Business rules should not depend on frameworks. The UI should know nothing about the database."

### @Query Reality
> "I need SwiftData models in the View to get automatic updates."

### The Conflict

**Clean Architecture says**:
```swift
View → ViewModel → UseCase → Repository → DataSource → SwiftData
       (Domain)    (Domain)    (Domain)      (Data)       (Data)
```

**@Query says**:
```swift
View → @Query → SwiftData
     (Data models directly!)
```

These are **fundamentally incompatible** approaches... unless we find a hybrid middle ground.

---

## Hybrid Architecture Options

### Option 1: @Query for Reads, UseCases for Writes

**Concept**: Use `@Query` for automatic UI updates, but route ALL writes through Clean Architecture.

```swift
struct OverviewView: View {
    // READ: Direct SwiftData access via @Query
    @Query(filter: #Predicate<ActiveHabitModel> { $0.isActive == true },
           sort: \ActiveHabitModel.displayOrder)
    var habitModels: [ActiveHabitModel]

    // WRITE: Through ViewModel + UseCases
    @State var vm: OverviewViewModel

    var body: some View {
        ForEach(habitModels) { habitModel in
            let habit = habitModel.toEntity()  // Convert to Domain

            HabitRow(habit: habit) {
                // Write still goes through ViewModel
                Task { await vm.completeHabit(habit) }
            }
        }
    }
}
```

**Pros**:
- ✅ Automatic UI updates (no manual `load()`)
- ✅ Business logic still in UseCases
- ✅ Write operations remain testable
- ✅ Memory leak SOLVED (SwiftData handles updates)

**Cons**:
- ❌ View depends on SwiftData models (coupling)
- ❌ Conversion logic in View (`toEntity()`)
- ❌ Two sources of truth (SwiftData + ViewModel state)
- ❌ Testing Views requires SwiftData container

**Verdict**: Pragmatic, but violates Clean Architecture principles.

---

### Option 2: ViewModel as @Query Wrapper

**Concept**: ViewModel uses `@Query` internally, exposes Domain types externally.

**Problem**: `@Query` is a **property wrapper** that only works in SwiftUI Views or SwiftData-aware contexts. ViewModels don't have access to SwiftData environment.

```swift
// ❌ DOESN'T WORK - @Query requires SwiftData environment
@MainActor @Observable
class OverviewViewModel {
    @Query var habitModels: [ActiveHabitModel]  // ❌ Compiler error!

    var habits: [Habit] {
        habitModels.compactMap { try? $0.toEntity() }
    }
}
```

**Why it fails**:
- `@Query` needs `ModelContainer` from SwiftUI environment
- ViewModels are not Views, don't have SwiftUI environment
- Can't inject `ModelContainer` into ViewModel (defeats purpose)

**Verdict**: Technically impossible without major refactoring.

---

### Option 3: Dual-Layer Views (Adapter Pattern)

**Concept**: Split View into **Data View** (uses @Query) and **Presentation View** (uses Domain types).

```swift
// Data View: Handles SwiftData @Query
struct HabitsDataView: View {
    @Query(filter: #Predicate<ActiveHabitModel> { $0.isActive == true })
    var habitModels: [ActiveHabitModel]

    @State var vm: HabitsViewModel

    var body: some View {
        // Convert SwiftData → Domain at boundary
        let habits = habitModels.compactMap { try? $0.toEntity() }

        HabitsPresentationView(habits: habits, vm: vm)
    }
}

// Presentation View: Pure Domain types
struct HabitsPresentationView: View {
    let habits: [Habit]  // ← Domain entities!
    @State var vm: HabitsViewModel

    var body: some View {
        List(habits) { habit in
            HabitRow(habit: habit) {
                Task { await vm.completeHabit(habit) }
            }
        }
    }
}
```

**Pros**:
- ✅ Automatic updates via @Query
- ✅ Presentation layer uses Domain types
- ✅ Clear boundary between Data and Domain
- ✅ Business logic in UseCases
- ✅ Presentation View is testable (no SwiftData)

**Cons**:
- ⚠️ Extra View layer (more boilerplate)
- ⚠️ Conversion on every render (performance?)
- ⚠️ Data View still coupled to SwiftData

**Verdict**: **Best balance** - preserves Clean Architecture while gaining reactivity.

---

### Option 4: Repository Streams (Reactive Repositories)

**Concept**: Repository exposes `AsyncStream<[Habit]>` instead of one-shot queries. ViewModel observes stream.

```swift
// Repository protocol
protocol HabitRepository {
    func fetchAllHabits() async throws -> [Habit]  // ← One-shot (current)
    func observeHabits() -> AsyncStream<[Habit]>   // ← Stream (new)
}

// Repository implementation
@ModelActor
class HabitLocalDataSource {
    func observeHabits() -> AsyncStream<[Habit]> {
        AsyncStream { continuation in
            // SwiftData doesn't provide native observation at ModelContext level
            // Would need NotificationCenter or custom change tracking
            // This is HARD to implement correctly!
        }
    }
}

// ViewModel
@MainActor @Observable
class HabitsViewModel {
    private(set) var habits: [Habit] = []

    init(habitRepository: HabitRepository) {
        Task {
            for await updatedHabits in habitRepository.observeHabits() {
                self.habits = updatedHabits  // ← Automatic updates!
            }
        }
    }
}
```

**Pros**:
- ✅ Pure Clean Architecture (no SwiftData in View/ViewModel)
- ✅ Automatic updates via streams
- ✅ Fully testable (mock stream in tests)
- ✅ Domain entities throughout

**Cons**:
- ❌ Complex implementation (SwiftData doesn't natively support this)
- ❌ Need change tracking mechanism
- ❌ Performance overhead (constant diffing)
- ❌ Major refactor (weeks of work)

**Verdict**: Architecturally pure, but over-engineered for this problem.

---

### Option 5: Keep Clean Architecture + Optimistic Updates

**Concept**: Current architecture + smart state management (from memory leak analysis).

```swift
@MainActor @Observable
class OverviewViewModel {
    private(set) var habitsData: OverviewData  // Domain types

    // Optimistic update
    func completeHabit(_ habit: Habit) async {
        let log = HabitLog(...)

        // 1. Update UI immediately
        updateUIWithLog(log)  // Modify in-memory state

        // 2. Persist to database
        try await logHabit.execute(log)

        // NO database read! We already know the state.
    }

    // Selective reload
    func goToPreviousDay() {
        viewingDate = previousDay

        if needsReload(for: viewingDate) {
            Task { await loadData() }  // Only if out of range
        } else {
            refreshUIFromCache()       // Reuse existing data
        }
    }
}
```

**Pros**:
- ✅ Pure Clean Architecture (no SwiftData coupling)
- ✅ Solves memory leak (99% fewer reloads)
- ✅ Fully testable
- ✅ Simple to implement (already designed)
- ✅ No framework dependency

**Cons**:
- ⚠️ Not "automatic" (manual state management)
- ⚠️ Need to handle widget/background updates
- ⚠️ Slightly more code than @Query

**Verdict**: **Pragmatic winner** - solves actual problem without sacrificing architecture.

---

## Comparative Analysis

| Approach | Reactivity | Clean Arch | Testing | Complexity | Memory Leak Fix |
|----------|-----------|------------|---------|------------|-----------------|
| **Option 1: @Query for Reads** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ✅ Automatic |
| **Option 2: ViewModel @Query** | N/A | N/A | N/A | N/A | ❌ Not possible |
| **Option 3: Dual-Layer Views** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ Automatic |
| **Option 4: Repository Streams** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | ✅ Via streams |
| **Option 5: Optimistic Updates** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ Manual |

---

## Recommendation: Phased Hybrid Approach

### Phase 1: Fix Memory Leak First (Option 5)
**Why**: Solves immediate critical problem without architectural risk.

**Implementation**:
- Optimistic UI updates for writes
- Selective reloads for navigation
- Keep Clean Architecture intact
- ~99% reduction in database queries

**Timeline**: 1-2 weeks
**Risk**: Low
**Impact**: High (crash prevention)

### Phase 2: Evaluate @Query for Specific Screens (Option 3)
**Why**: Leverage @Query where it provides maximum value with minimum coupling.

**Candidate screens**:
1. **Habits List** - Simple read-heavy screen, perfect for @Query
2. **Category Management** - CRUD operations, good @Query candidate
3. **Settings Profile** - Single entity, minimal complexity

**Implementation** (Dual-Layer Pattern):
```swift
// Data boundary
struct HabitsDataView: View {
    @Query var habitModels: [ActiveHabitModel]
    @State var vm: HabitsViewModel

    var body: some View {
        HabitsPresentationView(
            habits: habitModels.compactMap { try? $0.toEntity() },
            vm: vm
        )
    }
}

// Domain boundary (testable)
struct HabitsPresentationView: View {
    let habits: [Habit]  // Domain types
    @State var vm: HabitsViewModel

    var body: some View {
        // Pure UI logic
    }
}
```

**Timeline**: 2-3 weeks (per screen)
**Risk**: Medium
**Impact**: Medium (improved reactivity for specific screens)

### Phase 3: Consider Repository Streams (Option 4) - IF NEEDED
**Why**: Only if @Query coupling becomes problematic OR you need truly reactive architecture.

**Decision criteria**:
- Multiple screens need reactive updates
- Testing becomes harder with @Query coupling
- Team wants pure Clean Architecture

**Timeline**: 4-6 weeks
**Risk**: High (major refactor)
**Impact**: High (architectural purity)

---

## The Pragmatic Decision Tree

```
┌─────────────────────────────────────────┐
│ Do you need automatic UI updates?       │
└─────────────┬───────────────────────────┘
              │
     ┌────────▼────────┐
     │ YES             │ NO
     │                 │
     ▼                 ▼
┌─────────────┐   ┌──────────────────┐
│ Is the View │   │ Use Option 5:    │
│ complex with│   │ Optimistic       │
│ business    │   │ Updates          │
│ logic?      │   │ (Clean Arch)     │
└──────┬──────┘   └──────────────────┘
       │
  ┌────▼────┐
  │ YES     │ NO
  │         │
  ▼         ▼
┌──────────┐  ┌─────────────────┐
│ Option 3:│  │ Option 1:       │
│ Dual     │  │ Direct @Query   │
│ Layer    │  │ (acceptable     │
│ (best)   │  │ coupling)       │
└──────────┘  └─────────────────┘
```

---

## Concrete Recommendations

### 1. For OverviewViewModel (Complex, Business Logic Heavy)
**Recommendation**: **Option 5 - Optimistic Updates**

**Why**:
- Solves memory leak immediately
- Complex business logic (completion calculations, progress tracking, insights)
- Already designed and documented
- Maintains Clean Architecture for testing
- No new coupling introduced

**DO NOT use @Query** - overhead of conversion and coupling not worth it.

### 2. For HabitsViewModel (Moderate Complexity)
**Recommendation**: **Option 5 initially, Option 3 later if needed**

**Why**:
- Similar to Overview, has business logic (reordering, filtering, completion checks)
- Optimistic updates solve memory leak
- Can evaluate @Query later if reactivity becomes problem
- Keep architecture consistent with Overview

### 3. For CategoryListView (Simple CRUD)
**Recommendation**: **Option 3 - Dual-Layer Views**

**Why**:
- Simple screen, minimal business logic
- Direct @Query benefits outweigh coupling costs
- Good testing ground for hybrid approach
- Category changes are infrequent (less performance concern)

**Example**:
```swift
struct CategoriesDataView: View {
    @Query(sort: \ActiveHabitCategoryModel.name) var categoryModels
    @State var vm: CategoryViewModel

    var body: some View {
        CategoriesPresentationView(
            categories: categoryModels.compactMap { try? $0.toEntity() },
            vm: vm
        )
    }
}
```

### 4. For New Simple Screens
**Recommendation**: **Start with Option 3 by default**

**Why**:
- Best of both worlds for simple cases
- Establishes pattern for future development
- Team learns hybrid approach
- Easy to migrate away if needed

---

## Implementation Guidelines

### Rule 1: Reads vs Writes
- **@Query**: Only for read-heavy screens with simple filtering
- **UseCases**: ALWAYS for writes (Create, Update, Delete)

### Rule 2: Business Logic Location
- **Never in Data Views** - only conversion and @Query
- **Always in UseCases** - completion checks, validation, calculations
- **Presentation Views** - UI logic only (layout, styling, navigation)

### Rule 3: Conversion Boundaries
```swift
// ✅ CORRECT: Convert at View boundary
struct DataView: View {
    @Query var models: [ActiveHabitModel]

    var body: some View {
        let habits = models.compactMap { try? $0.toEntity() }
        PresentationView(habits: habits)
    }
}

// ❌ WRONG: Pass SwiftData models to Presentation
struct DataView: View {
    @Query var models: [ActiveHabitModel]

    var body: some View {
        PresentationView(habitModels: models)  // ❌ Leaks data layer!
    }
}
```

### Rule 4: Testing Strategy
- **Presentation Views**: Unit test with Domain types (no SwiftData)
- **Data Views**: Integration test with test ModelContainer
- **ViewModels**: Unit test with mock Repositories
- **UseCases**: Unit test with mock Repositories

---

## Migration Path

### Immediate (Week 1-2): Fix Memory Leak
```
1. Implement optimistic update helpers in OverviewViewModel
2. Update completeHabit(), updateNumericHabit(), deleteHabitLog()
3. Optimize date navigation (selective reloads)
4. Test with Instruments profiling
5. Verify 99% query reduction
```

### Short Term (Week 3-4): Evaluate @Query
```
1. Create CategoryListDataView with @Query (prototype)
2. Measure performance vs manual load
3. Gather team feedback on dual-layer pattern
4. Document pros/cons from real usage
5. Decide: expand or abandon @Query approach
```

### Long Term (Month 2-3): Scale Decision
```
Option A: @Query worked well
  → Migrate simple CRUD screens to dual-layer
  → Keep complex screens with optimistic updates
  → Document hybrid architecture guidelines

Option B: @Query coupling too costly
  → Stick with optimistic updates everywhere
  → Consider repository streams if reactivity critical
  → Maintain pure Clean Architecture
```

---

## Open Questions for Discussion

1. **Team Skill Level**: Is the team comfortable with hybrid architectures?
2. **Testing Priority**: How important is View testing vs integration testing?
3. **Future Screens**: Will new features be simple CRUD or complex business logic?
4. **Performance Targets**: Is 99% query reduction (optimistic) enough, or need 100% (reactive)?
5. **Maintenance**: Who will maintain dual-layer Views if we go that route?

---

## Conclusion

**The answer to "Can we use @Query with Clean Architecture?"** is **"Yes, but selectively."**

- **✅ Use @Query** for simple, read-heavy screens via dual-layer pattern (Option 3)
- **✅ Use Optimistic Updates** for complex business logic screens (Option 5)
- **❌ Don't force @Query** everywhere - respect architectural boundaries
- **⚠️ Consider Repository Streams** only if @Query coupling becomes unmanageable

**For THIS memory leak problem**: **Option 5 (Optimistic Updates)** is the clear winner.
- Solves immediate crisis
- Maintains architecture
- Simple to implement
- Fully testable
- No new dependencies

**For FUTURE screens**: **Option 3 (Dual-Layer)** is worth exploring for simple cases.
- Good middle ground
- Teaches team hybrid patterns
- Can expand or contract based on results

---

**Status**: Analysis complete, recommendations provided
**Next Action**: Discuss with team, decide on approach, implement Phase 1
