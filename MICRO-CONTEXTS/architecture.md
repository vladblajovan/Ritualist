# Architecture (60 tokens)

**Flow:** Views → ViewModels → UseCases → [Services + Repositories]

**Factory DI:**
- ViewModels: `@Injected(\.useCaseName)` for business operations
- ViewModels: `@Injected(\.infrastructureService)` allowed for UI/cross-cutting concerns
- UseCases: Constructor injection with Services/Repositories

**Rules:**
- ViewModels: `@MainActor @Observable`, call UseCases for business logic
- UseCases: Actor-agnostic, orchestrate Services/Repositories
- Business Services: Stateless utilities used BY UseCases only
- Infrastructure Services: Can be injected directly (ToastService, DebugLogger, etc.)
- Shared UseCases in AppContainer

**See:** `usecase-service-distinction.md` for detailed guidelines on when to use each pattern.
