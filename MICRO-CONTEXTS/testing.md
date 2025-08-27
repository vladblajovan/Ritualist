# Testing (35 tokens)

**Framework:** Swift Testing (iOS 17+), NOT XCTest

**Structure:** RitualistTests/ hierarchy (NEVER standalone files)

**CRITICAL:** Use real implementations + test data builders, NOT mocks (project-analysis.md violation)

**Pattern:** AAA (Arrange, Act, Assert), test builders for consistent data

**Coverage:** 80%+ business logic, 90%+ Domain layer