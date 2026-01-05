//
//  UserService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation
import Observation

/// Service that manages the current user's profile.
/// Loads from local repository and listens for profile changes.
@MainActor
public protocol UserService: Sendable {
    /// Current user profile (loaded from repository)
    var currentProfile: UserProfile { get }

    /// Load profile from repository if not already loaded
    func loadProfileIfNeeded() async

    /// Update user profile
    func updateProfile(_ profile: UserProfile) async throws
}

// MARK: - Default Implementation

/// Default UserService implementation that loads/saves profile via use cases
/// and listens for profile change notifications.
@MainActor @Observable
public final class DefaultUserService: UserService, Sendable {
    private var _currentProfile = UserProfile()
    private var hasLoadedProfile = false
    private let loadProfile: LoadProfileUseCase?
    private let saveProfile: SaveProfileUseCase?
    private let errorHandler: ErrorHandler?
    // nonisolated(unsafe) because NSObjectProtocol isn't Sendable, but this singleton
    // is only deallocated on app termination, making cross-isolation access safe
    nonisolated(unsafe) private var profileChangeObserver: NSObjectProtocol?

    public init(
        loadProfile: LoadProfileUseCase? = nil,
        saveProfile: SaveProfileUseCase? = nil,
        errorHandler: ErrorHandler? = nil
    ) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.errorHandler = errorHandler

        // Initialize with default profile
        _currentProfile = UserProfile(name: "")

        // Listen for profile changes from other parts of the app (e.g., Settings)
        setupProfileChangeObserver()

        // Note: Profile is loaded on-demand via loadProfileIfNeeded() to avoid
        // race conditions with SwiftUI setup that cause Combine threading warnings
    }

    private func setupProfileChangeObserver() {
        profileChangeObserver = NotificationCenter.default.addObserver(
            forName: .userProfileDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let updatedProfile = notification.object as? UserProfile {
                Task { @MainActor in
                    self._currentProfile = updatedProfile
                }
            }
        }
    }

    deinit {
        if let observer = profileChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public func loadProfileIfNeeded() async {
        guard !hasLoadedProfile else { return }
        guard let loadProfile = loadProfile else { return }

        hasLoadedProfile = true

        do {
            let profile = try await loadProfile.execute()
            _currentProfile = profile
        } catch {
            await errorHandler?.logError(
                error,
                context: ErrorContext.userInterface + "_profile_load",
                additionalProperties: ["operation": "loadProfileIfNeeded"]
            )
        }
    }

    public var currentProfile: UserProfile {
        _currentProfile
    }

    public func updateProfile(_ profile: UserProfile) async throws {
        _currentProfile = profile
        _currentProfile.updatedAt = Date()

        // Save to repository
        if let saveProfile = saveProfile {
            do {
                try await saveProfile.execute(_currentProfile)
            } catch {
                await errorHandler?.logError(
                    error,
                    context: ErrorContext.userInterface + "_profile_sync",
                    additionalProperties: [
                        "operation": "updateProfile_sync",
                        "profile_name": profile.name ?? "unnamed"
                    ]
                )
            }
        }
    }

}
