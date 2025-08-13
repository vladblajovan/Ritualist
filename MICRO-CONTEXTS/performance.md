# Performance (25 tokens)

**N+1 Fix:** Use `GetBatchHabitLogsUseCase` for multi-habit queries (95% reduction achieved)

**Threading:** `@MainActor @Observable` ViewModels, actor-agnostic services/UseCases run background

**Patterns:** Batch operations, proper @Observable usage, avoid MainActor.run in @MainActor classes