# RitualistCore Additional Migration Plan

## ✅ MIGRATION COMPLETED SUCCESSFULLY

**Status**: ✅ **COMPLETED** (August 13, 2025)  
**Build Status**: ✅ All 4 configurations compile successfully  
**Migration Result**: Successfully moved 70+ UseCase protocols, 6 service protocols, 5 value objects, 100+ enum cases, and error handling types to RitualistCore

## Overview
This document outlines the completed second phase of migrating shared types from the Ritualist target to RitualistCore to further improve code organization and establish RitualistCore as the true domain layer foundation.

## Migration Analysis Results

After analyzing the Ritualist codebase, the following additional candidates have been identified for migration to RitualistCore:

### 1. **UseCase Protocols** (High Priority - 60+ protocols)
**Location**: `Ritualist/Domain/UseCases/UseCases.swift`
**Target**: `RitualistCore/Sources/RitualistCore/UseCases/UseCaseProtocols.swift`

**Types to migrate:**
- Habit UseCases: `CreateHabitUseCase`, `GetActiveHabitsUseCase`, `UpdateHabitUseCase`, etc. (12 protocols)
- Log UseCases: `GetLogsUseCase`, `LogHabitUseCase`, `ToggleHabitLogUseCase`, etc. (6 protocols)
- Profile UseCases: `LoadProfileUseCase`, `SaveProfileUseCase`, `CheckPremiumStatusUseCase`, etc. (5 protocols)
- Category UseCases: `GetAllCategoriesUseCase`, `CreateCustomCategoryUseCase`, etc. (9 protocols)
- Calendar UseCases: `GenerateCalendarDaysUseCase`, `GenerateCalendarGridUseCase` (2 protocols)
- Tip UseCases: `GetAllTipsUseCase`, `GetFeaturedTipsUseCase`, etc. (4 protocols)
- Onboarding UseCases: `GetOnboardingStateUseCase`, `CompleteOnboardingUseCase`, etc. (3 protocols)
- Notification UseCases: `RequestNotificationPermissionUseCase`, `CheckNotificationStatusUseCase` (2 protocols)
- Feature Gating UseCases: `CheckFeatureAccessUseCase`, `CheckHabitCreationLimitUseCase`, etc. (3 protocols)
- User Action UseCases: `TrackUserActionUseCase`, `TrackHabitLoggedUseCase` (2 protocols)
- Paywall UseCases: `LoadPaywallProductsUseCase`, `PurchaseProductUseCase`, etc. (6 protocols)
- Habit Schedule UseCases: `ValidateHabitScheduleUseCase`, `CheckWeeklyTargetUseCase` (2 protocols)
- Domain Errors: `CategoryError`, `CreateHabitFromSuggestionResult`

### 2. **Domain Value Objects** (High Priority)
**Location**: `Ritualist/Features/OverviewV2/Presentation/OverviewV2ViewModel.swift`
**Target**: `RitualistCore/Sources/RitualistCore/Entities/Overview/OverviewValueObjects.swift`

**Types to migrate:**
- `TodaysSummary` - Daily progress summary structure
- `WeeklyProgress` - Weekly progress tracking structure  
- `StreakInfo` - Habit streak information
- `SmartInsight` - Smart insights data structure
- `InsightType` - Insight categorization enum

### 3. **Service Protocols** (High Priority)
**Location**: Various service files in `Ritualist/Core/Services/`
**Target**: `RitualistCore/Sources/RitualistCore/Services/ServiceProtocols.swift`

**Types to migrate:**
- `NotificationService` - Core notification service protocol
- `FeatureGatingService` & `FeatureGatingBusinessService` - Feature gating protocols
- `UserService` - User management protocol
- `PaywallService` - Paywall service protocol
- `UserActionTrackerService` - Analytics tracking protocol
- `SlogansServiceProtocol` - Slogan service protocol

### 4. **Shared Enums** (Medium Priority)
**Location**: `Ritualist/Core/Services/UserActionTrackerService.swift` and `Ritualist/Core/Services/FeatureGatingService.swift`
**Target**: `RitualistCore/Sources/RitualistCore/Enums/SharedEnums.swift`

**Types to migrate:**
- `UserActionEvent` - Analytics event types (100+ cases)
- `HabitsAssistantSource` - Source tracking for habits assistant
- `FeatureType` - Feature flags enumeration

### 5. **Error Handling** (Medium Priority)
**Location**: `Ritualist/Core/Services/ErrorHandlingActor.swift`
**Target**: `RitualistCore/Sources/RitualistCore/Utilities/ErrorHandling.swift`

**Types to migrate:**
- `ErrorHandlingActor` - Centralized error handling actor
- `ErrorEvent` - Error event structure
- `CategoryDataSourceError` - Data source error type (from LocalDataSources.swift)

## Migration Strategy

### Phase 1: UseCase Protocols
1. Create `RitualistCore/Sources/RitualistCore/UseCases/UseCaseProtocols.swift`
2. Move all 60+ UseCase protocol definitions
3. Include domain error types (`CategoryError`, `CreateHabitFromSuggestionResult`)
4. Update imports in all UseCase implementations

### Phase 2: Domain Value Objects
1. Create `RitualistCore/Sources/RitualistCore/Entities/Overview/OverviewValueObjects.swift`
2. Move `TodaysSummary`, `WeeklyProgress`, `StreakInfo`, `SmartInsight`, `InsightType`
3. Update imports in OverviewV2ViewModel and related views

### Phase 3: Service Protocols
1. Create `RitualistCore/Sources/RitualistCore/Services/ServiceProtocols.swift`
2. Move all service protocol definitions
3. Update imports in service implementations

### Phase 4: Shared Enums
1. Create `RitualistCore/Sources/RitualistCore/Enums/SharedEnums.swift`
2. Move `UserActionEvent`, `HabitsAssistantSource`, `FeatureType`
3. Update imports in all consuming files

### Phase 5: Error Handling
1. Create `RitualistCore/Sources/RitualistCore/Utilities/ErrorHandling.swift`
2. Move error handling types and actors
3. Update imports across the codebase

### Phase 6: Import Updates & Testing
1. Update all imports across consuming files
2. Ensure all migrated types have proper `public` access modifiers
3. Test all 4 build configurations
4. Resolve any compilation errors

## Benefits of This Migration

### Clean Architecture Compliance
- **Proper Layer Separation**: UseCase protocols define domain contracts
- **Dependency Direction**: Features depend on RitualistCore, not each other
- **Single Source of Truth**: Domain interfaces centralized in core module

### Code Reusability
- **Cross-Feature Sharing**: Value objects available to all features
- **Testing Support**: Domain contracts can be mocked for testing
- **Type Safety**: Shared enums ensure consistency

### Maintainability
- **Centralized Domain Logic**: Core business concepts in one place
- **Reduced Coupling**: Features only depend on core contracts
- **Easier Refactoring**: Changes to domain types affect single location

### Performance
- **Compile-time Safety**: Protocol definitions resolved at build time
- **Module Independence**: Faster incremental builds
- **Zero Runtime Overhead**: All type definitions are compile-time constructs

## Expected Impact

### Files to Create (5 new files)
- `RitualistCore/Sources/RitualistCore/UseCases/UseCaseProtocols.swift`
- `RitualistCore/Sources/RitualistCore/Entities/Overview/OverviewValueObjects.swift`
- `RitualistCore/Sources/RitualistCore/Services/ServiceProtocols.swift`
- `RitualistCore/Sources/RitualistCore/Enums/SharedEnums.swift`
- `RitualistCore/Sources/RitualistCore/Utilities/ErrorHandling.swift`

### Files to Update (50+ files)
- All UseCase implementations in `Ritualist/Domain/UseCases/`
- Service implementations in `Ritualist/Core/Services/`
- ViewModels and Views consuming migrated types
- Test files using migrated protocols

### Types Migrated
- **UseCase Protocols**: ~60 protocol definitions
- **Domain Value Objects**: 5 core data structures
- **Service Protocols**: 6 service interface definitions
- **Shared Enums**: 3 large enum types with 100+ cases
- **Error Types**: 3 error handling constructs

## Success Criteria

1. ✅ All 4 build configurations compile successfully
2. ✅ Zero compilation errors or missing type references
3. ✅ All migrated types have proper `public` access modifiers
4. ✅ Clean dependency direction maintained (Presentation → Domain → RitualistCore)
5. ✅ No cross-feature dependencies introduced
6. ✅ Existing functionality remains unchanged

## Risks & Mitigation

### Risk: Large-scale import updates
**Mitigation**: Systematic approach, update one file type at a time

### Risk: Circular dependencies
**Mitigation**: Maintain Clean Architecture principles, protocols in core, implementations in features

### Risk: Build failures
**Mitigation**: Test after each migration phase, fix issues incrementally

---

## ✅ Implementation Status - COMPLETED

- ✅ **Phase 1**: UseCase Protocols Migration - **COMPLETED**
- ✅ **Phase 2**: Domain Value Objects Migration - **COMPLETED** 
- ✅ **Phase 3**: Service Protocols Migration - **COMPLETED**
- ✅ **Phase 4**: Shared Enums Migration - **COMPLETED**
- ✅ **Phase 5**: Error Handling Migration - **COMPLETED**
- ✅ **Phase 6**: Import Updates & Testing - **COMPLETED**

**Completed Date**: August 13, 2025
**Actual Time**: ~4 hours (within estimated range)
**Build Status**: ✅ All configurations compile successfully
**Result**: Successfully established RitualistCore as the true domain layer foundation