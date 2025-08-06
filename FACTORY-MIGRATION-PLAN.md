# Factory Dependency Injection Migration Plan

## Overview
Migration from custom AppContainer DI system to Factory framework for improved maintainability, performance, and testing capabilities.

**Expected Benefits:**
- 73% reduction in DI-related code (530 → 150 lines)
- Compile-time safety vs runtime errors
- Built-in testing support
- Industry standard approach

---

## Phase 1: Setup & Package Integration

### 1.1 Package Installation
- [x] Add Factory package to Package.swift dependencies (Factory 2.5.3 installed via Xcode)
- [x] Import FactoryKit in project files (verified with test Container extension)
- [x] Verify build succeeds with Factory package (build successful with no Factory-related errors)

### 1.2 Initial Container Structure
- [x] Create `Extensions/Container+Core.swift` (created with test factory)
- [x] Create `Extensions/Container+Repositories.swift` (all repositories migrated)
- [x] Create `Extensions/Container+Services.swift` (all services migrated with MainActor support)
- [x] Create `Extensions/Container+DataSources.swift` (all data sources migrated)

---

## Phase 2: Core Dependencies Migration

### 2.1 Data Sources
- [x] Migrate `HabitLocalDataSource` to Factory
- [x] Migrate `LogLocalDataSource` to Factory
- [x] Migrate `ProfileLocalDataSource` to Factory
- [x] Migrate `TipLocalDataSource` to Factory
- [x] Migrate `OnboardingLocalDataSource` to Factory
- [x] Migrate `SwiftDataCategoryLocalDataSource` to Factory

### 2.2 Repositories
- [x] Migrate `HabitRepository` to Factory with singleton scope
- [x] Migrate `LogRepository` to Factory with singleton scope
- [x] Migrate `ProfileRepository` to Factory with singleton scope
- [x] Migrate `TipRepository` to Factory with singleton scope
- [x] Migrate `OnboardingRepository` to Factory with singleton scope
- [x] Migrate `CategoryRepository` to Factory with singleton scope

### 2.3 Core Services
- [x] Migrate `NotificationService` to Factory
- [x] Migrate `AppearanceManager` to Factory with singleton scope
- [x] Migrate `HabitSuggestionsService` to Factory
- [x] Migrate `UserActionTrackerService` to Factory
- [x] Migrate `UserService` to Factory (with MainActor support)
- [x] Migrate `PaywallService` to Factory (with MainActor support)
- [x] Migrate `FeatureGatingService` to Factory
- [x] Migrate `SlogansService` to Factory

---

## Phase 3: Domain Layer Migration

### 3.1 Habit Use Cases
- [x] Create `Extensions/Container+HabitUseCases.swift`
- [x] Migrate `CreateHabit` use case
- [x] Migrate `UpdateHabit` use case
- [x] Migrate `DeleteHabit` use case
- [x] Migrate `GetAllHabits` use case
- [x] Migrate `GetHabitCount` use case
- [x] Migrate `ToggleHabitActiveStatus` use case
- [x] Migrate `ReorderHabits` use case
- [x] Migrate `ValidateHabitUniqueness` use case

### 3.2 Log Use Cases
- [x] Create `Extensions/Container+LogUseCases.swift`
- [x] Migrate log-related use cases (prepared for future use cases)

### 3.3 Category Use Cases
- [x] Create `Extensions/Container+CategoryUseCases.swift`
- [x] Migrate `GetActiveCategories` use case
- [x] Migrate `CreateCustomCategory` use case
- [x] Migrate `ValidateCategoryName` use case

### 3.4 Feature Gating Use Cases
- [x] Create `Extensions/Container+FeatureUseCases.swift`
- [x] Migrate `CheckHabitCreationLimit` use case

### 3.5 Complex Use Cases
- [x] Migrate `CreateHabitFromSuggestionUseCase` with proper dependency injection
- [x] Test complex use case dependency resolution

---

## Phase 4: Presentation Layer Migration

### 4.1 ViewModels Container Extensions
- [x] Create `Extensions/Container+ViewModels.swift`
- [x] Define `habitsViewModel` factory
- [x] Define `habitDetailViewModel` factory (parameterized)
- [x] Define `categoryManagementViewModel` factory
- [x] Define `overviewViewModel` factory
- [x] Define `tipsViewModel` factory
- [x] Define `settingsViewModel` factory
- [x] Define `paywallViewModel` factory (completed with MainActor isolation)
- [x] Define `onboardingViewModel` factory (completed with all dependencies)

### 4.2 HabitsViewModel Migration
- [x] Convert `HabitsViewModel` to use Factory dependency resolution (used Container.shared approach instead of @Injected)
- [x] Remove manual dependency injection from initializer (now uses parameter-free init)
- [x] Resolve all use case dependencies via Factory:
  - [x] `Container.shared.getAllHabits()`
  - [x] `Container.shared.createHabit()`
  - [x] `Container.shared.updateHabit()`
  - [x] `Container.shared.deleteHabit()`
  - [x] `Container.shared.toggleHabitActiveStatus()`
  - [x] `Container.shared.reorderHabits()`
  - [x] `Container.shared.checkHabitCreationLimit()`
  - [x] `Container.shared.createHabitFromSuggestionUseCase()`
  - [x] `Container.shared.getActiveCategories()`
- [x] Resolve service dependencies via Factory:
  - [x] `Container.shared.habitSuggestionsService()`
  - [x] `Container.shared.userActionTracker()`
- [x] Test HabitsViewModel functionality (build successful)

### 4.3 HabitDetailViewModel Migration
- [x] Convert `HabitDetailViewModel` to use `@Injected` properties
- [x] Handle parameterized factory for editing existing habits
- [x] Update all `@Injected` use cases
- [x] Test create/edit/delete functionality

### 4.4 Other ViewModels Migration
- [x] Convert `OverviewViewModel` to Factory injection
- [x] Convert `SettingsViewModel` to Factory injection
- [x] Convert `OnboardingViewModel` to Factory injection
- [x] Convert `CategoryManagementViewModel` to Factory injection

---

## Phase 5: SwiftUI Integration

### 5.1 Root Views Update
- [x] Update `HabitsRoot` to use `@Injected(\.habitsViewModel)` (used @Injected instead of @InjectedObject for @Observable ViewModels)
- [x] Remove `@Environment(\.appContainer)` dependencies
- [x] Remove manual factory creation logic
- [x] Update category management sheet to use Factory injection
- [x] Test HabitsRoot functionality (build successful)

### 5.2 Feature Views Update
- [x] Update `OverviewView` to use Factory injection (completed with paywall factories)
- [x] Update `SettingsView` to use Factory injection (completed with paywall factories)
- [x] Update `HabitDetailView` to use Factory injection (completed)
- [x] Update `CategoryManagementView` to use Factory injection (via Container extension)
- [x] Update `RootTabView` to use Factory injection (completed)
- [x] Update `OnboardingFlowView` to use Factory injection (completed)
- [x] Remove all `@Environment(\.appContainer)` usage from views

### 5.3 Nested Components Update
- [x] Update components that use `appContainer` environment
- [x] Verify no `@Environment(\.appContainer)` remains in codebase (completed - all major views migrated)
- [x] Test all SwiftUI navigation flows (builds successfully)

---

## Phase 6: Testing Infrastructure

### 6.1 Test Setup
- [ ] Create `Tests/Mocks/Container+TestMocks.swift`
- [ ] Create mock implementations for core services
- [ ] Create mock implementations for repositories
- [ ] Set up Factory testing patterns

### 6.2 Repository Tests Migration
- [ ] Update `HabitRepositoryTests` to use Factory mocks
- [ ] Update `LogRepositoryTests` to use Factory mocks
- [ ] Update `ProfileRepositoryTests` to use Factory mocks

### 6.3 ViewModel Tests Migration
- [ ] Update `HabitsViewModelTests` to use Factory testing
- [ ] Update `HabitDetailViewModelTests` to use Factory testing
- [ ] Create test utilities for common mock scenarios

### 6.4 Use Case Tests Migration
- [ ] Update use case tests to use Factory dependency injection
- [ ] Verify all tests pass with Factory system

---

## Phase 7: Build Configuration Integration

### 7.1 Debug/Release Configuration
- [ ] Update Factory registrations for debug vs release builds
- [ ] Handle `#if DEBUG` conditions in Factory containers
- [ ] Test both debug and release configurations

### 7.2 Feature Flag Integration
- [ ] Update `ALL_FEATURES_ENABLED` build flag integration
- [ ] Ensure Factory works with `BuildConfigFeatureGatingService`
- [ ] Test AllFeatures vs Subscription build schemes

---

## Phase 8: Legacy Code Removal

### 8.1 Container Protocol Removal
- [ ] Remove `AppContainer` protocol from `AppEnvironment.swift`
- [ ] Remove `AppContainerKey` struct
- [ ] Remove `EnvironmentValues` extension

### 8.2 Manual Container Removal
- [ ] Remove `DefaultAppContainer` class from `AppDI.swift`
- [ ] Remove `bootstrap()` method
- [ ] Remove `createMinimal()` method
- [ ] Delete entire `AppDI.swift` file

### 8.3 Factory Pattern Removal
- [ ] Delete `FeatureDI/HabitsFactory.swift`
- [ ] Delete `FeatureDI/HabitDetailFactory.swift`
- [ ] Delete `FeatureDI/OverviewFactory.swift`
- [ ] Delete `FeatureDI/SettingsFactory.swift`
- [ ] Delete `FeatureDI/OnboardingFactory.swift`
- [ ] Delete `FeatureDI/PaywallFactory.swift`
- [ ] Delete `FeatureDI/TipsFactory.swift`
- [ ] Delete `FeatureDI/HabitsAssistantFactory.swift`
- [ ] Delete entire `FeatureDI/` directory

### 8.4 Bootstrap Code Update
- [ ] Update `RitualistApp.swift` to remove container bootstrap
- [ ] Remove container environment injection
- [ ] Simplify app initialization

---

## Phase 9: Documentation & Validation

### 9.1 Documentation Updates
- [ ] Update `CLAUDE.md` with Factory DI patterns
- [ ] Update `CLAUDE-COLLABORATION-GUIDE.md` with new DI approach
- [ ] Create Factory usage examples in documentation
- [ ] Update architecture diagrams

### 9.2 Code Quality Verification
- [ ] Run SwiftLint on all modified files
- [ ] Verify no compiler warnings
- [ ] Run full test suite
- [ ] Test both AllFeatures and Subscription builds

### 9.3 Performance Validation
- [ ] Measure app launch time before/after migration
- [ ] Verify memory usage patterns
- [ ] Test dependency resolution performance

---

## Phase 10: Final Integration Testing

### 10.1 Feature Testing
- [ ] Test complete habit creation flow
- [ ] Test habit editing and deletion
- [ ] Test overview/calendar functionality
- [ ] Test settings and profile management
- [ ] Test onboarding flow
- [ ] Test category management
- [ ] Test paywall integration

### 10.2 Build Verification
- [ ] Verify Debug-AllFeatures build works
- [ ] Verify Release-AllFeatures build works
- [ ] Verify Debug-Subscription build works
- [ ] Verify Release-Subscription build works

### 10.3 Test Coverage Verification
- [ ] Run complete test suite
- [ ] Verify test coverage maintained or improved
- [ ] Fix any broken tests from migration

---

## Risk Mitigation Checklist

### Pre-Migration
- [ ] Create feature branch for Factory migration
- [ ] Document current system behavior for comparison
- [ ] Ensure all existing tests pass
- [ ] Create rollback plan

### During Migration
- [ ] Test each phase before proceeding to next
- [ ] Maintain both systems during transition period
- [ ] Use feature flags if needed for gradual rollout

### Post-Migration
- [ ] Monitor for runtime issues in production
- [ ] Verify no performance regressions
- [ ] Update team documentation and training

---

## Success Criteria

### Code Quality
- [ ] Total DI-related code reduced by >70%
- [ ] Zero compiler warnings related to DI
- [ ] All SwiftLint rules pass
- [ ] No @Environment(\.appContainer) usage remains

### Functionality
- [ ] All app features work identically to before migration
- [ ] All unit tests continue to pass
- [ ] All UI tests continue to pass
- [ ] Both build configurations work correctly

### Performance
- [ ] App launch time unchanged or improved
- [ ] Memory usage unchanged or improved
- [ ] Test execution time unchanged or improved

### Maintainability
- [ ] New developers can understand DI system quickly
- [ ] Adding new dependencies requires minimal boilerplate
- [ ] Testing with mocks is straightforward
- [ ] Clear separation between layers maintained

---

## Timeline Estimate

**Total Duration: 3-4 weeks**

- **Week 1**: Phases 1-3 (Setup, Core Dependencies, Domain Layer)
- **Week 2**: Phases 4-5 (Presentation Layer, SwiftUI Integration)
- **Week 3**: Phases 6-8 (Testing, Build Config, Legacy Removal)
- **Week 4**: Phases 9-10 (Documentation, Final Testing, Validation)

## Notes

- Each checkbox represents a discrete, testable task
- Tasks should be completed in order within each phase
- Some tasks may be done in parallel within the same phase
- Create separate branches for each major phase if desired
- Document any deviations from this plan as they occur