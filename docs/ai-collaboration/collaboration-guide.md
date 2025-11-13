# Claude Code Collaboration Guide for Ritualist

## Interaction Protocol

### Before Every Response, I Must:
1. ✅ **Read mandatory micro-contexts FIRST** - Use `MICRO-CONTEXTS/task-router.md` to identify required cards
2. ✅ **Read CLAUDE.md completely** - Understand current project state, constraints, and conventions
3. ✅ **Check architecture alignment** - Ensure request fits Clean Architecture + feature-first organization  
4. ✅ **Validate against established patterns** - Use existing code patterns and DI structure
5. ✅ **Apply quality gates** - SwiftLint rules, naming conventions, separation of concerns

### Micro-Context Enforcement (MANDATORY):
- **NEVER** start work without reading `MICRO-CONTEXTS/quick-start.md` first
- **ALWAYS** use `task-router.md` to determine additional required cards
- **CRITICAL** tasks require specific micro-contexts:
  - Adding features → `usecase-service-distinction.md` + `violation-detection.md`
  - Testing → `testing-strategy.md` + `anti-patterns.md`
  - Bug fixes → `anti-patterns.md` + `debugging.md`

### When Making Changes, I Must:
1. ✅ **Run violation detection FIRST** - Use grep commands from `violation-detection.md` before any changes
2. ✅ **Follow existing patterns** - Never invent new patterns without discussion
3. ✅ **Maintain clean boundaries** - Domain ↔ Data ↔ Presentation separation
4. ✅ **Use established DI** - Leverage AppContainer and feature factories
5. ✅ **Test incrementally** - Build/compile after significant changes
6. ✅ **Identify architectural violations** - When encountering cross-feature dependencies or violations in existing code, STOP and propose proper refactoring before proceeding
7. ✅ **Challenge user requests with evidence** - If a request seems architecturally unsound, research the codebase thoroughly first, then push back with concrete examples and explanations. User wants to be challenged on questionable decisions, but only when backed by actual code analysis

### When I Make Mistakes, I Must:
1. ✅ **Acknowledge the error** - Be explicit about what went wrong
2. ✅ **Update CLAUDE.md** - Add new learning to prevent repetition
3. ✅ **Provide corrected approach** - Show the right way immediately
4. ✅ **Explain the why** - Help user understand the reasoning

## Communication Guidelines

### Technical Discussions:
- **Always reference file paths and line numbers** for code changes
- **Use architecture terminology consistently** (UseCases, Repositories, Entities)
- **Explain trade-offs** when multiple approaches exist
- **Provide concrete examples** rather than abstract concepts

### Planning and Architecture:
- **Create detailed plans** for complex features using TodoWrite tool
- **Break down large tasks** into atomic, testable units
- **Document decisions** that affect architecture
- **Consider future extensibility** in design choices

### Code Quality:
- **Run builds early and often** to catch issues quickly
- **Follow SwiftUI + SwiftData best practices**
- **Maintain consistency** with existing code style
- **Prioritize readability** over cleverness
- **Apply YAGNI principle** - Don't create new UseCases/abstractions when existing ones work perfectly

## Knowledge Management

### What Gets Added to CLAUDE.md:
1. **New architecture decisions** and their rationale
2. **Established code patterns** that should be reused
3. **Anti-patterns discovered** and why they should be avoided
4. **Performance considerations** specific to this app
5. **External service integration guidelines**
6. **Testing strategies** for different layers
7. **Build configuration management** (like our recent subscription system)

### Learning Loop Process:
1. **Identify gap** - When I miss something or make an error
2. **Document pattern** - Add correct approach to CLAUDE.md
3. **Create example** - Show how to apply the pattern
4. **Validate understanding** - Confirm with user before proceeding

## Collaboration Patterns

### For New Features:
1. **Architecture planning** - Discuss entities, use cases, repositories first
2. **Create task breakdown** - Use TodoWrite for complex features
3. **Implement domain first** - Start with business logic, then data, then UI
4. **Test continuously** - Build after each layer

### For Bug Fixes:
1. **Identify root cause** - Don't just fix symptoms
2. **Consider architecture impact** - Will fix affect other components?
3. **Apply minimal changes** - Preserve existing working code
4. **Document lesson learned** - Update CLAUDE.md if pattern emerges

### For Refactoring:
1. **Preserve behavior** - Ensure functionality doesn't change
2. **Improve architecture** - Move toward cleaner boundaries
3. **Update documentation** - Keep CLAUDE.md current
4. **Validate with builds** - Ensure no regressions

## Success Metrics

### Good Collaboration Indicators:
- ✅ **Faster development cycles** - Less back-and-forth on architecture
- ✅ **Consistent code quality** - New code matches existing patterns
- ✅ **Fewer regressions** - Changes don't break existing functionality
- ✅ **Clear decision trail** - CLAUDE.md documents why choices were made

### Red Flags:
- ❌ **Skipping micro-contexts** - Starting work without reading required cards
- ❌ **Architecture violations** - ViewModels injecting Services directly
- ❌ **Mock-based testing** - Using mocks instead of real implementations
- ❌ **Repeated mistakes** - Same issue appearing multiple times
- ❌ **Architecture drift** - New code not following established patterns
- ❌ **Build failures** - Not testing changes incrementally
- ❌ **Unclear rationale** - Can't explain why specific approach was chosen
- ❌ **Creating standalone test files** - NEVER create separate test scripts or files outside the proper test structure
- ❌ **Cross-feature dependencies** - Features directly calling other feature factories/components

### Enforcement Checklist - Use BEFORE Starting Any Work:

#### For Adding Features:
- [ ] Read `MICRO-CONTEXTS/quick-start.md`
- [ ] Read `MICRO-CONTEXTS/usecase-service-distinction.md`
- [ ] Read `MICRO-CONTEXTS/violation-detection.md`
- [ ] Run violation detection commands
- [ ] Confirm ViewModels will ONLY inject UseCases

#### For Testing:
- [ ] Read `MICRO-CONTEXTS/testing-strategy.md`
- [ ] Read `MICRO-CONTEXTS/anti-patterns.md`
- [ ] Confirm using real implementations, NOT mocks
- [ ] Plan test data builders, not stub methods

#### For Bug Fixes:
- [ ] Read `MICRO-CONTEXTS/anti-patterns.md`
- [ ] Read `MICRO-CONTEXTS/debugging.md`
- [ ] Run violation detection to check for architecture issues
- [ ] Fix root cause, not symptoms

## Tools and Automation

### Must-Use Tools:
- **TodoWrite** - For complex task planning and tracking
- **Read + Edit** - Always read before editing to understand context
- **Bash** - For builds, testing, and validation
- **Grep** - For understanding existing patterns before implementing new ones

### Verification Steps:
- **Build early** - After significant changes
- **Check patterns** - Grep for similar implementations
- **Validate architecture** - Ensure clean boundaries maintained
- **Update documentation** - Keep CLAUDE.md current

### Architecture Violation Detection (CRITICAL):
**Before implementing ANY feature, run these grep commands to detect existing violations:**

#### Direct Repository Access From Views (❌ VIOLATION):
```bash
grep -r "\.habitRepository\." Ritualist/Features/ --include="*.swift"
grep -r "\.logRepository\." Ritualist/Features/ --include="*.swift"
```

#### Direct Service Calls From ViewModels (❌ VIOLATION):
```bash
grep -r "@Injected.*Service" Ritualist/Features/*/Presentation/ --include="*.swift"
grep -r "\..*Service\." Ritualist/Features/*/Presentation/ --include="*.swift"
```

#### Cross-Feature Dependencies (❌ VIOLATION):
```bash
grep -r "HabitsAssistantFactory\|DashboardFactory\|OverviewFactory" Ritualist/Features/ --include="*.swift" --exclude-dir=*/Shared/*
```

#### Missing UseCase Pattern (❌ VIOLATION):
```bash
# ViewModels should call UseCases, not repositories/services directly
grep -r "func.*(" Ritualist/Features/*/Presentation/*ViewModel.swift | grep -v "UseCase\|Task\|async"
```

**✅ CORRECT PATTERNS TO VERIFY:**
- Views → ViewModels → UseCases → Services/Repositories
- Shared UseCases registered in AppContainer
- @Injected(\.useCaseName) in ViewModels

### Testing Requirements:
- **ALWAYS write proper unit tests** - Use existing test structure in RitualistTests/
- **NEVER create standalone test files** - All tests must go in the proper test target
- **Test logic and behavior** - Write tests to verify actual implementation behavior
- **Follow existing test patterns** - Look at existing tests for naming and structure conventions

### Testing Anti-Patterns (CRITICAL):
- **❌ NEVER rely primarily on mocks** - As identified in project-analysis.md, over-reliance on mocks tests mock behavior, not actual implementations
- **❌ AVOID mock-heavy test suites** - They hide real implementation issues and provide false confidence
- **❌ DON'T use mocks for critical services** - HabitCompletionService, repositories, etc. should be tested with real implementations
- **❌ NEVER create "stub" implementations** - Always implement actual working logic or mark as TODO with explanation
- **✅ USE real implementations with test data builders** - Create reliable test data using builder pattern
- **✅ USE in-memory databases for integration tests** - Test actual SwiftData interactions
- **✅ TEST actual business logic** - Verify real calculations, not mock return values

### Build Configuration:
- **Always use iPhone 16 with iOS 26** for build testing
- **Use proper scheme**: `Ritualist-AllFeatures` or `Ritualist-Subscription`
- **Standard build command**: `xcodebuild -project Ritualist.xcodeproj -scheme Ritualist-AllFeatures -destination "platform=iOS Simulator,name=iPhone 16" build`
- **Avoid other devices/simulators** - They may not be available and cause build failures

This guide ensures our collaboration remains productive, educational, and aligned with your project goals!