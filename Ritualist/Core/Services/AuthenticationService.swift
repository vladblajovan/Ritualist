import Foundation
import Combine

// MARK: - Authentication Service Protocol

public protocol AuthenticationService: ObservableObject {
    /// Current authentication state
    var authState: AuthState { get }
    
    /// Publisher for authentication state changes
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }
    
    /// Sign in with email and password
    func signIn(credentials: AuthCredentials) async throws -> User
    
    /// Sign out current user
    func signOut() async throws
    
    /// Get current authenticated user
    func getCurrentUser() async -> User?
    
    /// Update current user information
    func updateUser(_ user: User) async throws -> User
    
    /// Check if user is authenticated
    var isAuthenticated: Bool { get }
    
    /// Check if current user has premium subscription
    var isPremiumUser: Bool { get }
}

// MARK: - User Session Protocol

public protocol UserSessionProtocol: ObservableObject {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var isPremiumUser: Bool { get }
    var authService: any AuthenticationService { get }
    
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func updateUser(_ user: User) async throws
}

// MARK: - Session Management

@MainActor
public final class UserSession: UserSessionProtocol {
    @Published public private(set) var currentUser: User?
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var isPremiumUser = false
    
    public let authService: any AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    // State coordination support
    private weak var stateCoordinator: (any StateCoordinatorProtocol)?
    
    public init(authService: any AuthenticationService) {
        self.authService = authService
        setupStateObservation()
    }
    
    // Method to set state coordinator (called by DI container)
    public func setStateCoordinator(_ coordinator: any StateCoordinatorProtocol) {
        self.stateCoordinator = coordinator
    }
    
    private func setupStateObservation() {
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authState in
                self?.updateState(from: authState)
            }
            .store(in: &cancellables)
    }
    
    private func updateState(from authState: AuthState) {
        switch authState {
        case .authenticated(let user):
            currentUser = user
            isAuthenticated = true
            isPremiumUser = user.isPremiumUser
        case .unauthenticated, .authenticating, .error:
            currentUser = nil
            isAuthenticated = false
            isPremiumUser = false
        }
    }
    
    public func signIn(email: String, password: String) async throws {
        let credentials = AuthCredentials(email: email, password: password)
        _ = try await authService.signIn(credentials: credentials)
    }
    
    public func signOut() async throws {
        // If we have a state coordinator, use it for coordinated sign-out
        if let coordinator = stateCoordinator, !coordinator.isExecutingTransaction {
            try await coordinator.executeTransaction([.clearUserSession])
        } else {
            // Fallback to direct sign-out
            try await authService.signOut()
        }
    }
    
    public func updateUser(_ user: User) async throws {
        _ = try await authService.updateUser(user)
        // The updated user will be automatically reflected through authStatePublisher
    }
}

// MARK: - No-Op Implementations for Environment Defaults

public final class NoOpAuthenticationService: AuthenticationService, ObservableObject {
    @Published public var authState: AuthState = .unauthenticated
    
    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }
    
    public var isAuthenticated: Bool { false }
    public var isPremiumUser: Bool { false }
    
    public init() {}
    
    public func signIn(credentials: AuthCredentials) async throws -> User {
        throw AuthError.unknown("NoOp implementation")
    }
    
    public func signOut() async throws {}
    
    public func getCurrentUser() async -> User? { nil }
    
    public func updateUser(_ user: User) async throws -> User {
        throw AuthError.unknown("NoOp implementation")
    }
}

public final class NoOpUserSession: UserSessionProtocol, ObservableObject {
    @Published public private(set) var currentUser: User?
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var isPremiumUser = false
    
    public let authService: any AuthenticationService
    
    public init() {
        self.authService = NoOpAuthenticationService()
    }
    
    public func signIn(email: String, password: String) async throws {}
    public func signOut() async throws {}
    public func updateUser(_ user: User) async throws {}
}