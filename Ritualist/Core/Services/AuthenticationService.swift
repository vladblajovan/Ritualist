import Foundation
import Observation
import SwiftUI

// MARK: - Authentication Service Protocol

@MainActor
public protocol AuthenticationService {
    /// Current authentication state
    var authState: AuthState { get }
    
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

@MainActor
public protocol UserSessionProtocol {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var isPremiumUser: Bool { get }
    var authService: any AuthenticationService { get }
    
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func updateUser(_ user: User) async throws
}

// MARK: - Session Management

@MainActor @Observable
public final class UserSession: UserSessionProtocol {
    public private(set) var currentUser: User?
    public private(set) var isAuthenticated = false
    public private(set) var isPremiumUser = false
    
    public let authService: any AuthenticationService
    
    // Task for observing auth state changes
    private var observationTask: Task<Void, Never>?
    
    public init(authService: any AuthenticationService) {
        self.authService = authService
        setupStateObservation()
    }
    
    deinit {
        // Task cleanup handled automatically
    }
    
    // Clean up observation task when needed
    public func stopObservation() {
        observationTask?.cancel()
        observationTask = nil
    }
    
    private func setupStateObservation() {
        observationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            // Use withObservationTracking to react to authState changes
            while !Task.isCancelled {
                withObservationTracking {
                    self.updateState(from: self.authService.authState)
                } onChange: {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.updateState(from: self.authService.authState)
                    }
                }
                
                // Small delay to prevent tight loops
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
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
        // Direct sign-out through authentication service
        try await authService.signOut()
    }
    
    public func updateUser(_ user: User) async throws {
        _ = try await authService.updateUser(user)
        // The updated user will be automatically reflected through authStatePublisher
    }
}

// MARK: - No-Op Implementations for Environment Defaults

@MainActor @Observable
public final class NoOpAuthenticationService: AuthenticationService {
    public var authState: AuthState = .unauthenticated
    
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

@MainActor @Observable
public final class NoOpUserSession: UserSessionProtocol {
    public private(set) var currentUser: User?
    public private(set) var isAuthenticated = false
    public private(set) var isPremiumUser = false
    
    public let authService: any AuthenticationService
    
    public init() {
        self.authService = NoOpAuthenticationService()
    }
    
    public func signIn(email: String, password: String) async throws {}
    public func signOut() async throws {}
    public func updateUser(_ user: User) async throws {}
}