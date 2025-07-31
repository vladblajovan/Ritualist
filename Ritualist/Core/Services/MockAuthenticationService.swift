import Foundation
import Combine

// MARK: - Mock Authentication Service

@MainActor
public final class MockAuthenticationService: AuthenticationService, ObservableObject {
    @Published public var authState: AuthState = .unauthenticated
    
    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }
    
    public var isAuthenticated: Bool {
        authState.isAuthenticated
    }
    
    public var isPremiumUser: Bool {
        authState.currentUser?.isPremiumUser ?? false
    }
    
    // Mock test users
    private var mockUsers: [String: User] = [
        "free@test.com": User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            email: "free@test.com",
            name: "Free User",
            subscriptionPlan: .free,
            subscriptionExpiryDate: nil
        ),
        "monthly@test.com": User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            email: "monthly@test.com",
            name: "Monthly Subscriber",
            subscriptionPlan: .monthly,
            subscriptionExpiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
        ),
        "annual@test.com": User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            email: "annual@test.com",
            name: "Annual Subscriber",
            subscriptionPlan: .annual,
            subscriptionExpiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        )
    ]
    
    private let validPassword = "test123"
    
    public init() {
        // Try to restore previous session from UserDefaults
        restoreSession()
    }
    
    public func signIn(credentials: AuthCredentials) async throws -> User {
        authState = .authenticating
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Validate credentials
        guard let user = mockUsers[credentials.email],
              credentials.password == validPassword else {
            authState = .error("Invalid credentials")
            throw AuthError.invalidCredentials
        }
        
        // Save session
        UserDefaults.standard.set(user.email, forKey: "current_user_email")
        
        authState = .authenticated(user)
        return user
    }
    
    public func signOut() async throws {
        authState = .authenticating
        
        // Simulate logout delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Clear session
        UserDefaults.standard.removeObject(forKey: "current_user_email")
        
        authState = .unauthenticated
    }
    
    public func getCurrentUser() async -> User? {
        authState.currentUser
    }
    
    public func updateUser(_ user: User) async throws -> User {
        // Don't change auth state to .authenticating during user updates
        // This prevents the brief flash to login screen
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Update the user data with current timestamp
        var updatedUser = user
        updatedUser.updatedAt = Date()
        
        // For mock implementation, we'll update the mockUsers dictionary
        // In a real implementation, this would persist to a backend service
        let userEmail = updatedUser.email
        
        // Update the mockUsers dictionary
        mockUsers[userEmail] = updatedUser
        
        // Update the current auth state with the updated user
        authState = .authenticated(updatedUser)
        
        return updatedUser
    }
    
    private func restoreSession() {
        guard let email = UserDefaults.standard.string(forKey: "current_user_email"),
              let user = mockUsers[email] else {
            authState = .unauthenticated
            return
        }
        
        authState = .authenticated(user)
    }
}

// MARK: - Debug Helper

extension MockAuthenticationService {
    /// Debug method to get all available test accounts
    public static var testAccounts: [(email: String, password: String, plan: SubscriptionPlan)] {
        [
            ("free@test.com", "test123", .free),
            ("monthly@test.com", "test123", .monthly),
            ("annual@test.com", "test123", .annual)
        ]
    }
}