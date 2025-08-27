# Testing Strategy (75 tokens)

**CRITICAL:** Avoid mock-based testing (project-analysis.md identifies as major issue)

**✅ CORRECT APPROACH:**
- Real implementations with test data builders (TestBuilders.swift)
- In-memory SwiftData for repository tests
- TestModelContainer for integration tests
- Actual business logic verification, not mock behavior

**❌ WRONG APPROACH:**
- Mock-heavy test suites (hide real issues)
- Testing mock return values instead of actual calculations
- Stub implementations returning 0/nil/empty

**Pattern:** Build reliable test data → Test real implementation → Verify actual behavior