//
//  DetectiCloudDataUseCase.swift
//  RitualistCore
//
//  Created by Claude on 27.11.2025.
//
//  Detects existing iCloud data to determine onboarding flow type.
//  Used on fresh install to check if user has data from another device.
//

import Foundation
import CoreData

// MARK: - Protocol

public protocol DetectiCloudDataUseCase {
    /// Detects existing iCloud data with timeout.
    /// Waits for NSPersistentStoreRemoteChange notification before checking.
    /// - Parameter timeout: Maximum time to wait for iCloud sync (default 3.5 seconds)
    /// - Returns: OnboardingFlowType based on detected data
    func execute(timeout: TimeInterval) async -> OnboardingFlowType
}

// MARK: - Implementation

public final class DefaultDetectiCloudDataUseCase: DetectiCloudDataUseCase {
    private let checkiCloudStatus: CheckiCloudStatusUseCase
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let profileRepository: ProfileRepository
    private let logger: DebugLogger

    public init(
        checkiCloudStatus: CheckiCloudStatusUseCase,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        profileRepository: ProfileRepository,
        logger: DebugLogger
    ) {
        self.checkiCloudStatus = checkiCloudStatus
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.profileRepository = profileRepository
        self.logger = logger
    }

    public func execute(timeout: TimeInterval = 2.0) async -> OnboardingFlowType {
        logger.log(
            "🔍 Starting iCloud data detection",
            level: .info,
            category: .system,
            metadata: ["timeout": timeout]
        )

        // 1. Check iCloud availability - if not available, exit immediately
        let status = await checkiCloudStatus.execute()

        guard status == .available else {
            logger.log(
                "☁️ iCloud not available - using new user flow (instant)",
                level: .info,
                category: .system,
                metadata: ["status": status.displayMessage]
            )
            return .newUser
        }

        // 2. Check immediately - data might already be synced
        let immediateSummary = await fetchDataSummary()
        if immediateSummary.hasData {
            logger.log(
                "✅ iCloud data already present - using returning user flow",
                level: .info,
                category: .system,
                metadata: [
                    "habitsCount": immediateSummary.habitsCount,
                    "hasProfile": immediateSummary.hasProfile
                ]
            )
            return .returningUser(summary: immediateSummary)
        }

        // 3. Wait for NSPersistentStoreRemoteChange notification
        logger.log(
            "⏳ Waiting for iCloud sync",
            level: .info,
            category: .system
        )

        let didReceiveRemoteChange = await waitForRemoteChangeNotification(timeout: timeout)

        // 4. If we received a notification, check for data
        // First notification is often just metadata - actual data arrives in subsequent ones
        if didReceiveRemoteChange {
            logger.log(
                "📥 Remote change received, checking for data",
                level: .info,
                category: .system
            )

            // Brief pause to let CoreData process
            try? await Task.sleep(for: .milliseconds(300))

            var summary = await fetchDataSummary()
            if summary.hasData {
                logger.log(
                    "✅ iCloud data detected - using returning user flow",
                    level: .info,
                    category: .system,
                    metadata: [
                        "habitsCount": summary.habitsCount,
                        "categoriesCount": summary.categoriesCount,
                        "hasProfile": summary.hasProfile,
                        "profileName": summary.profileName ?? "nil"
                    ]
                )
                return .returningUser(summary: summary)
            }

            // First notification was likely just metadata - wait for actual data
            logger.log(
                "📥 First notification had no data, waiting for more",
                level: .info,
                category: .system
            )

            // Wait for one more notification cycle (habits typically arrive 1-2s after first notification)
            let receivedMore = await waitForRemoteChangeNotification(timeout: 2.5)
            if receivedMore {
                try? await Task.sleep(for: .milliseconds(300))
                summary = await fetchDataSummary()
                if summary.hasData {
                    logger.log(
                        "✅ iCloud data detected on second check - using returning user flow",
                        level: .info,
                        category: .system,
                        metadata: [
                            "habitsCount": summary.habitsCount,
                            "categoriesCount": summary.categoriesCount,
                            "hasProfile": summary.hasProfile,
                            "profileName": summary.profileName ?? "nil"
                        ]
                    )
                    return .returningUser(summary: summary)
                }
            }
        }

        // 5. Final check
        let finalSummary = await fetchDataSummary()

        if finalSummary.hasData {
            logger.log(
                "✅ iCloud data detected on final check - using returning user flow",
                level: .info,
                category: .system,
                metadata: [
                    "habitsCount": finalSummary.habitsCount,
                    "categoriesCount": finalSummary.categoriesCount,
                    "hasProfile": finalSummary.hasProfile,
                    "profileName": finalSummary.profileName ?? "nil"
                ]
            )
            return .returningUser(summary: finalSummary)
        }

        logger.log(
            "⏱️ No iCloud data found - using new user flow",
            level: .info,
            category: .system,
            metadata: ["receivedNotification": didReceiveRemoteChange]
        )
        return .newUser
    }

    // MARK: - Private

    /// Waits for NSPersistentStoreRemoteChange notification with timeout
    /// Returns true if notification was received, false if timeout
    private func waitForRemoteChangeNotification(timeout: TimeInterval) async -> Bool {
        await waitForNotification(.NSPersistentStoreRemoteChange, timeout: timeout)
    }

    /// Waits for context changes that contain habits or profiles (not just any change)
    /// This filters out false positives from local category seeding
    private func waitForRelevantContextChanges(timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            var observer: NSObjectProtocol?
            var timeoutTask: Task<Void, Never>?
            var hasResumed = false

            // Set up notification observer that filters for relevant objects
            observer = NotificationCenter.default.addObserver(
                forName: .NSManagedObjectContextObjectsDidChange,
                object: nil,
                queue: .main
            ) { notification in
                guard !hasResumed else { return }

                // Check if notification contains habits or profiles
                let hasRelevantChanges = self.notificationContainsRelevantObjects(notification)

                guard hasRelevantChanges else {
                    // Ignore this notification - it's probably from category seeding
                    return
                }

                hasResumed = true
                timeoutTask?.cancel()
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                continuation.resume(returning: true)
            }

            // Set up timeout
            timeoutTask = Task {
                try? await Task.sleep(for: .seconds(timeout))
                guard !hasResumed else { return }
                hasResumed = true
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                continuation.resume(returning: false)
            }
        }
    }

    /// Check if notification contains habit or profile objects (not just categories)
    private func notificationContainsRelevantObjects(_ notification: Notification) -> Bool {
        let relevantEntityNames = ["HabitModel", "UserProfileModel", "HabitLogModel"]

        // Check inserted objects
        if let inserted = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for obj in inserted {
                if let entityName = obj.entity.name, relevantEntityNames.contains(entityName) {
                    return true
                }
            }
        }

        // Check updated objects
        if let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for obj in updated {
                if let entityName = obj.entity.name, relevantEntityNames.contains(entityName) {
                    return true
                }
            }
        }

        return false
    }

    /// Generic notification waiter with timeout
    private func waitForNotification(_ name: Notification.Name, timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            var observer: NSObjectProtocol?
            var timeoutTask: Task<Void, Never>?
            var hasResumed = false

            // Set up notification observer
            observer = NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { _ in
                guard !hasResumed else { return }
                hasResumed = true
                timeoutTask?.cancel()
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                continuation.resume(returning: true)
            }

            // Set up timeout
            timeoutTask = Task {
                try? await Task.sleep(for: .seconds(timeout))
                guard !hasResumed else { return }
                hasResumed = true
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                continuation.resume(returning: false)
            }
        }
    }

    private func fetchDataSummary() async -> SyncedDataSummary {
        // Fetch data in parallel
        async let habitsResult = fetchHabits()
        async let categoriesResult = fetchCategories()
        async let profileResult = fetchProfile()

        let habits = await habitsResult
        let categories = await categoriesResult
        let profile = await profileResult

        // Filter out predefined categories (only count custom ones)
        let customCategoriesCount = categories.filter { !$0.isPredefined }.count

        // Check if profile has meaningful data (name is not empty)
        let hasProfile = profile != nil && !(profile?.name.isEmpty ?? true)

        return SyncedDataSummary(
            habitsCount: habits.count,
            categoriesCount: customCategoriesCount,
            hasProfile: hasProfile,
            profileName: profile?.name,
            profileAvatar: profile?.avatarImageData
        )
    }

    private func fetchHabits() async -> [Habit] {
        do {
            return try await habitRepository.fetchAllHabits()
        } catch {
            logger.log(
                "Failed to fetch habits for detection",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            return []
        }
    }

    private func fetchCategories() async -> [HabitCategory] {
        do {
            return try await categoryRepository.getAllCategories()
        } catch {
            logger.log(
                "Failed to fetch categories for detection",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            return []
        }
    }

    private func fetchProfile() async -> UserProfile? {
        do {
            return try await profileRepository.loadProfile()
        } catch {
            logger.log(
                "Failed to fetch profile for detection",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            return nil
        }
    }
}
