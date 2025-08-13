# Architecture (30 tokens)

**Flow:** Views → ViewModels → UseCases → Services/Repositories

**Factory DI:** `@Injected(\.serviceName)` for services, `@Injected(\.viewModelName)` OR constructor injection for ViewModels

**Rules:**
- ViewModels: `@MainActor @Observable` 
- UseCases: Actor-agnostic
- NO direct service calls from ViewModels
- Shared UseCases in AppContainer