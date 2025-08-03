# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 📋 COLLABORATION GUIDE
**CRITICAL**: Always reference `CLAUDE-COLLABORATION-GUIDE.md` before starting any work. This guide contains the interaction protocol, quality gates, and learning procedures that must be followed for effective collaboration.

## 🧪 TESTING STRATEGY
**IMPORTANT**: All code changes must include proper unit tests. Reference `TESTING-STRATEGY.md` for comprehensive testing guidelines, patterns, and requirements. Never create standalone test files - always use the proper RitualistTests/ structure.

## 🚨 CRITICAL DEVELOPMENT REMINDERS 🚨

**ALWAYS FOLLOW THESE PRINCIPLES:**
- **Clean Architecture**: Views → ViewModels → UseCases → Services/Repositories
- **Separation of Concerns**: No direct service calls from Views or ViewModels
- **UseCase Pattern**: Every business operation must go through a UseCase
- **Build Standard**: ALWAYS test using iPhone 16, iOS 18.5 simulator
- **Repository Pattern**: Views NEVER call repositories directly - use UseCases

**ARCHITECTURAL VIOLATIONS TO AVOID:**
- ❌ Direct service calls from ViewModels (use UseCases)
- ❌ Repository calls from Views (use UseCases) 
- ❌ Business logic in Views (move to UseCases)
- ❌ Multiple service dependencies in ViewModels (compose via UseCases)

## Project Overview

Ritualist is an iOS habit tracking app built with SwiftUI, targeting iOS 17+. The app follows Clean Architecture principles with feature-first organization and uses SwiftData for persistence.

## Development Commands

### Building and Running
- **Build**: Open `Ritualist.xcodeproj` in Xcode and build (⌘+B)
- **Run**: Select a target device/simulator and run (⌘+R)
- **Run Tests**: ⌘+U for all tests, or ⌘+Control+U for current test

### Code Quality
- **SwiftLint**: Run `swiftlint` from repo root (requires `brew install swiftlint`)
- **SwiftLint config**: Located at `Ritualist/.swiftlint.yml`
- **SwiftLint in Xcode**: Integrated as build phase - violations appear as warnings/errors

### Testing
- **Unit Tests**: Located in `RitualistTests/` - test domain logic and repositories
- **UI Tests**: Located in `RitualistUITests/` - test core user flows
- **Single Test**: Right-click specific test method and "Run Test"

## Architecture

### Clean Architecture Layers
```
Ritualist/
├── Application/           # App entry point, DI setup, root navigation
├── Features/             # Feature modules (Habits, Overview, Settings)
│   └── [Feature]/
│       └── Presentation/ # Views and ViewModels
├── Domain/              # Business logic layer
│   ├── Entities/        # Core business models
│   ├── Repositories/    # Repository protocols
│   └── UseCases/       # Business use cases
├── Data/               # Data access layer
│   ├── Models/         # SwiftData models
│   ├── DataSources/    # Local data sources
│   ├── Mappers/        # Entity ↔ Model mappers
│   └── Repositories/   # Repository implementations
└── Core/               # Shared utilities and services
    ├── DesignSystem/   # UI tokens, components
    ├── Services/       # Date, notifications, streak logic
    ├── Storage/        # SwiftData stack
    └── Utilities/      # Helper functions
```

### Dependency Injection
- Uses protocol-based DI with `AppContainer`
- Bootstrap in `AppDI.swift` - creates all dependencies
- Access via SwiftUI Environment: `@Environment(\.appContainer) private var di`
- Feature factories in `FeatureDI/` for ViewModels

### Key Domain Entities
- **Habit**: Core entity with schedule, reminders, tracking type (binary/numeric)
- **HabitLog**: Daily tracking entries with optional numeric values
- **UserProfile**: User settings including appearance and week start day

### Data Flow
1. **SwiftUI Views** → ViewModels (via DI factories)
2. **ViewModels** → UseCases → Repositories (protocols)
3. **Repository Impls** → DataSources → SwiftData models
4. **Mappers** convert between Domain entities and Data models

## Code Conventions

- **Language**: Swift 5.9+, iOS 17.6 minimum deployment
- **Style**: Follow SwiftLint rules - max 130 char lines, explicit init preferred
- **Architecture**: Feature-first folders, Clean Architecture separation
- **Branching**: `feature/<ticket>-<desc>` (e.g., `feature/RIT-0402-add-habit-form`)
- **Commits**: Conventional format preferred (`feat:`, `fix:`, `chore:`, etc.)

## Important Files

- `RitualistApp.swift`: App entry point with DI bootstrap
- `Application/AppDI.swift`: Main dependency injection container
- `Application/RootTabView.swift`: Root navigation structure
- `Domain/Entities/Entities.swift`: Core business models
- `.swiftlint.yml`: SwiftLint configuration (in Ritualist/ subdirectory)
- `CONTRIBUTING.md`: Full development workflow and PR checklist

## Testing Strategy

- **Domain Layer**: Unit test entities, use cases, repository logic
- **Data Layer**: Test data sources, mappers, SwiftData integration
- **Presentation**: UI tests for habit creation, logging, streak viewing
- **Accessibility**: VoiceOver labels, Dynamic Type support (up to AX5)

## Common Development Tasks

When adding new features:
1. Start with Domain entities and repository protocols
2. Add Data models and repository implementations
3. Create UseCases for business logic
4. Build Presentation layer (View + ViewModel)
5. Wire up in FeatureDI factory
6. Add comprehensive tests

Always run SwiftLint before committing - the build phase will show violations in Xcode.

## Build Configuration System

The app uses a sophisticated build-time configuration system for subscription management:

### Build Configurations:
- **Debug-AllFeatures / Release-AllFeatures**: All premium features enabled (TestFlight/launch)
- **Debug-Subscription / Release-Subscription**: Subscription-based feature gating (production)

### Compiler Flags:
- `ALL_FEATURES_ENABLED`: Grants all premium features regardless of subscription
- `SUBSCRIPTION_ENABLED`: Enforces subscription-based feature gating

### Architecture Integration:
- **FeatureGatingService**: Respects build configuration automatically
- **Build-time validation**: Compile errors prevent invalid flag combinations
- **Clean boundaries**: UI layer unaware of build config - uses service layer

### Usage:
```swift
// ✅ Correct - Service layer handles build config
vm.hasAdvancedAnalytics  // Automatically respects build flags

// ❌ Wrong - Never put build checks in views
#if ALL_FEATURES_ENABLED
// View logic here
#endif
```

## Architecture Decisions Log

### Recent Decisions (August 2025):

1. **Build Configuration Strategy**
   - **Decision**: Explicit dual boolean flags with compile-time validation
   - **Rationale**: Prevents configuration errors, enables TestFlight→AppStore workflow
   - **Implementation**: `BuildConfigurationService` with `#error` validation

2. **Feature Gating Architecture**
   - **Decision**: Service layer handles all build config logic, not views
   - **Rationale**: Maintains clean architecture, easier testing, single responsibility
   - **Implementation**: `BuildConfigFeatureGatingService` wraps standard service

3. **Subscription Testing Strategy**
   - **Decision**: AllFeatures build for TestFlight, Subscription build for App Store
   - **Rationale**: Beta users test full experience, production has revenue model
   - **Implementation**: Scheme-based switching, zero code changes needed

## Established Code Patterns

### Feature Creation Workflow:
1. **Domain First**: Define entities, repository protocols, use cases
2. **Data Layer**: Implement repositories, data sources, mappers
3. **Presentation**: Create ViewModels that use UseCases, then Views
4. **Dependency Injection**: Wire up in appropriate FeatureDI factory
5. **Testing**: Unit tests for domain, UI tests for flows

### Build Configuration Integration:
```swift
// ✅ Service layer pattern (correct)
public var hasAdvancedAnalytics: Bool {
    #if ALL_FEATURES_ENABLED
    return true
    #else
    return standardFeatureGating.hasAdvancedAnalytics
    #endif
}

// ✅ ViewModel pattern (correct)
vm.hasAdvancedAnalytics  // Uses service layer

// ❌ View pattern (avoid)
#if ALL_FEATURES_ENABLED
// UI logic
#endif
```

## Anti-Patterns to Avoid

### Build Configuration Anti-Patterns:
- ❌ **Build checks in views**: Use service layer instead
- ❌ **Implicit configuration**: Always require explicit flags
- ❌ **Mixed build logic**: Keep build config in dedicated services

### Architecture Anti-Patterns:
- ❌ **Direct service calls from ViewModels**: Use UseCases
- ❌ **Repository calls from Views**: Use UseCases → Repositories
- ❌ **Business logic in Views**: Move to UseCases
- ❌ **Multiple service dependencies**: Compose via UseCases

## Performance Considerations

- **Build-time decisions**: Zero runtime overhead for feature flagging
- **SwiftData optimization**: Use appropriate fetch descriptors and sorting
- **UI performance**: Minimize re-renders with proper @Observable usage

## External Integration Guidelines

- **Build tools**: All configurations must build successfully before merge
- **TestFlight**: Use AllFeatures configuration for beta testing
- **App Store**: Use Subscription configuration for production releases