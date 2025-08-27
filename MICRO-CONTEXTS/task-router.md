# Task Router - Automatic Context Selection (120 tokens)

**MANDATORY: Use this to determine which micro-contexts to read BEFORE any work.**

## **Task Type → Required Reading**

**🏗️ Adding Features/Components:**
- `quick-start.md` → `usecase-service-distinction.md` → `violation-detection.md`
- **Critical**: Run violation detection BEFORE implementing
- **Focus**: ViewModels must ONLY inject UseCases, never Services

**🧪 Writing Tests:**
- `quick-start.md` → `testing-strategy.md` → `anti-patterns.md`
- **Critical**: Use real implementations, NOT mocks
- **Focus**: Test actual business logic, not mock behavior

**🐛 Bug Fixing:**
- `anti-patterns.md` → `debugging.md` → `violation-detection.md`
- **Critical**: Check for architecture violations first
- **Focus**: Don't fix symptoms, fix architectural issues

**⚡ Performance Issues:**
- `quick-start.md` → `performance.md` → `architecture.md`
- **Critical**: Check for N+1 queries, direct Service injection
- **Focus**: Use batch operations, proper threading

**🔨 Build Problems:**
- `build.md` → `debugging.md`
- **Critical**: Use iPhone 16, iOS 26 simulator only
- **Focus**: SwiftLint must pass, 4 build configs

## **🚫 NEVER PROCEED WITHOUT READING ASSIGNED CARDS**
- Skip micro-contexts = Architecture violations guaranteed
- Wrong task routing = Wasted time and rework
- Always read in sequence: general → specific → detection