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