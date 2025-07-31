# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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