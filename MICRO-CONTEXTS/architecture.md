# Architecture (40 tokens)

**Flow:** Views → ViewModels → UseCases → [Services + Repositories]

**Factory DI:** 
- ViewModels: `@Injected(\.useCaseName)` ONLY (never inject Services)
- UseCases: Constructor injection with Services/Repositories

**Rules:**
- ViewModels: `@MainActor @Observable`, call ONLY UseCases
- UseCases: Actor-agnostic, orchestrate Services/Repositories
- Services: Stateless utilities used BY UseCases
- NO direct service calls from ViewModels
- Shared UseCases in AppContainer