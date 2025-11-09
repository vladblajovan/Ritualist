# Changelog

All notable changes to Ritualist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-11-09

### Added
- **Core Habit Tracking**: Create, edit, and track daily habits with binary and numeric types
- **Smart Streaks**: Automatic streak calculation with current streak and best streak tracking
- **Categories**: Organize habits with predefined and custom categories
- **Habit Scheduling**: Support for daily and custom frequency schedules (e.g., 3x/week)
- **Reminders & Notifications**: Location-aware reminders with geofencing support
- **Overview Dashboard**: Today's summary, weekly progress, monthly calendar, and streak cards
- **Personality Analysis**: Big Five personality insights based on habit patterns (premium feature)
- **Smart Insights**: Automated habit performance analysis and recommendations
- **Settings**: User profile management, notification controls, location permissions
- **Widget Support**: Home screen widget showing habit progress
- **Build Configuration System**: Dual flag system (AllFeatures/Subscription builds)
- **Factory DI**: Dependency injection with compile-time safety
- **SwiftData Integration**: Local persistence with proper @Relationship architecture
- **N+1 Query Optimization**: Batch database operations for improved performance
- **MainActor Threading**: Optimized concurrency model for UI responsiveness

### Infrastructure
- **RitualistCore**: Shared Swift package for domain logic, use cases, and services
- **Clean Architecture**: Feature-first organization with clear layer separation
- **SwiftLint Integration**: Code quality enforcement with custom rules
- **Testing Infrastructure**: Unit test framework with test data builders

### In Progress (Not Released)
- **iCloud CloudKit Sync**: UserProfile sync implementation complete (~1,010 LOC)
  - Phase 1-3: Infrastructure, implementation, error handling ✅
  - Phase 4: Testing blocked (requires paid Apple Developer Program) ⏸️
  - Phase 5: UI integration complete ✅
  - Currently disabled due to CloudKit entitlement limitations

### Notes
- This is the **initial pre-release version** (0.1.0) establishing the versioning baseline
- App has not yet been released to TestFlight or App Store
- Version 0.x.y indicates pre-release/development status
- Build numbers automated via git commit count

---

[Unreleased]: https://github.com/vladblajovan/Ritualist/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/vladblajovan/Ritualist/releases/tag/v0.1.0
