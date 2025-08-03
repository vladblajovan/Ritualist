# MainActor Refactoring Plan

## 🎯 Objective

Reduce the number of `@MainActor` annotations throughout the codebase by separating UI concerns from business logic, improving performance and testability while maintaining clean architecture principles.

## 📊 Current State Analysis

### Current MainActor Usage

**Services with @MainActor:**
- `AuthenticationService` protocol + implementations
- `UserSessionProtocol` protocol + implementations  
- `PaywallService` protocol + implementations
- `FeatureGatingService` (7 properties + 2 methods)

**UseCases with @MainActor:**
- `ResetPurchaseStateUseCase.execute()`
- `GetPurchaseStateUseCase.execute()`

**Dependency Injection:**
- `AppDI.createMinimal()` method
- `AppContainerKey.defaultValue` property

### Root Cause Analysis

The current architecture violates the **Single Responsibility Principle** by mixing:
- **Business Logic** (purchase processing, authentication, feature validation)
- **UI State Management** (reactive properties for SwiftUI)

This creates a cascade effect where everything becomes MainActor-bound.

## 🏗️ Proposed Architecture

### Separation Pattern

```swift
// BEFORE: Mixed concerns
@MainActor
public protocol PaywallService {
    var purchaseState: PurchaseState { get }  // UI state
    func purchase(_ product: Product) async throws -> Bool  // Business logic
}

// AFTER: Separated concerns
public protocol PaywallBusinessService {  // No @MainActor
    func purchase(_ product: Product) async throws -> Bool
    func loadProducts() async throws -> [Product]
    func restorePurchases() async throws -> Bool
}

@MainActor @Observable
public class PaywallUIState {  // UI state management
    @Published var purchaseState: PurchaseState = .idle
    @Published var products: [Product] = []
    
    private let businessService: PaywallBusinessService
    
    // Bridge methods that call business service and update UI state
}
```

## 📋 Refactoring Tasks

### Phase 1: Business Service Extraction (2-3 days)

#### Task 1.1: Extract PaywallBusinessService
- [ ] Create `PaywallBusinessService` protocol (no @MainActor)
- [ ] Create `PaywallBusinessServiceImpl` implementation
- [ ] Create `PaywallUIState` @MainActor @Observable class
- [ ] Update `PaywallViewModel` to use separated services
- [ ] Update all Paywall UseCases to use business service
- [ ] Test paywall functionality end-to-end

#### Task 1.2: Extract AuthBusinessService  
- [ ] Create `AuthBusinessService` protocol (no @MainActor)
- [ ] Create `AuthBusinessServiceImpl` implementation
- [ ] Create `AuthUIState` @MainActor @Observable class
- [ ] Update `UserSession` to use separated services
- [ ] Update all Auth UseCases to use business service
- [ ] Test authentication flows end-to-end

#### Task 1.3: Extract FeatureGatingBusinessService
- [ ] Create `FeatureGatingBusinessService` protocol (no @MainActor)
- [ ] Create `FeatureGatingBusinessServiceImpl` implementation
- [ ] Remove @MainActor from business logic methods
- [ ] Keep @MainActor only for UI-bound computed properties
- [ ] Update UseCases to use business service
- [ ] Test feature gating functionality

### Phase 2: UseCase Modernization (1-2 days)

#### Task 2.1: Remove @MainActor from UseCases
- [ ] Update `ResetPurchaseStateUseCase` to use business service
- [ ] Update `GetPurchaseStateUseCase` to return business state
- [ ] Remove @MainActor annotations from UseCase execute methods
- [ ] Test all UseCase implementations

#### Task 2.2: Update ViewModels
- [ ] Update `PaywallViewModel` to bridge business state to UI state
- [ ] Update other ViewModels to use separated services
- [ ] Ensure reactive UI updates still work correctly
- [ ] Test all ViewModel functionality

### Phase 3: Dependency Injection Cleanup (1 day)

#### Task 3.1: Update AppDI Container
- [ ] Remove @MainActor from `createMinimal()` method
- [ ] Update container to provide business services (non-MainActor)
- [ ] Create separate UI state providers where needed
- [ ] Update environment defaults to use non-MainActor services

#### Task 3.2: Update Service Implementations
- [ ] Remove @MainActor from NoOp implementations
- [ ] Remove @MainActor from Simple implementations  
- [ ] Ensure Mock implementations work without MainActor
- [ ] Test all service variants

### Phase 4: Testing & Validation (1 day)

#### Task 4.1: Comprehensive Testing
- [ ] Run full build and ensure zero errors
- [ ] Test all major user flows (auth, paywall, habits)
- [ ] Verify UI reactivity still works correctly
- [ ] Performance test to ensure background processing works

#### Task 4.2: Architecture Validation
- [ ] Verify business logic can run on background threads
- [ ] Confirm UI updates happen on main thread
- [ ] Validate Clean Architecture boundaries are maintained
- [ ] Document new architecture patterns

## 🎯 Expected Benefits

### Performance Improvements
- ✅ **Background Processing**: Business logic can run off main thread
- ✅ **Improved Responsiveness**: UI remains responsive during heavy operations
- ✅ **Better Concurrency**: Parallel processing of business operations

### Architecture Improvements  
- ✅ **Clear Separation**: UI concerns vs business logic
- ✅ **Better Testability**: Business logic easily tested without UI
- ✅ **Maintainability**: Easier to reason about and modify
- ✅ **Scalability**: Pattern supports complex business workflows

### Development Experience
- ✅ **Reduced @MainActor**: Fewer concurrency constraints
- ✅ **Cleaner Code**: Single responsibility per class
- ✅ **Better Error Handling**: Business errors vs UI errors separated

## ⚠️ Risks & Considerations

### Migration Risks
- **UI Reactivity**: Must ensure state changes still trigger UI updates
- **Race Conditions**: Careful coordination between business and UI layers
- **Testing Overhead**: More components to test individually

### Complexity Trade-offs
- **More Classes**: Increased number of files and dependencies
- **Bridge Logic**: ViewModels become bridge between business and UI
- **Learning Curve**: Team needs to understand new patterns

## 📈 Success Metrics

### Before Refactoring
- @MainActor annotations: ~15+ occurrences
- Services mixing UI/business concerns: 4 services
- Business logic tied to main thread: 100%

### After Refactoring Target
- @MainActor annotations: ~5 occurrences (UI state only)
- Pure business services: 4 services
- Business logic on background threads: 80%+
- UI responsiveness: Improved
- Test coverage: Maintained or improved

## 🚀 Implementation Strategy

### Recommended Approach
1. **Incremental Migration**: One service at a time
2. **Feature Flags**: Keep old implementation during transition
3. **Parallel Development**: New pattern alongside existing code
4. **Thorough Testing**: Validate each phase before proceeding

### Timeline Estimate
- **Total Duration**: 5-7 days
- **Phase 1**: 2-3 days (core service extraction)
- **Phase 2**: 1-2 days (UseCase updates)  
- **Phase 3**: 1 day (DI cleanup)
- **Phase 4**: 1 day (testing/validation)

## 📚 Reference Implementation

When ready to implement, start with PaywallService as it has the clearest separation between:
- **Business**: Purchase processing, product loading, receipt validation
- **UI**: Purchase state, loading indicators, error messages

This will establish the pattern for other services to follow.

---

*Created: 2025-08-01*
*Status: Planning Phase*
*Priority: Medium (Future Enhancement)*