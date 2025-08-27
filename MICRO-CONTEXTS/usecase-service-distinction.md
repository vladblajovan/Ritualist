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

## ✅ **NEW USECASES CREATED (27.08.2025)**

**Habit Completion UseCases:**
- `IsHabitCompletedUseCase` - Replaces habitCompletionService.isCompleted()
- `CalculateDailyProgressUseCase` - Replaces habitCompletionService.calculateDailyProgress()
- `IsScheduledDayUseCase` - Replaces habitCompletionService.isScheduledDay()

**Analytics UseCases:**
- `GetActiveHabitsUseCase` - Replaces habitAnalyticsService.getActiveHabits()
- `CalculateStreakAnalysisUseCase` - Replaces performanceAnalysisService.calculateStreakAnalysis()

**Utility UseCases:**
- `GetCurrentSloganUseCase` - Replaces slogansService.getCurrentSlogan()
- `ClearPurchasesUseCase` - Replaces paywallService.clearPurchases()
- `PopulateTestDataUseCase` - Replaces testDataPopulationService calls