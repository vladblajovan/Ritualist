# Contributing to Ritualist

Thank you for your interest in contributing to Ritualist! This guide will help you get started.

## 📚 Essential Reading

Before contributing, please read:

1. **[README.md](README.md)** - Project overview
2. **[MICRO-CONTEXTS/quick-start.md](MICRO-CONTEXTS/quick-start.md)** - Quick reference (50 tokens)
3. **[docs/ai-collaboration/claude.md](docs/ai-collaboration/claude.md)** - Complete development guide
4. **[docs/ai-collaboration/collaboration-guide.md](docs/ai-collaboration/collaboration-guide.md)** - Collaboration protocol

## 🚀 Getting Started

### Prerequisites

- **Xcode** 15+ (macOS Sonoma+)
- **iOS 17+** deployment target
- **Swift 5.9+**
- **SwiftLint** (`brew install swiftlint`)

### Environment Setup

See [docs/guides/setup/environment-setup.md](docs/guides/setup/environment-setup.md) for detailed setup instructions.

## 🏗️ Architecture

Ritualist follows **Clean Architecture** with strict layer separation:

```
Views → ViewModels → UseCases → Services/Repositories → DataSources
```

**Key Principles:**
- ✅ ViewModels ONLY call UseCases
- ✅ UseCases orchestrate Services and Repositories
- ✅ Services are stateless utilities
- ✅ Repositories delegate to DataSources
- ❌ NO direct Service calls from ViewModels
- ❌ NO business logic in Views

See [docs/architecture/README.md](docs/architecture/README.md) for details.

## 🧪 Testing Strategy

**CRITICAL**: Use real implementations, NOT mocks!

- **Framework**: Swift Testing (iOS 17+)
- **Structure**: Tests in `RitualistTests/` hierarchy
- **Pattern**: AAA (Arrange, Act, Assert)
- **Coverage**: 80%+ business logic, 90%+ Domain layer

See [MICRO-CONTEXTS/testing-strategy.md](MICRO-CONTEXTS/testing-strategy.md) for details.

## 📝 Commit Convention

Follow conventional commits format:

```
feat: Add personality analysis feature
fix: Correct timezone calculation bug
chore: Update dependencies
docs: Improve API documentation
test: Add UseCase test coverage
refactor: Simplify HabitRepository
```

## 🔀 Branch Naming

```
feature/<ticket>-<description>   # feature/RIT-123-add-habit-form
fix/<ticket>-<description>       # fix/RIT-456-timezone-bug
chore/<description>              # chore/update-dependencies
```

## 🎯 Pull Request Process

1. **Create feature branch** from `main`
2. **Implement changes** following architecture guidelines
3. **Add tests** (required for all code changes)
4. **Run SwiftLint** - must pass before PR
5. **Update documentation** if needed
6. **Create PR** with clear description
7. **Address review feedback**
8. **Squash and merge** after approval

### PR Checklist

- [ ] Code follows Clean Architecture principles
- [ ] Tests added and passing
- [ ] SwiftLint violations resolved
- [ ] Documentation updated
- [ ] No architecture violations (check MICRO-CONTEXTS)
- [ ] All 4 build configurations pass (Debug/Release × AllFeatures/Subscription)

## 🚫 Common Mistakes to Avoid

### Architecture Violations

❌ **Direct Service Injection in ViewModels**
```swift
// WRONG
@Injected(\.habitCompletionService) var service
```

✅ **Use UseCases Instead**
```swift
// CORRECT
@Injected(\.isHabitCompleted) var isHabitCompleted
```

### Testing Anti-Patterns

❌ **Mock-heavy tests**
```swift
// WRONG
let mockService = MockHabitService()
mockService.result = expectedValue
```

✅ **Real implementations with test data**
```swift
// CORRECT
let habit = HabitBuilder.binary(name: "Test")
let result = service.calculate(habit, logs: testLogs)
```

## 📚 Documentation

- **Guides**: [docs/guides/](docs/guides/) - How-to tutorials
- **Reference**: [docs/reference/](docs/reference/) - Technical references
- **Architecture**: [docs/architecture/](docs/architecture/) - Design decisions
- **MICRO-CONTEXTS**: Quick reference cards (read first!)

## 🤝 Code Review

All PRs require review. Reviewers will check for:

1. **Architecture compliance** - No layer violations
2. **Test coverage** - Adequate tests included
3. **Code quality** - SwiftLint passing, clean code
4. **Documentation** - Changes documented
5. **Performance** - No N+1 queries, proper threading

## 💬 Getting Help

- **Architecture questions**: See [docs/architecture/](docs/architecture/)
- **Testing questions**: See [MICRO-CONTEXTS/testing-strategy.md](MICRO-CONTEXTS/testing-strategy.md)
- **Build issues**: See [MICRO-CONTEXTS/build.md](MICRO-CONTEXTS/build.md)
- **AI collaboration**: See [docs/ai-collaboration/](docs/ai-collaboration/)

## 📋 Issue Reporting

When reporting issues, please include:

1. **Environment**: iOS version, Xcode version, device
2. **Steps to reproduce**: Clear reproduction steps
3. **Expected behavior**: What should happen
4. **Actual behavior**: What actually happens
5. **Logs/screenshots**: If applicable

## 🎉 Thank You!

Your contributions make Ritualist better for everyone. We appreciate your time and effort!

---

**Questions?** Check the [docs/](docs/) folder or open a discussion.
