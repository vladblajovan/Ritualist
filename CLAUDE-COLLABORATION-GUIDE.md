# Claude Code Collaboration Guide for Ritualist

## Interaction Protocol

### Before Every Response, I Must:
1. ✅ **Read CLAUDE.md completely** - Understand current project state, constraints, and conventions
2. ✅ **Check architecture alignment** - Ensure request fits Clean Architecture + feature-first organization  
3. ✅ **Validate against established patterns** - Use existing code patterns and DI structure
4. ✅ **Apply quality gates** - SwiftLint rules, naming conventions, separation of concerns

### When Making Changes, I Must:
1. ✅ **Follow existing patterns** - Never invent new patterns without discussion
2. ✅ **Maintain clean boundaries** - Domain ↔ Data ↔ Presentation separation
3. ✅ **Use established DI** - Leverage AppContainer and feature factories
4. ✅ **Test incrementally** - Build/compile after significant changes

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
- ❌ **Repeated mistakes** - Same issue appearing multiple times
- ❌ **Architecture drift** - New code not following established patterns
- ❌ **Build failures** - Not testing changes incrementally
- ❌ **Unclear rationale** - Can't explain why specific approach was chosen

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

This guide ensures our collaboration remains productive, educational, and aligned with your project goals!