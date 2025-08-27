# UseCase vs Service Distinction (90 tokens)

**UseCases (Application Layer):**
- Single business operation (CompleteHabitUseCase, GetWeeklyProgressUseCase)
- Orchestrates Services & Repositories
- ViewModels ONLY call UseCases via @Injected(\.useCaseName)
- Protocol-based from RitualistCore

**Services (Domain/Infrastructure):**
- Reusable calculations/utilities (HabitCompletionCalculator, NotificationScheduler)
- Called BY UseCases, NEVER by ViewModels directly
- Stateless, focused on specific domain logic

**❌ WRONG:** ViewModel → @Injected(\.service) → Repository
**✅ CORRECT:** ViewModel → @Injected(\.useCase) → [Service + Repository]

**Detect violations:**
```bash
grep -r "@Injected.*Service" Ritualist/Features/*/Presentation/ --include="*ViewModel.swift"
```

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
- ❌ No ViewModels inject business Services directly
- ✅ All business operations go through UseCases  
- ✅ Services contain ONLY utility functions and calculations
- ✅ UseCases orchestrate business workflows using Services + Repositories