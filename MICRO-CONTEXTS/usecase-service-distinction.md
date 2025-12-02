# UseCase vs Service Distinction (150 tokens)

## The Key Test

- **UseCase** = *"Do this business operation"* (verb + noun pattern)
- **Service** = *"Manage this capability/state"* (noun + Service/Manager)

## UseCases (Application Layer)

- Single business operation (CompleteHabitUseCase, GetWeeklyProgressUseCase)
- Orchestrates Services & Repositories
- Protocol-based from RitualistCore
- ViewModels call via `@Injected(\.useCaseName)`

## Services: Two Categories

### 1. Business Services (Domain Logic)

- Reusable calculations/utilities (HabitCompletionCalculator, NotificationScheduler)
- **Called BY UseCases, NEVER by ViewModels directly**
- Stateless, focused on specific domain logic

**❌ WRONG:** ViewModel → @Injected(\.businessService) → Repository
**✅ CORRECT:** ViewModel → @Injected(\.useCase) → [Service + Repository]

### 2. Infrastructure/UI Services (Cross-Cutting Concerns)

These services **CAN be injected directly into ViewModels**:

| Service Type | Examples | Rationale |
|--------------|----------|-----------|
| UI Presentation | `ToastService`, `AppearanceManager` | UI coordination, not business logic |
| Stateful Singletons | `SubscriptionService`, `PaywallService` | State management needed for coordination |
| Infrastructure | `DebugLogger`, `UserActionTracker` | Cross-cutting observability concerns |

**✅ ALLOWED:** ViewModel → @Injected(\.toastService) → show toast
**✅ ALLOWED:** ViewModel → @Injected(\.debugLogger) → log event

## When to Create Each

| Create a... | When... |
|-------------|---------|
| **UseCase** | Single-responsibility business operation that may need testing/mocking |
| **Business Service** | Reusable domain logic that multiple UseCases need |
| **Infrastructure Service** | Cross-cutting concern (logging, toasts, analytics, appearance) |

## Detect Business Service Violations

```bash
# Check for business services in ViewModels (should be empty or only infrastructure services)
grep -r "@Injected.*Service" Ritualist/Features/*/Presentation/ --include="*ViewModel.swift"
```

**Allowed matches:** `toastService`, `subscriptionService`, `paywallService`, `debugLogger`, `userActionTracker`
**Violations:** Any business/domain service (e.g., `habitAnalyticsService`, `notificationScheduler`)

---

## ✅ **PHASE 2 SERVICE CLEANUP COMPLETED (27.08.2025)**

**Services Refactored to Utility-Only:**
- `PersonalityAnalysisService` - Only calculation methods (calculatePersonalityScores, determineDominantTrait)
- `HabitAnalyticsService` - Only getSingleHabitLogs() utility method
- `TestDataPopulationService` - Only data generation utilities (getCustomCategoryData, getCustomHabitData)

**Business Logic Moved to UseCases:**
- `AnalyzePersonalityUseCase` - Full personality analysis workflow
- `PopulateTestDataUseCase` - Complete test data population orchestration
- `UpdatePersonalityAnalysisUseCase` - Profile refresh and regeneration logic

**Dashboard UseCases Fixed:**
- `AggregateCategoryPerformanceUseCase` - Uses GetActiveHabitsUseCase + GetHabitLogsForAnalyticsUseCase
- `AnalyzeWeeklyPatternsUseCase` - Uses UseCase dependencies instead of Service methods
- `CalculateHabitPerformanceUseCase` - Uses GetActiveHabitsUseCase + GetHabitLogsUseCase
- `GenerateProgressChartDataUseCase` - Uses GetHabitCompletionStatsUseCase

**Architecture Boundaries Enforced:**
- ❌ No ViewModels inject **business** Services directly
- ✅ ViewModels MAY inject **infrastructure/UI** Services directly
- ✅ All business operations go through UseCases
- ✅ Business Services contain ONLY utility functions and calculations
- ✅ UseCases orchestrate business workflows using Services + Repositories
