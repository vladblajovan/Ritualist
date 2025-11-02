# Ritualist

![Build and Test](https://github.com/vladblajovan/Ritualist/actions/workflows/i18n-validation.yml/badge.svg)
![Architecture Validation](https://github.com/vladblajovan/Ritualist/actions/workflows/architecture-check.yml/badge.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A modern iOS habit tracking app built with SwiftUI and Clean Architecture principles.

## Features

- 📊 **Habit Tracking** - Track daily and weekly habits with custom schedules
- 📈 **Analytics Dashboard** - Visualize your progress with completion statistics
- 🎯 **Streak Tracking** - Monitor current and best streaks for each habit
- 🎨 **Customizable** - Personalize habits with colors, emojis, and categories
- 🧠 **Personality Insights** - ML-based personality analysis from habit patterns
- 🌍 **Localization Ready** - Full i18n support with validated string lengths
- 🔒 **Clean Architecture** - Maintainable codebase with proper layer separation

## Architecture

Built using Clean Architecture with the following layers:

- **Presentation** - SwiftUI Views and ViewModels
- **Domain** - Business logic, Entities, and UseCases
- **Data** - Repositories, SwiftData models, and Mappers

### Key Patterns
- Dependency Injection with Factory framework
- Repository pattern for data access
- UseCase pattern for business operations
- MVVM presentation layer
- SwiftData for persistence

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Building

### Configurations

The project includes multiple build configurations:

- **Debug-AllFeatures** - All features enabled for development/TestFlight
- **Release-AllFeatures** - All features enabled, optimized build
- **Debug-Subscription** - Subscription-based feature gating
- **Release-Subscription** - Production configuration with subscription model

### Building for Simulator

```bash
xcodebuild build \
  -project Ritualist.xcodeproj \
  -scheme Ritualist-AllFeatures \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug
```

### Running Tests

```bash
xcodebuild test \
  -project Ritualist.xcodeproj \
  -scheme Ritualist-AllFeatures \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:RitualistTests
```

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
```

### Project Structure

```
Ritualist/
├── Application/      # App entry point and DI setup
├── Features/         # Feature modules (Habits, Overview, Settings)
├── Domain/          # Business logic and entities
├── Data/            # Data access and persistence
└── Core/            # Shared utilities and design system

RitualistTests/      # Unit tests
Scripts/            # Build and validation scripts
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

## Acknowledgments

- Built with SwiftUI and SwiftData
- Dependency injection powered by Factory
- UI design inspired by modern iOS design patterns
