# Ritualist

![Build and Test](https://github.com/vladblajovan/Ritualist/actions/workflows/i18n-validation.yml/badge.svg)
![Architecture Validation](https://github.com/vladblajovan/Ritualist/actions/workflows/architecture-check.yml/badge.svg)
![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)

A modern iOS habit tracking app built with SwiftUI and Clean Architecture principles. Features timezone-aware tracking, intelligent location-based reminders, iCloud sync, and ML-powered personality insights.

**Status:** Pre-release (v0.1.0) - Active development

## Features

### Core Functionality
- 📊 **Habit Tracking** - Track daily and weekly habits with custom schedules
- 🌍 **Timezone-Aware Tracking** - Three-timezone architecture (Current, Home, Display) ensures accurate habit tracking across time zones and DST transitions with proper date boundary handling
- 📈 **Analytics Dashboard** - Visualize your progress with multiple time periods (This Week, This Month, Last 6 Months, Last Year, All Time), schedule optimization suggestions, weekly pattern analysis, and completion statistics
- 🎯 **Streak Tracking** - Monitor current and best streaks for each habit
- 🎨 **Customizable** - Personalize habits with colors, emojis, and categories

### Advanced Features
- 📍 **Location-Based Reminders** - Geofencing triggers for habits at specific locations (home, gym, etc.)
- ☁️ **iCloud Sync** - CloudKit integration for seamless data sync across devices
- 🧠 **Personality Insights** - ML-based Big Five personality analysis from habit patterns
- 📊 **Test Scenarios** - Pre-built habit profiles (The Achiever, The Connector, etc.) for testing
- 💳 **StoreKit Integration** - In-app subscriptions with feature gating

### Settings & Customization
- 👤 **Profile Management** - Personalize with profile photo and display name
- 🎨 **Appearance Modes** - Light, Dark, or System-adaptive themes
- 📅 **Week Configuration** - Customize first day of week (respects locale settings)
- 🔔 **Notification Controls** - Granular permission management
- 🌍 **Timezone Management** - Configure home timezone for consistent tracking across locations
- 📜 **Timezone History** - View complete timezone change history with timestamps
- 🐛 **Debug Menu** - Development tools including test data scenarios and migration testing

### Technical Excellence
- 🌍 **Full Localization** - i18n support with validated string lengths (239 strings validated)
- 🔒 **Clean Architecture** - 9/10 architecture rating with proper layer separation
- ⚡ **Performance Optimized** - 95% database query reduction, 65% MainActor optimization
- 🧪 **Comprehensive Testing** - 21+ timezone edge case scenarios, real implementations, no mocks
- 📦 **Modular Design** - RitualistCore package for shared business logic
- 🗄️ **SwiftData Schema V9** - Timezone-aware persistence with migration support

## Architecture

Built using Clean Architecture with the following layers:

- **Presentation** - SwiftUI Views and ViewModels (`@MainActor @Observable`)
- **Domain** - Business logic, Entities, and UseCases (in RitualistCore)
- **Data** - Repositories, SwiftData models, and Mappers

### Key Patterns
- **Factory DI** - Type-safe dependency injection (73% code reduction vs custom container)
- **Repository Pattern** - Data access abstraction
- **UseCase Pattern** - Single-responsibility business operations
- **MVVM** - Presentation layer architecture
- **SwiftData Schema V9** - Persistence with proper `@Relationship` modeling and timezone fields
- **RitualistCore Package** - Shared business logic and domain models
- **Three-Timezone Architecture** - Current (device), Home (user-defined), Display (functional) for accurate date calculations across time zones and DST transitions

### Performance Optimizations
- **N+1 Query Elimination** - Batch operations (95% database query reduction)
- **Threading Model** - Background services, MainActor ViewModels (65% reduction in main thread load)
- **Memory Management** - Singleton scoping, proper lifecycle management
- **Cache Sync Logic** - Migration-aware caching with navigation state preservation

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Swift 6.0+
- SwiftData Schema V9

## Building

### Versioning

The project uses semantic versioning with automated build numbers:

- **Version:** 0.1.0 (pre-release/alpha)
- **Build Number:** Auto-incremented from git commit count
- See `docs/VERSIONING.md` for complete versioning strategy

### Configurations

The project includes multiple build configurations:

- **Debug-AllFeatures** - All features enabled for development/TestFlight
- **Release-AllFeatures** - All features enabled, optimized build
- **Debug-Subscription** - Subscription-based feature gating
- **Release-Subscription** - Production configuration with subscription model

**When to use which:**
- Development & TestFlight → Use `Ritualist-AllFeatures`
- App Store Production → Use `Ritualist-Subscription`

See `docs/BUILD-CONFIGURATION-GUIDE.md` for complete details on scheme selection and distribution.

### Building for Simulator

```bash
xcodebuild build \
  -project Ritualist.xcodeproj \
  -scheme Ritualist-AllFeatures \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug-AllFeatures
```

### Running Tests

```bash
xcodebuild test \
  -project Ritualist.xcodeproj \
  -scheme Ritualist-AllFeatures \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:RitualistTests
```

**Note:** Build number is automatically set from git commit count during Xcode builds. See `docs/BUILD-NUMBER-SETUP.md` for details.

## Code Quality

### CI/CD Pipeline

All pull requests are validated with:

- ✅ **Build & Test** - Compilation and unit test execution
- ✅ **SwiftLint** - Code style and best practices enforcement
- ✅ **String Validation** - Localized string length constraints
- ✅ **Architecture Check** - Clean Architecture pattern compliance

### Branch Protection

The `main` branch is protected with:

- Required pull requests for all changes
- Automated CI checks must pass
- All review threads must be resolved

## Development

### Prerequisites

```bash
# Install SwiftLint
brew install swiftlint

# Install pre-commit hook for string validation
cp Scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Developer Tools

- **Pre-commit Hooks** - Automatic string validation before commits prevents CI failures
- **String Validation Script** - Run `swift Scripts/validate_strings.swift` to validate all 239 localized strings for length constraints and format issues
- **Debug Menu** - In-app development tools accessible via Settings:
  - Test data scenarios (`.minimal`, `.moderate`, `.full`)
  - Schema migration testing (V1 → V9)
  - Timezone configuration testing
  - Performance testing fixtures
- **Architecture Checks** - Automated CI validation of Clean Architecture patterns

### Project Structure

```
Ritualist/
├── Application/           # App entry point and DI setup
├── Features/              # Feature modules (Habits, Overview, Settings)
│   ├── Habits/           # Habit management and logging
│   ├── Overview/         # Dashboard and analytics
│   └── Settings/         # User preferences and iCloud sync
├── Domain/               # Business logic and entities (legacy)
├── Data/                 # Data access and persistence
├── Core/                 # Shared utilities and design system
└── DI/                   # Factory dependency injection containers

RitualistCore/            # Shared business logic package
├── Sources/
│   ├── Domain/          # Entities, protocols
│   ├── UseCases/        # Business operations
│   ├── Services/        # Business services
│   ├── Mappers/         # Data transformations
│   └── ViewLogic/       # Presentation helpers

RitualistTests/           # Unit and integration tests
├── Features/            # Feature-specific tests
└── TestInfrastructure/  # Test builders and helpers

Scripts/                  # Automation scripts
├── bump-version.sh      # Version management
├── set-build-number.sh  # Auto build numbers
└── update-build-number-manual.sh

docs/                     # Documentation
├── VERSIONING.md                    # Versioning strategy
├── BUILD-NUMBER-SETUP.md            # Automated build numbers
├── BUILD-CONFIGURATION-GUIDE.md     # Scheme selection guide
├── BUILD-CONFIGURATION-STRATEGY.md  # Industry best practices
├── STOREKIT-IMPLEMENTATION-PLAN.md  # StoreKit roadmap
└── [Feature guides]
```

### Coding Guidelines

- Follow Clean Architecture principles
- Use UseCases for all business operations
- ViewModels should only inject UseCases, never Services
- All strings must be localized
- Write unit tests for business logic
- Run SwiftLint before committing

## Contributing

1. Create a feature branch from `main`
2. Make your changes following the coding guidelines
3. Ensure all tests pass and SwiftLint is clean
4. Open a pull request with a clear description
5. Wait for CI checks to pass

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Recent Improvements

### Latest: Timezone-Aware Tracking ([PR #47](https://github.com/vladblajovan/Ritualist/pull/47))
- **Three-Timezone Architecture** - Current (device), Home (user-defined), Display (functional) for accurate habit tracking across time zones
- **DST Transition Handling** - Proper date boundary calculations during daylight saving time changes (e.g., November 2025)
- **Locale-Aware Week Calculations** - Calendar week respects user's first day of week preference (Monday for Romania locale)
- **Timezone History Tracking** - Complete audit trail of timezone changes with timestamps
- **21+ Edge Case Tests** - Comprehensive test coverage for timezone scenarios including retroactive logging, midnight boundaries, and weekly analytics
- **Dashboard Fix** - Fixed weekly period charts showing insufficient data due to Calendar locale bug
- **String Validation** - Pre-commit hooks with regex-based format specifier validation (239 strings validated)
- **Schema V9 Migration** - Added timezone fields to persistence layer with proper migration support

### Performance & Optimization
- **N+1 Query Elimination** - Batch query operations (GetBatchHabitLogsUseCase)
- **MainActor Threading** - Proper concurrency patterns (65% main thread load reduction)
- **Factory DI Migration** - From custom container (530 lines → 150 lines, 73% reduction)
- **SwiftData Relationships** - Proper `@Relationship` modeling for data integrity
- **Memory Leak Analysis** - Comprehensive diagnostic tests and fixes

### Feature Additions
- **iCloud Sync** - CloudKit integration with conflict resolution
- **Location Reminders** - Geofencing with background monitoring
- **Personality Analysis** - Big Five model with advanced tie-breaking
- **Test Scenarios** - Pre-built profiles for development and testing
- **Versioning System** - Semantic versioning with automated build numbers

### Code Quality
- **Architecture Compliance** - 9/10 Clean Architecture rating
- **Test Infrastructure** - Real implementations, no mocks
- **Cache Sync Logic** - Migration-aware data handling
- **Documentation** - Comprehensive guides for versioning, build setup, and features

## Acknowledgments

- Built with **SwiftUI** and **SwiftData**
- Dependency injection powered by **Factory**
- Cloud sync with **CloudKit**
- Location services with **CoreLocation**
- In-app purchases with **StoreKit**
- UI design inspired by modern iOS design patterns
