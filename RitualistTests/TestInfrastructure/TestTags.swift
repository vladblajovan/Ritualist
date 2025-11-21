import Testing

/// Centralized test tags for organizing and running test suites by flow/feature
///
/// **Usage:**
/// ```swift
/// @Suite("My Tests", .tags(.timezone, .critical))
/// struct MyTests { }
/// ```
///
/// **Running tests by tag:**
/// ```bash
/// # Run all timezone-related tests
/// swift test --filter tag:timezone
///
/// # Run all critical tests
/// swift test --filter tag:critical
///
/// # Run all business logic tests
/// swift test --filter tag:businessLogic
/// ```
extension Tag {

    // MARK: - Architectural Layers

    /// Business logic tests (services, domain rules, calculations)
    @Tag static var businessLogic: Self

    /// Data layer tests (repositories, data sources, persistence)
    @Tag static var dataLayer: Self

    /// Use case/orchestration tests (coordinating multiple services)
    @Tag static var orchestration: Self

    /// Infrastructure tests (test helpers, mocks, builders)
    @Tag static var infrastructure: Self

    // MARK: - Feature Areas

    /// Tests related to timezone handling (three-timezone model, travel detection)
    @Tag static var timezone: Self

    /// Tests related to notifications (scheduling, delivery, actions)
    @Tag static var notifications: Self

    /// Tests related to habit tracking (logging, completion, streaks)
    @Tag static var habits: Self

    /// Tests related to Dashboard/Overview analytics
    @Tag static var dashboard: Self

    /// Tests related to historical date validation
    @Tag static var history: Self

    /// Tests related to offer codes and discounts
    @Tag static var offerCodes: Self

    /// Tests related to onboarding flow
    @Tag static var onboarding: Self

    /// Tests related to user profile management
    @Tag static var profile: Self

    /// Tests related to categories
    @Tag static var categories: Self

    /// Tests related to streak calculations
    @Tag static var streaks: Self

    // MARK: - Priority Levels

    /// Critical tests that must pass before any release
    @Tag static var critical: Self

    /// High priority tests for core functionality
    @Tag static var high: Self

    /// Medium priority tests for important features
    @Tag static var medium: Self

    /// Low priority tests for edge cases
    @Tag static var low: Self

    // MARK: - Test Types

    /// Unit tests (isolated component testing)
    @Tag static var unit: Self

    /// Integration tests (multiple components working together)
    @Tag static var integration: Self

    /// End-to-end flow tests
    @Tag static var e2e: Self

    /// Regression tests (prevent known bugs from reoccurring)
    @Tag static var regression: Self

    /// Edge case tests (boundary conditions, unusual inputs)
    @Tag static var edgeCases: Self

    /// Error handling tests (failure scenarios, recovery)
    @Tag static var errorHandling: Self

    // MARK: - Speed / Performance

    /// Fast tests (< 100ms) - run frequently
    @Tag static var fast: Self

    /// Slow tests (> 1s) - run less frequently
    @Tag static var slow: Self

    // MARK: - Dependencies

    /// Tests that use SwiftData/database
    @Tag static var database: Self

    /// Tests that require network connectivity
    @Tag static var network: Self

    /// Tests that interact with system services (notifications, location, etc.)
    @Tag static var system: Self

    /// Tests that are completely isolated (no external dependencies)
    @Tag static var isolated: Self

    // MARK: - User Flows

    /// Tests covering the habit creation flow
    @Tag static var habitCreation: Self

    /// Tests covering the habit logging flow
    @Tag static var habitLogging: Self

    /// Tests covering the habit editing flow
    @Tag static var habitEditing: Self

    /// Tests covering the settings/preferences flow
    @Tag static var settings: Self

    /// Tests covering travel scenarios (timezone changes)
    @Tag static var travel: Self

    /// Tests covering completion checking logic
    @Tag static var completion: Self

    /// Tests covering scheduling logic
    @Tag static var scheduling: Self
}

// MARK: - Tag Combinations for Common Scenarios

extension Tag {
    /// Quick smoke test - critical tests only, fast execution
    static var smokeTest: [Self] { [.critical, .fast] }

    /// Pre-commit checks - fast tests without system dependencies
    static var preCommit: [Self] { [.fast, .isolated] }

    /// Full regression suite - all regression tests
    static var fullRegression: [Self] { [.regression] }

    /// Database-related tests - useful for schema changes
    static var databaseTests: [Self] { [.database] }

    /// Timezone-related tests - useful when changing timezone logic
    static var timezoneTests: [Self] { [.timezone, .travel] }

    /// Business critical - all critical business logic tests
    static var businessCritical: [Self] { [.businessLogic, .critical] }

    /// Notification flow - all notification-related tests
    static var notificationFlow: [Self] { [.notifications, .scheduling] }

    /// Habit tracking flow - all habit-related tests
    static var habitFlow: [Self] { [.habits, .habitLogging, .completion] }
}
