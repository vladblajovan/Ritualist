# CLAUDE.md

## ⚡ CRITICAL: READ MICRO-CONTEXTS FIRST!
**🚨 ALWAYS start by reading relevant micro-context cards (MICRO-CONTEXTS/) before this file! 🚨**  
**📋 Use TASK-ROUTER.md to select the right cards for your task type.**  
**📖 Only read this full document if micro-contexts aren't sufficient.**

---

### **Quick Context Selection (50-150 tokens vs 800-1000):**
- **New to project**: `MICRO-CONTEXTS/quick-start.md` (50 tokens)
- **Adding features**: `MICRO-CONTEXTS/architecture.md` (30 tokens) 
- **Performance issues**: `MICRO-CONTEXTS/performance.md` (25 tokens)
- **Testing**: `MICRO-CONTEXTS/testing.md` (20 tokens)
- **Build problems**: `MICRO-CONTEXTS/build.md` (25 tokens)
- **Avoiding mistakes**: `MICRO-CONTEXTS/anti-patterns.md` (40 tokens)
- **Troubleshooting**: `MICRO-CONTEXTS/debugging.md` (35 tokens)

📖 **For comprehensive details**: Continue reading this full document (464 lines)

## 📋 COLLABORATION GUIDE
**CRITICAL**: Always reference `CLAUDE-COLLABORATION-GUIDE.md` before starting any work. This guide contains the interaction protocol, quality gates, and learning procedures that must be followed for effective collaboration.

## 🧪 TESTING STRATEGY
**IMPORTANT**: All code changes must include proper unit tests. Reference `TESTING-STRATEGY.md` for comprehensive testing guidelines, patterns, and requirements. Never create standalone test files - always use the proper RitualistTests/ structure.

## 📚 LESSONS LEARNED - CRITICAL FOR COLLABORATION

### ⚠️ **Major Refactoring Failures and Key Learnings**

**1. OverviewV2ViewModel Split Attempt (Failed)**
- **What Happened**: Attempted to split 1,232-line ViewModel into focused components using composite pattern
- **Result**: Complete functional breakdown - data not loading, 0 progress shown, over-logging bugs introduced
- **Root Cause**: Broke Single Source of Truth, lost SwiftUI @Observable reactivity, introduced race conditions
- **CRITICAL LESSON**: Don't fix what isn't broken. Working code > perfect code. Large ViewModels can be acceptable if they work correctly

**2. Premature Architecture Changes**
- **Anti-Pattern**: Making "theoretical improvements" without clear user-facing problems
- **Example**: Complex service separation that introduced Combine and DispatchQueue anti-patterns user explicitly rejected
- **RULE**: Only refactor when there's a real bug or performance issue, not for code aesthetics

**3. User Feedback Violations**
- **Critical Error**: Continuing with approaches user explicitly rejected (Combine, DispatchQueue, complex abstractions)
- **LESSON**: When user says "no Combine", that means NO COMBINE. User preferences are absolute law

### ✅ **Successful Implementation Patterns**

**1. N+1 Query Optimization**
- **Problem**: 20 habits = 20 database queries (O(n) performance)
- **Solution**: Batch query implementation with `GetBatchHabitLogsUseCase`
- **Result**: 95% reduction in database queries, measurable performance improvement
- **Pattern**: Fix specific, measurable performance issues with isolated changes

**2. Incremental Architecture Improvements**
- **Success**: SwiftData relationships implementation without breaking existing functionality
- **Success**: Factory DI migration done gradually with zero downtime
- **Success**: MainActor optimization removing unnecessary thread switches
- **Pattern**: Small, focused changes with immediate testing and validation

## 🏆 COMPLETED MAJOR INITIATIVES

### ✅ **SwiftData Relationships Implementation** 
- **Status**: COMPLETED - Full @Relationship architecture implemented
- **Impact**: Data integrity enforced, cascade delete rules, no orphaned data
- **Files**: `/Data/Models/` (SDHabit, SDHabitLog, SDCategory with proper relationships)
- **Before**: Manual foreign key management, possible data inconsistency
- **After**: SwiftData-enforced relationships, guaranteed referential integrity

### ✅ **N+1 Database Query Optimization**
- **Status**: COMPLETED - 95% query reduction achieved  
- **Impact**: Massive performance improvement for users with many habits
- **Implementation**: `GetBatchHabitLogsUseCase` replaces individual queries
- **Optimized Methods**: `loadTodaysSummary()`, `loadWeeklyProgress()`, `generateBasicHabitInsights()`, `loadMonthlyCompletionData()`
- **Before**: ~80+ database queries on app load (20 habits × 4 methods)
- **After**: 4 batch queries total on app load

### ✅ **Factory DI Migration**  
- **Status**: COMPLETED - 73% code reduction achieved
- **Impact**: Compile-time safety, better testing, industry standard approach  
- **Migration**: From custom AppContainer to Factory framework (530 → 150 lines)
- **Coverage**: All ViewModels, UseCases, Services, and Repositories migrated
- **Benefits**: Built-in testing support, @Injected property wrappers, singleton scoping

### ✅ **MainActor Threading Optimization**
- **Status**: COMPLETED - 65% MainActor load reduction achieved
- **Impact**: Improved UI responsiveness and background processing capabilities
- **Cleanup**: 37+ MainActor.run calls removed, 100+ proper @MainActor annotations added
- **Pattern**: Business services run on background threads, UI services on MainActor
- **Result**: ViewModels use correct class-level @MainActor, services are actor-agnostic

### ✅ **Build Configuration System**
- **Status**: COMPLETED - Dual flag system with validation
- **Implementation**: ALL_FEATURES_ENABLED + SUBSCRIPTION_ENABLED with compile-time validation
- **Configurations**: Debug/Release × AllFeatures/Subscription (4 total build configs)
- **Architecture**: Service layer handles feature gating, views remain unaware of build flags
- **Benefits**: TestFlight uses AllFeatures, production uses Subscription model

### ✅ **Category Management System**
- **Status**: COMPLETED - Full CRUD operations with UI
- **Features**: Create custom categories, edit/delete, predefined vs custom distinction
- **UI Components**: CategoryManagementView, CategoryRowView, EditCategorySheet
- **Data Flow**: Clean Architecture with UseCases, proper cascade handling
- **Integration**: Available from habit creation and habits list contexts

### ✅ **Personality Analysis System**  
- **Status**: COMPLETED - Big Five analysis with 9/10 architecture rating
- **Algorithm**: 50+ UseCases, sophisticated multi-criteria tie-breaking system
- **Features**: Schedule-aware analysis, completion pattern recognition, confidence scoring
- **UI**: PersonalityInsightsView with data threshold validation and progress tracking
- **Data Requirements**: 5+ active habits, 1 week logging, 3+ custom categories/habits

## ⚡ PERFORMANCE OPTIMIZATIONS ACHIEVED

### 🚀 **Threading Model Optimization**
- **Current Architecture**: 9/10 Swift concurrency rating
- **MainActor Usage**: 65% reduction in main thread load
- **Background Processing**: Business services run off main thread for better performance
- **Pattern**: `@MainActor @Observable` ViewModels, actor-agnostic services and UseCases

### 🗄️ **Database Performance**
- **N+1 Query Elimination**: 95% reduction in database queries (from N queries to 1 batch query)
- **SwiftData Relationships**: Proper referential integrity without performance overhead
- **Background Context**: Data operations don't block UI thread
- **Optimized Queries**: Batch operations for multi-habit data loading

### 🏗️ **Architecture Performance**
- **Factory DI**: Compile-time dependency resolution, zero runtime lookup overhead
- **Service Layer**: Background thread execution for analytics, personality analysis, and data processing
- **Memory Management**: Singleton scoping prevents duplicate service instances
- **Build Configuration**: Zero runtime feature flag overhead (compile-time decisions)

## 🧠 AI & PERSONALITY ANALYSIS IMPLEMENTATION

### 📊 **Algorithm Details (v1.1)**
- **Framework**: Big Five personality model (Openness, Conscientiousness, Extraversion, Agreeableness, Neuroticism)
- **Data Sources**: Habit selections, completion patterns, category preferences, custom habit creation
- **Advanced Features**: Multi-criteria tie-breaking, schedule-aware analysis, behavioral pattern recognition
- **Confidence Scoring**: Quality-based confidence with 4 levels (Low, Medium, High, Very High)

### 🎯 **Analysis Features**
- **Schedule Awareness**: Respects habit schedules (daily vs 3x/week) for accurate completion analysis
- **Pattern Recognition**: Emotional stability inference from completion patterns, flexibility preference analysis
- **Behavioral Inference**: Keyword analysis, habit variety scoring, social pattern detection
- **Quality Bonuses**: Up to +45 confidence points for high-quality data patterns

### 🏗️ **Technical Architecture**
- **Services**: `PersonalityAnalysisService`, `DataThresholdValidator`
- **UseCases**: `AnalyzePersonalityUseCase`, `GetPersonalityInsightsUseCase`, `ValidateAnalysisDataUseCase`
- **Data Models**: `PersonalityProfile`, `PersonalityTrait` enum, confidence scoring system
- **UI Integration**: Settings personality section, Smart Insights cards, threshold progress tracking

### 📈 **Future AI Enhancements**
- **Natural Language Analysis**: Planned Apple NLP integration for custom habit name analysis
- **Temporal Patterns**: Weekly/seasonal behavioral pattern recognition
- **Predictive Modeling**: Habit success prediction based on personality and historical data
- **Enhanced Recommendations**: Personality-based habit suggestions and coaching

## 🚨 CRITICAL DEVELOPMENT REMINDERS 🚨

**ALWAYS FOLLOW THESE PRINCIPLES:**
- **VERIFY BEFORE WRITING**: NEVER use imaginary property, method, function, parameter, or class names. ALWAYS search the actual codebase first using Grep/Read tools
- **Clean Architecture**: Views → ViewModels → UseCases → Services/Repositories
- **Separation of Concerns**: No direct service calls from Views or ViewModels
- **UseCase Pattern**: Every business operation must go through a UseCase
- **Build Standard**: ALWAYS test using iPhone 16, iOS 26 simulator
- **Repository Pattern**: Views NEVER call repositories directly - use UseCases

**ARCHITECTURAL VIOLATIONS TO AVOID:**
- ❌ Direct service calls from ViewModels (use UseCases)
- ❌ Repository calls from Views (use UseCases) 
- ❌ Business logic in Views (move to UseCases)
- ❌ Multiple service dependencies in ViewModels (compose via UseCases)

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
- **Framework**: Factory-based DI (migrated from custom AppContainer)  
- **Pattern**: `@Injected(\.propertyName)` property wrappers and Container extensions
- **Access**: Services via `@Injected`, ViewModels via factory methods
- **Scoping**: Singleton for services, factory-created for ViewModels

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

- **Language**: Swift 5.9+, iOS 17+ minimum deployment
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

## Build Configuration System

The app uses a sophisticated build-time configuration system for subscription management:

### Build Configurations:
- **Debug-AllFeatures / Release-AllFeatures**: All premium features enabled (TestFlight/launch)
- **Debug-Subscription / Release-Subscription**: Subscription-based feature gating (production)

### Compiler Flags:
- `ALL_FEATURES_ENABLED`: Grants all premium features regardless of subscription
- `SUBSCRIPTION_ENABLED`: Enforces subscription-based feature gating

### Architecture Integration:
- **FeatureGatingService**: Respects build configuration automatically
- **Build-time validation**: Compile errors prevent invalid flag combinations
- **Clean boundaries**: UI layer unaware of build config - uses service layer

### Usage:
```swift
// ✅ Correct - Service layer handles build config
vm.hasAdvancedAnalytics  // Automatically respects build flags

// ❌ Wrong - Never put build checks in views
#if ALL_FEATURES_ENABLED
// View logic here
#endif
```

## 📋 ARCHITECTURE DECISIONS LOG

### Recent Decisions (August 2025):

1. **Build Configuration Strategy**
   - **Decision**: Explicit dual boolean flags with compile-time validation
   - **Rationale**: Prevents configuration errors, enables TestFlight→AppStore workflow
   - **Implementation**: `BuildConfigurationService` with `#error` validation

2. **Feature Gating Architecture**
   - **Decision**: Service layer handles all build config logic, not views
   - **Rationale**: Maintains clean architecture, easier testing, single responsibility
   - **Implementation**: `BuildConfigFeatureGatingService` wraps standard service

3. **Subscription Testing Strategy**
   - **Decision**: AllFeatures build for TestFlight, Subscription build for App Store
   - **Rationale**: Beta users test full experience, production has revenue model
   - **Implementation**: Scheme-based switching, zero code changes needed

4. **Factory DI Migration Strategy**
   - **Decision**: Migrate from custom AppContainer to Factory framework
   - **Rationale**: Industry standard, compile-time safety, built-in testing support, 73% code reduction
   - **Implementation**: Gradual migration maintaining compatibility, @Injected property wrappers

5. **SwiftData Relationships Implementation**
   - **Decision**: Use proper @Relationship attributes instead of manual foreign keys
   - **Rationale**: Data integrity, cascade delete rules, SwiftData best practices
   - **Impact**: Eliminated orphaned data issues, proper referential integrity

6. **MainActor Threading Strategy**
   - **Decision**: Business services run on background threads, UI services on MainActor
   - **Rationale**: Better performance, UI responsiveness, proper Swift concurrency patterns
   - **Pattern**: `@MainActor @Observable` ViewModels, actor-agnostic services and UseCases

7. **N+1 Query Optimization Strategy**
   - **Decision**: Implement batch query operations for multi-habit data loading
   - **Rationale**: Measurable performance improvement (95% query reduction) without complexity
   - **Implementation**: `GetBatchHabitLogsUseCase` replaces individual queries

8. **Large ViewModel Strategy**
   - **Decision**: Keep working large ViewModels (1,232 lines) rather than force premature splitting
   - **Rationale**: Failed refactoring attempt proved working code > perfect code
   - **Anti-Pattern**: Don't fix what isn't broken, avoid theoretical improvements

## Established Code Patterns

### Feature Creation Workflow:
1. **Domain First**: Define entities, repository protocols, use cases
2. **Data Layer**: Implement repositories, data sources, mappers
3. **Presentation**: Create ViewModels that use UseCases, then Views
4. **Dependency Injection**: Wire up in appropriate FeatureDI factory
5. **Testing**: Unit tests for domain, UI tests for flows

### Build Configuration Integration:
```swift
// ✅ Service layer pattern (correct)
public var hasAdvancedAnalytics: Bool {
    #if ALL_FEATURES_ENABLED
    return true
    #else
    return standardFeatureGating.hasAdvancedAnalytics
    #endif
}

// ✅ ViewModel pattern (correct)
vm.hasAdvancedAnalytics  // Uses service layer

// ❌ View pattern (avoid)
#if ALL_FEATURES_ENABLED
// UI logic
#endif
```

## Anti-Patterns to Avoid

### Build Configuration Anti-Patterns:
- ❌ **Build checks in views**: Use service layer instead
- ❌ **Implicit configuration**: Always require explicit flags
- ❌ **Mixed build logic**: Keep build config in dedicated services

### Architecture Anti-Patterns:
- ❌ **Direct service calls from ViewModels**: Use UseCases
- ❌ **Repository calls from Views**: Use UseCases → Repositories
- ❌ **Business logic in Views**: Move to UseCases
- ❌ **Multiple service dependencies**: Compose via UseCases

### Code Duplication Anti-Patterns:
- ❌ **Duplicate UI components**: Use shared components in `/Features/Shared/Presentation/`
- ❌ **Copy-paste similar Views**: Extract common patterns into reusable components
- ❌ **Feature-specific versions of shared logic**: Use domain-level shared components

### Domain UseCase Management:
**CRITICAL PATTERN**: Shared UseCases belong in AppContainer, not feature-specific factories.

**✅ Correct Pattern:**
```swift
// AppContainer protocol
var createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase { get }

// Feature using shared UseCase
return await di.createHabitFromSuggestionUseCase.execute(suggestion)
```

**❌ Wrong Pattern:**
```swift
// Cross-feature dependency violation
let habitsAssistantFactory = HabitsAssistantFactory(container: di)
let useCase = habitsAssistantFactory.makeCreateHabitFromSuggestionUseCase()
```

**Why This Matters:**
- **Feature Independence**: No cross-feature dependencies
- **Testability**: Each feature can be tested in isolation  
- **Single Source of Truth**: Shared logic lives in Domain layer
- **Clean Architecture**: Proper dependency flow

## Performance Considerations

- **Build-time decisions**: Zero runtime overhead for feature flagging
- **SwiftData optimization**: Use appropriate fetch descriptors and sorting
- **UI performance**: Minimize re-renders with proper @Observable usage

## External Integration Guidelines

- **Build tools**: All configurations must build successfully before merge
- **TestFlight**: Use AllFeatures configuration for beta testing
- **App Store**: Use Subscription configuration for production releases

## 🔧 DEVELOPMENT WORKFLOW & TROUBLESHOOTING

### 🛠️ **Development Standards**
- **Build Testing**: Always use iPhone 16, iOS 26 simulator (iOS 17 minimum deployment target)
- **Build Commands**: Standard build command: `xcodebuild -project Ritualist.xcodeproj -scheme Ritualist-AllFeatures -destination "platform=iOS Simulator,name=iPhone 16" build`
- **Code Quality**: SwiftLint must pass before commits (integrated as build phase)
- **Architecture**: Maintain Clean Architecture separation, no violations allowed

### 🧪 **Testing Requirements**  
- **Framework**: Swift Testing (iOS 17+) for unit tests
- **Structure**: RitualistTests/ hierarchy must be maintained (never create standalone test files)
- **Coverage**: 80%+ for business logic, 90%+ for Domain layer
- **Patterns**: AAA pattern (Arrange, Act, Assert), test builders for consistent data

### 🚀 **Performance Monitoring**
- **Database Queries**: Monitor for N+1 patterns, use batch operations
- **UI Responsiveness**: Ensure business logic runs on background threads
- **Memory Usage**: Singleton services prevent duplicate instances
- **Threading**: Background services, MainActor ViewModels

### 🏗️ **Architecture Compliance**
- **Clean Architecture Flow**: Views → ViewModels → UseCases → Services/Repositories
- **Dependency Direction**: Always inward (Presentation → Domain → Data)
- **Service Layer**: Business services on background threads, UI services on MainActor
- **No Violations**: Direct service calls from ViewModels, repository calls from Views

### 📋 **Common Troubleshooting**

**Build Issues:**
- Verify iPhone 16, iOS 26 simulator is available and selected (iOS 17 minimum deployment)
- Check SwiftLint violations (build phase shows them as errors)
- Ensure all configurations build (Debug/Release × AllFeatures/Subscription)

**Performance Issues:**
- Check for N+1 database query patterns
- Verify business logic isn't blocking main thread
- Monitor MainActor usage with threading analysis

**Architecture Issues:**
- Verify Clean Architecture layer separation
- Check for cross-feature dependencies (anti-pattern)
- Ensure proper UseCase → Repository → DataSource flow

**Testing Issues:**
- Use RitualistTests/ structure, never standalone files
- Follow Swift Testing patterns (not XCTest unless legacy)
- Maintain test builders for consistent test data

### 🎯 **Quality Gates**
1. **Build Success**: All 4 configurations must build successfully
2. **SwiftLint Clean**: Zero linting violations allowed
3. **Architecture Compliance**: No layer violations or anti-patterns
4. **Test Coverage**: Adequate coverage for business logic changes
5. **Performance Validation**: No regressions in UI responsiveness