# Architecture

Architecture decisions, analysis, and technical design documentation.

## 📁 Categories

### [Decisions](decisions/)
Architecture Decision Records (ADRs) documenting key technical decisions:
- Factory DI adoption
- SwiftData relationships
- Build configuration strategy

### [Analysis](analysis/)
In-depth architecture analysis:
- Clean Architecture implementation
- Threading model (@MainActor strategy)
- Data persistence patterns

---

## 🎯 Architecture Principles

Ritualist follows **Clean Architecture** with clear layer separation:
```
Views → ViewModels → UseCases → Services/Repositories → DataSources
```

Key patterns:
- ✅ Factory-based dependency injection
- ✅ SwiftData for persistence
- ✅ Actor-based concurrency (@MainActor ViewModels)
- ✅ Feature-first organization

---

[← Back to Documentation](../README.md)
