# Navigation Architecture Plan - Coordinator Pattern

## Executive Summary
Implement a Coordinator pattern for navigation that centralizes navigation logic, manages dependency injection, and eliminates tight coupling between views and their navigation destinations.

## Current Problems
1. **Scattered Navigation Logic**: Navigation code distributed across ViewModels and Views
2. **Tight Coupling**: Views directly instantiate their destination ViewModels
3. **No Central Control**: Difficult to implement app-wide navigation flows
4. **Testing Challenges**: Navigation logic mixed with business logic
5. **Deep Link Complexity**: No centralized handling for deep links

## Proposed Architecture

### Core Components

#### 1. Coordinator Protocol
```swift
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    var container: Container { get }
    
    func start()
    func coordinate(to route: Route)
}
```

#### 2. Route System
```swift
enum AppRoute {
    case habits
    case habitDetail(Habit?)
    case overview
    case dashboard
    case settings
    case paywall(source: String)
    case assistant
    case categoryManagement
}
```

#### 3. Main App Coordinator
```swift
@MainActor
final class AppCoordinator: ObservableObject {
    let container: Container
    private var tabCoordinators: [TabCoordinator] = []
    
    func start() -> some View {
        RootTabView()
            .environmentObject(self)
    }
    
    func navigate(to route: AppRoute) {
        // Centralized navigation logic
    }
}
```

## Implementation Phases

### Phase 1: Foundation (2-3 days)
- [ ] Create Coordinator protocol and base implementation
- [ ] Define comprehensive Route enum system
- [ ] Implement AppCoordinator as root coordinator
- [ ] Create TabCoordinator for each tab

### Phase 2: Feature Coordinators (3-4 days)
- [ ] HabitsCoordinator - Manage habits flow
- [ ] OverviewCoordinator - Handle overview navigation
- [ ] DashboardCoordinator - Dashboard navigation
- [ ] SettingsCoordinator - Settings and profile flows

### Phase 3: Migration (4-5 days)
- [ ] Migrate navigation from ViewModels to coordinators
- [ ] Remove direct ViewModel instantiation from Views
- [ ] Update sheets and modals to use coordinators
- [ ] Ensure all navigation goes through coordinators

### Phase 4: Advanced Features (2-3 days)
- [ ] Implement deep link handling through coordinators
- [ ] Add navigation history tracking
- [ ] Create navigation analytics middleware
- [ ] Add transition animations control

## Dependency Injection Benefits

### Current DI Issues
```swift
// Current: View creates ViewModel directly
struct HabitsRoot: View {
    @Injected(\.habitsViewModel) var vm  // Tight coupling
}

// Current: ViewModel creates child ViewModels
func makeHabitDetailViewModel(for habit: Habit?) -> HabitDetailViewModel {
    return HabitDetailViewModel(habit: habit)  // Direct instantiation
}
```

### Proposed DI Through Coordinators
```swift
// Coordinator handles all DI
class HabitsCoordinator {
    private let container: Container
    
    func showHabitDetail(for habit: Habit?) {
        let viewModel = container.habitDetailViewModel(for: habit)
        let view = HabitDetailView(viewModel: viewModel)
        navigationController.push(view)
    }
}

// View receives dependencies
struct HabitsView: View {
    let viewModel: HabitsViewModel  // Injected by coordinator
    @EnvironmentObject var coordinator: HabitsCoordinator
}
```

## Benefits

### 1. Separation of Concerns
- Views: UI rendering only
- ViewModels: Business logic only  
- Coordinators: Navigation and DI only

### 2. Testability
- Mock coordinators for UI tests
- Test navigation flows independently
- Verify DI configuration

### 3. Flexibility
- Easy to change navigation flows
- A/B test different user journeys
- Platform-specific navigation (iPad vs iPhone)

### 4. Maintainability
- Single place to update navigation logic
- Clear navigation graph
- Reduced coupling between features

## Migration Strategy

### Step 1: Parallel Implementation
- Build coordinator system alongside existing navigation
- No breaking changes initially

### Step 2: Gradual Migration
- Start with leaf views (no children)
- Move to complex flows (habits, overview)
- Finally migrate root navigation

### Step 3: Cleanup
- Remove old navigation code from ViewModels
- Delete makeViewModel factory methods
- Update documentation

## Success Metrics

### Quantitative
- 50% reduction in navigation-related code in ViewModels
- 0 direct ViewModel instantiations in Views
- 100% of navigation through coordinators
- 30% improvement in navigation test coverage

### Qualitative
- Easier to understand navigation flows
- Simplified deep link implementation
- Better separation of concerns
- Improved code reusability

## Risk Mitigation

### Risk 1: Large Refactoring
**Mitigation**: Incremental migration, feature flag for rollback

### Risk 2: Team Learning Curve
**Mitigation**: Documentation, code examples, pair programming

### Risk 3: Performance Impact
**Mitigation**: Lazy loading, memory profiling, coordinator lifecycle management

## Code Examples

### Before: Current Navigation
```swift
// In HabitsViewModel
public func selectHabit(_ habit: Habit) {
    selectedHabit = habit  // View watches this
}

// In HabitsView
.sheet(item: $vm.selectedHabit) { habit in
    let detailVM = vm.makeHabitDetailViewModel(for: habit)
    HabitDetailView(vm: detailVM)
}
```

### After: Coordinator Navigation
```swift
// In HabitsViewModel
public func selectHabit(_ habit: Habit) {
    coordinator.showHabitDetail(for: habit)
}

// In HabitsCoordinator
func showHabitDetail(for habit: Habit) {
    let viewModel = container.habitDetailViewModel(for: habit)
    let view = HabitDetailView(viewModel: viewModel)
    present(view, animated: true)
}
```

## Timeline

- **Week 1**: Foundation and core coordinators
- **Week 2**: Feature coordinators and migration start
- **Week 3**: Complete migration and testing
- **Week 4**: Advanced features and optimization

## Conclusion

The Coordinator pattern will provide a robust, scalable navigation architecture that:
- Centralizes navigation logic
- Improves dependency injection
- Enhances testability
- Reduces coupling
- Simplifies deep linking
- Provides better analytics hooks

This investment will pay dividends in maintainability and feature velocity as the app grows.