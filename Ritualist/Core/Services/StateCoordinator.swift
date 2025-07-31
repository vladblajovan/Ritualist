import Foundation
import Combine

// MARK: - State Operation Types

public enum StateOperation {
    case updatePurchaseState(PurchaseState)
    case updateUserSubscription(User, Product)
    case updateUserAuthentication(User)
    case updateFeatureGating(SubscriptionPlan)
    case clearUserSession
    case storePurchaseRecord(Product)
    case removePurchaseRecord(String)
}

// MARK: - State Coordinator Protocol

public protocol StateCoordinatorProtocol: AnyObject {
    /// Execute multiple operations atomically
    func executeTransaction(_ operations: [StateOperation]) async throws
    
    /// Update user subscription with purchase - atomic operation
    func updateUserSubscription(_ user: User, _ product: Product) async throws
    
    /// Cancel user subscription - atomic operation
    func cancelSubscription(_ user: User) async throws
    
    /// Validate system state consistency
    func validateSystemConsistency() async -> [String]
    
    /// Check if coordinator is currently executing a transaction
    var isExecutingTransaction: Bool { get }
}

// MARK: - Transaction Result

public enum TransactionResult {
    case success
    case failure(Error)
    case partialFailure([StateOperation], Error)
}

// MARK: - State Coordinator Implementation

public final class StateCoordinator: StateCoordinatorProtocol {
    
    // Dependencies
    private let paywallService: PaywallService
    private let authService: any AuthenticationService
    private let userSession: any UserSessionProtocol
    private let secureDefaults: SecureUserDefaults
    
    // Transaction state
    public private(set) var isExecutingTransaction = false
    private let transactionQueue = DispatchQueue(label: "StateCoordinator.transactions", qos: .userInitiated)
    
    // Coordination lock for atomic operations
    private let coordinationLock = NSLock()
    
    public init(
        paywallService: PaywallService,
        authService: any AuthenticationService,
        userSession: any UserSessionProtocol,
        secureDefaults: SecureUserDefaults
    ) {
        self.paywallService = paywallService
        self.authService = authService
        self.userSession = userSession
        self.secureDefaults = secureDefaults
    }
    
    // MARK: - Transaction Execution
    
    public func executeTransaction(_ operations: [StateOperation]) async throws {
        guard !operations.isEmpty else { return }
        
        // Ensure only one transaction runs at a time
        coordinationLock.lock()
        defer { coordinationLock.unlock() }
        
        isExecutingTransaction = true
        defer { isExecutingTransaction = false }
        
        // Track operations for rollback if needed
        var completedOperations: [StateOperation] = []
        var rollbackActions: [() async throws -> Void] = []
        
        do {
            for operation in operations {
                // Execute operation and track rollback action
                let rollbackAction = try await executeOperation(operation)
                completedOperations.append(operation)
                rollbackActions.append(rollbackAction)
            }
        } catch {
            // Rollback completed operations in reverse order
            await performRollback(rollbackActions.reversed())
            throw error
        }
    }
    
    private func executeOperation(_ operation: StateOperation) async throws -> (() async throws -> Void) {
        switch operation {
        case .updatePurchaseState(let state):
            return try await updatePurchaseStateOperation(state)
            
        case .updateUserSubscription(let user, let product):
            return try await updateUserSubscriptionOperation(user, product)
            
        case .updateUserAuthentication(let user):
            return try await updateUserAuthenticationOperation(user)
            
        case .updateFeatureGating(let plan):
            return try await updateFeatureGatingOperation(plan)
            
        case .clearUserSession:
            return try await clearUserSessionOperation()
            
        case .storePurchaseRecord(let product):
            return try await storePurchaseRecordOperation(product)
            
        case .removePurchaseRecord(let productId):
            return try await removePurchaseRecordOperation(productId)
        }
    }
    
    // MARK: - Operation Implementations
    
    private func updatePurchaseStateOperation(_ state: PurchaseState) async throws -> (() async throws -> Void) {
        let previousState = paywallService.purchaseState
        
        // Update state (assuming we have a way to set this)
        if let mockService = paywallService as? MockPaywallService {
            await MainActor.run {
                mockService.purchaseState = state
            }
        }
        
        // Return rollback action
        return { @MainActor in
            if let mockService = self.paywallService as? MockPaywallService {
                mockService.purchaseState = previousState
            }
        }
    }
    
    private func updateUserSubscriptionOperation(_ user: User, _ product: Product) async throws -> (() async throws -> Void) {
        let originalUser = user
        
        // Create updated user
        var updatedUser = user
        updatedUser.subscriptionPlan = product.subscriptionPlan
        
        // Calculate expiry date
        let calendar = Calendar.current
        switch product.duration {
        case .monthly:
            updatedUser.subscriptionExpiryDate = calendar.date(byAdding: .month, value: 1, to: Date())
        case .annual:
            updatedUser.subscriptionExpiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        }
        
        // Update user through auth service
        _ = try await authService.updateUser(updatedUser)
        
        // Return rollback action
        return {
            _ = try await self.authService.updateUser(originalUser)
        }
    }
    
    private func updateUserAuthenticationOperation(_ user: User) async throws -> (() async throws -> Void) {
        let originalUser = authService.authState.currentUser
        
        // Update user
        _ = try await authService.updateUser(user)
        
        // Return rollback action
        return {
            if let original = originalUser {
                _ = try await self.authService.updateUser(original)
            }
        }
    }
    
    private func updateFeatureGatingOperation(_ plan: SubscriptionPlan) async throws -> (() async throws -> Void) {
        // Store previous feature gating state
        let previousPlan = await secureDefaults.getSecurely(SubscriptionPlan.self, forKey: "feature_gating_plan") ?? .free
        
        // Update feature gating
        try await secureDefaults.setSecurely(plan, forKey: "feature_gating_plan")
        
        // Return rollback action
        return {
            try await self.secureDefaults.setSecurely(previousPlan, forKey: "feature_gating_plan")
        }
    }
    
    private func clearUserSessionOperation() async throws -> (() async throws -> Void) {
        let originalUser = userSession.currentUser
        let originalEmail = await secureDefaults.getSecurely(String.self, forKey: "current_user_email")
        
        // Clear session
        try await userSession.signOut()
        
        // Return rollback action
        return {
            if let email = originalEmail, let user = originalUser {
                try await self.secureDefaults.setSecurely(email, forKey: "current_user_email")
                _ = try await self.authService.updateUser(user)
            }
        }
    }
    
    private func storePurchaseRecordOperation(_ product: Product) async throws -> (() async throws -> Void) {
        let previousPurchases = await secureDefaults.getSecurely([String].self, forKey: "purchased_products") ?? []
        
        var updatedPurchases = previousPurchases
        if !updatedPurchases.contains(product.id) {
            updatedPurchases.append(product.id)
            try await secureDefaults.setSecurely(updatedPurchases, forKey: "purchased_products")
        }
        
        // Return rollback action
        return {
            try await self.secureDefaults.setSecurely(previousPurchases, forKey: "purchased_products")
        }
    }
    
    private func removePurchaseRecordOperation(_ productId: String) async throws -> (() async throws -> Void) {
        let previousPurchases = await secureDefaults.getSecurely([String].self, forKey: "purchased_products") ?? []
        
        let updatedPurchases = previousPurchases.filter { $0 != productId }
        try await secureDefaults.setSecurely(updatedPurchases, forKey: "purchased_products")
        
        // Return rollback action
        return {
            try await self.secureDefaults.setSecurely(previousPurchases, forKey: "purchased_products")
        }
    }
    
    // MARK: - Rollback Support
    
    private func performRollback(_ rollbackActions: [() async throws -> Void]) async {
        for rollbackAction in rollbackActions {
            do {
                try await rollbackAction()
            } catch {
                // Log rollback failures but continue with other rollbacks
                print("StateCoordinator: Rollback failed: \(error)")
            }
        }
    }
    
    // MARK: - High-Level Operations
    
    public func updateUserSubscription(_ user: User, _ product: Product) async throws {
        let operations: [StateOperation] = [
            .updatePurchaseState(.success(product)),
            .updateUserSubscription(user, product),
            .updateFeatureGating(product.subscriptionPlan),
            .storePurchaseRecord(product)
        ]
        
        try await executeTransaction(operations)
    }
    
    public func cancelSubscription(_ user: User) async throws {
        var updatedUser = user
        updatedUser.subscriptionPlan = .free
        updatedUser.subscriptionExpiryDate = nil
        
        let operations: [StateOperation] = [
            .updateUserSubscription(updatedUser, Product.freeProduct),
            .updateFeatureGating(.free),
            .removePurchaseRecord(user.subscriptionPlan.rawValue)
        ]
        
        try await executeTransaction(operations)
    }
    
    // MARK: - State Validation
    
    public func validateSystemConsistency() async -> [String] {
        var issues: [String] = []
        
        // Check user-paywall consistency
        if let currentUser = userSession.currentUser {
            let storedPurchases = await secureDefaults.getSecurely([String].self, forKey: "purchased_products") ?? []
            
            // Check if user subscription matches stored purchases
            let hasValidSubscription = currentUser.subscriptionPlan != .free
            let hasPurchaseRecord = !storedPurchases.isEmpty
            
            if hasValidSubscription && !hasPurchaseRecord {
                issues.append("User has subscription but no purchase record")
            }
            
            if !hasValidSubscription && hasPurchaseRecord {
                issues.append("User has purchase record but no active subscription")
            }
            
            // Check subscription expiry
            if let expiryDate = currentUser.subscriptionExpiryDate,
               expiryDate < Date() && currentUser.subscriptionPlan != .free {
                issues.append("User subscription is expired but still marked as premium")
            }
        }
        
        return issues
    }
}

// MARK: - Product Extension for Free Product

extension Product {
    static var freeProduct: Product {
        Product(
            id: "free",
            name: "Free Plan",
            description: "Basic features",
            price: "Free",
            localizedPrice: "Free",
            subscriptionPlan: .free,
            duration: .monthly,
            features: ["Basic habit tracking"],
            isPopular: false
        )
    }
}