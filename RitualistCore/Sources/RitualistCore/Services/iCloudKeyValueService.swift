//
//  iCloudKeyValueService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 27.11.2025.
//
//  Service for managing iCloud key-value storage using NSUbiquitousKeyValueStore.
//  This is used for small, fast-syncing flags like onboarding completion status.
//  Syncs independently from CloudKit/CoreData - almost instantaneous.
//

import Foundation

// MARK: - Protocol

public protocol iCloudKeyValueService: Sendable {
    /// Check if onboarding has been completed (syncs from iCloud)
    func hasCompletedOnboarding() -> Bool

    /// Mark onboarding as completed (syncs to iCloud)
    func setOnboardingCompleted()

    /// Synchronize with iCloud (call on app launch)
    func synchronize()

    /// Synchronize with iCloud and wait for completion (with timeout)
    /// Returns true if sync completed, false if timed out
    func synchronizeAndWait(timeout: TimeInterval) async -> Bool

    /// Reset onboarding flag (for testing/debug)
    func resetOnboardingFlag()

    // MARK: - Local-only flags (not synced via iCloud)

    /// Check if THIS device has completed onboarding (local only, not synced)
    /// This is separate from iCloud flag to detect returning users on new devices
    func hasCompletedOnboardingLocally() -> Bool

    /// Mark onboarding as completed on THIS device (local only)
    func setOnboardingCompletedLocally()

    /// Reset local device flag (for testing/debug)
    func resetLocalOnboardingFlag()
}

// MARK: - Keys

private enum iCloudKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}

private enum LocalKeys {
    /// Local-only key stored in UserDefaults (not synced)
    static let hasCompletedOnboardingLocally = "hasCompletedOnboardingLocally_device"
}

// MARK: - Implementation

public final class DefaultiCloudKeyValueService: iCloudKeyValueService, @unchecked Sendable {
    private let store: NSUbiquitousKeyValueStore
    private let userDefaults: UserDefaults
    private let logger: DebugLogger

    public init(logger: DebugLogger, userDefaults: UserDefaults = .standard) {
        self.store = NSUbiquitousKeyValueStore.default
        self.userDefaults = userDefaults
        self.logger = logger

        // Register for external change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    public func hasCompletedOnboarding() -> Bool {
        let completed = store.bool(forKey: iCloudKeys.hasCompletedOnboarding)
        logger.log(
            "☁️ iCloud KV: hasCompletedOnboarding = \(completed)",
            level: .debug,
            category: .system
        )
        return completed
    }

    public func setOnboardingCompleted() {
        store.set(true, forKey: iCloudKeys.hasCompletedOnboarding)
        store.synchronize()
        logger.log(
            "☁️ iCloud KV: Set hasCompletedOnboarding = true",
            level: .info,
            category: .system
        )
    }

    public func synchronize() {
        let result = store.synchronize()
        logger.log(
            "☁️ iCloud KV: Synchronize called, result = \(result)",
            level: .debug,
            category: .system
        )
    }

    public func synchronizeAndWait(timeout: TimeInterval) async -> Bool {
        // Start sync
        let syncStarted = store.synchronize()
        guard syncStarted else {
            logger.log("☁️ iCloud KV: Synchronize failed to start", level: .warning, category: .system)
            return false
        }

        logger.log("☁️ iCloud KV: Waiting for sync (timeout: \(timeout)s)", level: .debug, category: .system)

        // Use a single continuation that's guaranteed to be resumed by either notification or timeout
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            var hasResumed = false
            let lock = NSLock()
            var observer: NSObjectProtocol?

            // Helper to safely resume only once
            func resumeOnce(with value: Bool) {
                lock.lock()
                defer { lock.unlock() }
                guard !hasResumed else { return }
                hasResumed = true
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                continuation.resume(returning: value)
            }

            // Listen for notification
            observer = NotificationCenter.default.addObserver(
                forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: self.store,
                queue: .main
            ) { _ in
                resumeOnce(with: true)
            }

            // Start timeout timer
            Task {
                try? await Task.sleep(for: .seconds(timeout))
                resumeOnce(with: false)
            }
        }

        logger.log("☁️ iCloud KV: Sync wait completed, success = \(result)", level: .debug, category: .system)
        return result
    }

    public func resetOnboardingFlag() {
        store.removeObject(forKey: iCloudKeys.hasCompletedOnboarding)
        store.synchronize()
        logger.log(
            "☁️ iCloud KV: Reset hasCompletedOnboarding flag",
            level: .info,
            category: .system
        )
    }

    // MARK: - Local-only flags

    public func hasCompletedOnboardingLocally() -> Bool {
        let completed = userDefaults.bool(forKey: LocalKeys.hasCompletedOnboardingLocally)
        logger.log(
            "📱 Local: hasCompletedOnboardingLocally = \(completed)",
            level: .debug,
            category: .system
        )
        return completed
    }

    public func setOnboardingCompletedLocally() {
        userDefaults.set(true, forKey: LocalKeys.hasCompletedOnboardingLocally)
        logger.log(
            "📱 Local: Set hasCompletedOnboardingLocally = true",
            level: .info,
            category: .system
        )
    }

    public func resetLocalOnboardingFlag() {
        userDefaults.removeObject(forKey: LocalKeys.hasCompletedOnboardingLocally)
        logger.log(
            "📱 Local: Reset hasCompletedOnboardingLocally flag",
            level: .info,
            category: .system
        )
    }

    // MARK: - Private

    @objc private func handleExternalChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        let reasonString: String
        switch reason {
        case NSUbiquitousKeyValueStoreServerChange:
            reasonString = "server change"
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            reasonString = "initial sync"
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            reasonString = "quota violation"
        case NSUbiquitousKeyValueStoreAccountChange:
            reasonString = "account change"
        default:
            reasonString = "unknown (\(reason))"
        }

        logger.log(
            "☁️ iCloud KV: External change detected",
            level: .info,
            category: .system,
            metadata: ["reason": reasonString]
        )

        // Post notification for any observers
        NotificationCenter.default.post(
            name: .iCloudKeyValueDidChange,
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - Notification Name

public extension Notification.Name {
    static let iCloudKeyValueDidChange = Notification.Name("iCloudKeyValueDidChange")
}
