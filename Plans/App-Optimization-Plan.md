# Ritualist App Optimization Plan
*Comprehensive strategy for DRY principles, shared components, and architectural improvements*

## Executive Summary

This document outlines a systematic approach to optimize the Ritualist iOS app by:
1. **Extracting shared UI components** from features to centralized locations
2. **Eliminating duplicate code** while maintaining DRY principles
3. **Preserving clear business logic separation** (no DRY violations in domain layer)
4. **Migrating from Combine to @Observable** for consistency
5. **Creating reusable UI components** with parameter-based customization

**Expected Benefits:**
- 30-40% reduction in UI code duplication
- Improved maintainability and consistency
- Better performance with @Observable pattern
- Easier testing and component reuse

## Current State Analysis

### ✅ Architecture Strengths
- **Clean Architecture**: Well-maintained Views → ViewModels → UseCases → Services/Repositories flow
- **Factory DI**: Modern dependency injection with @Injected patterns
- **SwiftData Integration**: Proper relationships and data layer
- **Performance**: N+1 queries optimized, MainActor properly used

### ⚠️ Areas for Improvement

#### Duplicate UI Components (8+ Identified)
1. **Row Components**:
   - `HabitRowView` (Habits/Presentation/HabitsView.swift:464)
   - `CategoryRowView` (Settings/Presentation/CategoryManagementView.swift:232)
   - `TipListRow` (Tips/Presentation/TipsBottomSheet.swift:101)
   - `HabitSuggestionRow` (HabitsAssistant/Presentation/HabitsAssistantView.swift:183)
   - `TraitRowView` (UserPersonality/Presentation/PersonalityInsightsView.swift:620)
   - `HabitPerformanceRow` (Dashboard/Presentation/Components/HabitPerformanceRow.swift:4)
   - `RequirementRowView` (UserPersonality/Presentation/DataThresholdPlaceholderView.swift:158)

2. **Card Components**:
   - Multiple card implementations instead of using existing `BaseCard` protocol
   - `TipCard`, `BenefitCard`, `PricingCard` with similar structures

3. **Button Styles**:
   - Inconsistent button styling across features
   - Missing centralized iOS 26 glass button implementation
   - Multiple `.buttonStyle()` variations

4. **Sheet Components**:
   - 5+ sheet implementations with similar patterns
   - Could be consolidated into reusable base sheets

#### Combine Usage (2 Files to Migrate)
1. **NavigationService.swift**: Uses `@Published` and `ObservableObject`
2. **FeatureGatingService.swift**: Has Combine import and deprecated patterns

#### Styling Inconsistencies
- Repeated styling patterns across 50+ files
- 822 instances of styling properties that could be centralized
- iOS 26 features not consistently applied

## Phase 1: Shared Components Extraction

### 1.1 Create Shared Component Library

**Location**: `Ritualist/Features/Shared/Presentation/Components/`

#### A. GenericRowView
```swift
public struct GenericRowView: View {
    let icon: RowIcon?
    let title: String
    let subtitle: String?
    let trailing: AnyView?
    let action: (() -> Void)?
    
    enum RowIcon {
        case emoji(String)
        case systemImage(String, Color?)
        case circle(Color)
    }
}
```

**Replaces**: 7+ duplicate row implementations
**Benefits**: Single component for all list rows with flexible customization

#### B. ActionButton
```swift
public struct ActionButton: View {
    let title: String
    let style: ActionButtonStyle
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    enum ActionButtonStyle {
        case primary, secondary, destructive, ghost
        case glass26 // iOS 26 Liquid Glass style
    }
}
```

**Features**: 
- iOS 26 glass button support with availability checks
- Loading states and disabled states
- Consistent bounce animations from existing `BounceStyle`

#### C. SectionContainer
```swift
public struct SectionContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let headerAction: HeaderAction?
    let content: () -> Content
    
    struct HeaderAction {
        let title: String
        let action: () -> Void
    }
}
```

#### D. StatCard
```swift
public struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let trend: TrendIndicator?
    let color: Color?
    
    enum TrendIndicator {
        case up(Double), down(Double), neutral
    }
}
```

#### E. BaseSheet
```swift
public struct BaseSheet<Content: View>: View {
    let title: String
    let subtitle: String?
    let dismissAction: () -> Void
    let content: () -> Content
    
    // Standard sheet presentation with consistent styling
}
```

### 1.2 Progress Components

#### CircularProgressView (Enhancement)
- Extend existing `CircularProgressView` for more use cases
- Add size variants and color customization

#### LinearProgressView
```swift
public struct LinearProgressView: View {
    let progress: Double
    let trackColor: Color
    let progressColor: Color
    let height: CGFloat
}
```

### 1.3 State Management Components

#### EmptyStateView
```swift
public struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: ActionButton?
}
```

#### LoadingOverlay
```swift
public struct LoadingOverlay: View {
    let message: String?
    let isVisible: Bool
}
```

## Phase 2: Duplicate Code Elimination

### 2.1 Row Component Migration

**Files to Update:**
1. `Habits/Presentation/HabitsView.swift` - Replace `HabitRowView`
2. `Settings/Presentation/CategoryManagementView.swift` - Replace `CategoryRowView`
3. `Tips/Presentation/TipsBottomSheet.swift` - Replace `TipListRow`
4. `HabitsAssistant/Presentation/HabitsAssistantView.swift` - Replace `HabitSuggestionRow`
5. `UserPersonality/Presentation/PersonalityInsightsView.swift` - Replace `TraitRowView`
6. `Dashboard/Presentation/Components/HabitPerformanceRow.swift` - Refactor to use `GenericRowView`

**Migration Pattern:**
```swift
// Before
private struct HabitRowView: View {
    let habit: Habit
    let onTap: () -> Void
    // ... 30+ lines of custom styling
}

// After
GenericRowView(
    icon: .emoji(habit.emoji ?? "•"),
    title: habit.name,
    subtitle: habit.isActive ? "Active" : "Inactive",
    trailing: AnyView(Image(systemName: "info.circle")),
    action: onTap
)
```

### 2.2 Button Standardization

**Create Centralized Button Styles:**
- Extend existing `CardDesign.swift` with button styles
- Add iOS 26 glass button implementation
- Remove inline button styling across 40+ files

### 2.3 Card Component Consolidation

**Extend BaseCard Protocol:**
- All card components should implement `OverviewCardData` protocol
- Use unified `CardStyle` modifier from existing `CardDesign.swift`
- Remove duplicate card styling

### 2.4 Sheet Pattern Unification

**Files to Refactor:**
1. `HabitsAssistantSheet.swift`
2. `TipsBottomSheet.swift`
3. `AddCustomCategorySheet.swift`
4. `NumericHabitLogSheet.swift`
5. `PersonalityAnalysisDeepLinkSheet.swift`

## Phase 3: Business Logic Preservation

### 3.1 Domain Layer - NO CHANGES
**Principle**: Business logic must remain feature-specific and NOT be consolidated.

**Preserved Separation:**
- **UseCases**: Keep all 50+ UseCases feature-specific
- **Services**: Domain services remain in their contexts
- **Entities**: Business models stay in domain layer
- **Repositories**: Repository interfaces and implementations stay separated

**Why**: Business logic duplication is often intentional and context-specific.

### 3.2 Clean Architecture Boundaries
- Views → ViewModels → UseCases → Services/Repositories flow maintained
- No cross-feature dependencies introduced
- Shared UI components don't contain business logic

## Phase 4: Combine to @Observable Migration

### 4.1 NavigationService.swift Migration
```swift
// Current (Combine-based)
@MainActor
public final class NavigationService: ObservableObject {
    @Published public var selectedTab: Pages = .overview
    @Published public var shouldRefreshOverview = false
}

// Target (@Observable)
@MainActor
@Observable
public final class NavigationService {
    public var selectedTab: Pages = .overview
    public var shouldRefreshOverview = false
}
```

### 4.2 FeatureGatingService.swift Cleanup
- Remove deprecated `@Observable` implementation
- Remove Combine imports
- Keep only the business service layer
- Clean up legacy code marked as deprecated

### 4.3 View Integration Updates
**Files to Update:**
- `Application/RootTabView.swift` - Update NavigationService usage
- Any ViewModels using NavigationService with Combine patterns

### 4.4 PersonalityDeepLinkCoordinator Migration
- Convert `@Published` properties to @Observable pattern
- Remove Combine dependencies

## Phase 5: Reusable UI Component Design

### 5.1 Component Design Principles

#### Flexibility Through Parameters
```swift
// Example: GenericRowView supports multiple configurations
GenericRowView(
    icon: .circle(.blue),              // For habit categories
    title: "Daily Exercise",
    subtitle: "Active • 7 day streak",
    trailing: AnyView(Toggle("", isOn: $isEnabled))
)

GenericRowView(
    icon: .systemImage("star.fill", .yellow),  // For tips
    title: "Meditation Tip",
    subtitle: "Reduce stress and anxiety"
)
```

#### Consistent Styling
- All components use `CardDesign` and `Spacing` tokens
- iOS 26 features with proper availability checks
- Dark mode support built-in

#### Accessibility
- Proper VoiceOver labels
- Dynamic Type support
- High contrast support

### 5.2 Component Extensions

#### Existing Components to Enhance
1. **Chip.swift** - Already well-designed, minor enhancements
2. **CategoryFilterCarousel.swift** - Good reusability
3. **HorizontalCarousel.swift** - Generic enough for reuse
4. **ConfirmationDialog.swift** - Good shared component

#### New Component Categories
1. **Input Components**: Text fields, selectors, steppers
2. **Display Components**: Stats, metrics, indicators
3. **Navigation Components**: Tab bars, navigation items
4. **Feedback Components**: Alerts, toasts, loading states

## Implementation Timeline

### Week 1: Foundation (Phase 1-2)
- **Days 1-2**: Create shared component library structure
- **Days 3-4**: Implement GenericRowView and ActionButton
- **Days 5-7**: Migrate first 3 row components, test thoroughly

### Week 2: Migration (Phase 2-3)
- **Days 1-3**: Complete row component migration
- **Days 4-5**: Button and card standardization
- **Days 6-7**: Sheet component consolidation

### Week 3: Observable Migration (Phase 4)
- **Days 1-2**: NavigationService migration
- **Days 3-4**: FeatureGatingService cleanup
- **Days 5-7**: Integration testing and bug fixes

### Week 4: Polish & Validation (Phase 5)
- **Days 1-3**: Advanced component features
- **Days 4-5**: Performance testing
- **Days 6-7**: Documentation and code review

## Success Metrics

### Code Quality Metrics
- **Lines of Code**: Target 30% reduction in UI code
- **Duplicate Code**: Eliminate 8+ duplicate row components
- **Component Reuse**: 5+ shared components used across 15+ files
- **Architecture Violations**: Zero violations introduced

### Performance Metrics
- **Build Time**: No significant impact
- **Runtime Performance**: Improved with @Observable
- **Memory Usage**: Reduced with shared components
- **App Startup**: No regression

### Maintainability Metrics
- **Component Tests**: 90%+ coverage for shared components
- **Documentation**: All shared components documented
- **API Consistency**: Unified parameter patterns
- **Future Feature Development**: Faster with shared components

## Risk Mitigation

### Technical Risks
1. **Breaking Existing Functionality**: 
   - Mitigation: Incremental migration with thorough testing
2. **Performance Impact**: 
   - Mitigation: Performance testing at each phase
3. **Over-abstraction**: 
   - Mitigation: Keep components flexible, avoid premature optimization

### Process Risks
1. **Timeline Overrun**: 
   - Mitigation: Phase-based approach allows for adjustments
2. **Team Adoption**: 
   - Mitigation: Clear documentation and examples
3. **Regression Introduction**: 
   - Mitigation: Comprehensive testing strategy

## File Organization After Optimization

```
Ritualist/Features/Shared/Presentation/
├── Components/
│   ├── Buttons/
│   │   ├── ActionButton.swift
│   │   └── ButtonStyles.swift
│   ├── Cards/
│   │   ├── StatCard.swift
│   │   └── BaseCard+Extensions.swift
│   ├── Lists/
│   │   ├── GenericRowView.swift
│   │   └── EmptyStateView.swift
│   ├── Progress/
│   │   ├── LinearProgressView.swift
│   │   └── CircularProgressView+Extensions.swift
│   ├── Sheets/
│   │   ├── BaseSheet.swift
│   │   └── SheetPresentationModifiers.swift
│   └── Layout/
│       ├── SectionContainer.swift
│       └── LoadingOverlay.swift
├── [Existing Files]
│   ├── CategoryFilterCarousel.swift
│   ├── Chip.swift
│   ├── ConfirmationDialog.swift
│   └── HorizontalCarousel.swift
```

## ✅ COMPLETED: Sheet Presentation Optimization (August 2025)

### Sheet Sizing System Overhaul
Successfully implemented a comprehensive device-aware sheet presentation system that eliminates hardcoded values and provides consistent, responsive sizing across all devices.

#### Key Achievements:
1. **Device-Aware Multiplier System**: Created `View+DeviceAwareSizing.swift` extension using screen height fractions instead of magic numbers
2. **Dynamic Font Support**: All sheets now properly handle accessibility font scaling without losing functionality  
3. **iPhone SE Compatibility**: Fixed critical usability issues on small screens with appropriate sizing ratios
4. **Consistent Drag Behavior**: All sheets now support full drag-to-top functionality with proper presentation detents

#### Technical Implementation:
```swift
extension View {
    func deviceAwareSheetSizing(
        compactMultiplier: (min: CGFloat, ideal: CGFloat, max: CGFloat),
        regularMultiplier: (min: CGFloat, ideal: CGFloat, max: CGFloat), 
        largeMultiplier: (min: CGFloat, ideal: CGFloat, max: CGFloat)
    ) -> some View
}
```

#### Sheets Optimized (7 Total):
- **NumericHabitLogSheet**: Fixed button layout + multiplier sizing (92-98% / 67-87% / 61-78%)
- **StreaksCard**: Increased from cramped to proper size (75-95% / 70-90% / 65-85%)  
- **HabitsAssistantSheet**: Added missing presentation configuration (88-100% / 80-100% / 72-94%)
- **TipsBottomSheet**: Responsive sizing across devices (88-100% / 80-100% / 72-94%)
- **PersonalityInsights**: Large sheet support (97-100% / 87-100% / 78-100%)
- **Privacy/Confidence sheets**: Compact sizing (53-79% / 47-67% / 39-61%)
- **TipDetailView**: Content-appropriate sizing (71-97% / 60-87% / 56-78%)

#### Architecture Benefits:
- **Maintainability**: No more magic numbers - all sizing based on clean screen fractions
- **Consistency**: Unified behavior across all sheet presentations
- **Accessibility**: Full dynamic type support prevents buttons being hidden
- **Responsiveness**: Proper adaptation from iPhone SE (568pt) to iPhone Pro Max (926pt)

### Fixed Button Layout Pattern
Established the correct pattern for sheets with critical actions:
```swift
VStack(spacing: 0) {
    ScrollView { /* content */ }
    VStack { /* fixed buttons */ }.background(.regularMaterial)
}
```

**Impact**: Ensures buttons remain accessible regardless of content size or font scaling.

---

## Conclusion

This optimization plan provides a systematic approach to improving the Ritualist app's codebase while maintaining its excellent architectural foundation. The focus on shared components and DRY principles will significantly improve maintainability and development velocity while preserving the clear business logic separation that makes the app robust and testable.

The phased approach ensures minimal risk while delivering measurable improvements in code quality, consistency, and developer experience.

**Recent Success**: The sheet presentation optimization demonstrates the effectiveness of systematic, device-aware improvements that enhance both developer experience and user accessibility across the entire iOS device ecosystem.