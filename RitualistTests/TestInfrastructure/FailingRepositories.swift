import Foundation
@testable import RitualistCore

/// Reusable failing repository implementations for error path testing
///
/// These test doubles simulate repository failures to verify error handling behavior.
/// Use these instead of defining failing repositories locally in each test file.

// MARK: - Failing Habit Repository

/// Test implementation that throws errors for HabitRepository operations
public actor FailingHabitRepository: HabitRepository {
    public var shouldFailFetchAll: Bool = false
    public var shouldFailFetchById: Bool = false
    public var shouldFailUpdate: Bool = false
    public var shouldFailDelete: Bool = false

    public init() {}

    public func fetchAllHabits() async throws -> [Habit] {
        if shouldFailFetchAll {
            throw NSError(domain: "FailingHabitRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
        }
        return []
    }

    public func fetchHabit(by id: UUID) async throws -> Habit? {
        if shouldFailFetchById {
            throw NSError(domain: "FailingHabitRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fetch by ID failed"])
        }
        return nil
    }

    public func update(_ habit: Habit) async throws {
        if shouldFailUpdate {
            throw NSError(domain: "FailingHabitRepository", code: 3, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
        }
    }

    public func delete(id: UUID) async throws {
        if shouldFailDelete {
            throw NSError(domain: "FailingHabitRepository", code: 4, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        }
    }

    public func cleanupOrphanedHabits() async throws -> Int { return 0 }

    // MARK: - Configuration Methods

    public func setShouldFailFetchAll(_ value: Bool) {
        self.shouldFailFetchAll = value
    }

    public func setShouldFailFetchById(_ value: Bool) {
        self.shouldFailFetchById = value
    }

    public func setShouldFailUpdate(_ value: Bool) {
        self.shouldFailUpdate = value
    }

    public func setShouldFailDelete(_ value: Bool) {
        self.shouldFailDelete = value
    }
}

// MARK: - Failing Profile Repository

/// Test implementation that throws errors for ProfileRepository operations
public actor FailingProfileRepository: ProfileRepository {
    public var shouldFailLoad: Bool = false
    public var shouldFailSave: Bool = false
    public var profileToReturn: UserProfile?

    public init() {}

    public func loadProfile() async throws -> UserProfile? {
        if shouldFailLoad {
            throw NSError(domain: "FailingProfileRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Load failed"])
        }
        return profileToReturn
    }

    public func saveProfile(_ profile: UserProfile) async throws {
        if shouldFailSave {
            throw NSError(domain: "FailingProfileRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        }
        profileToReturn = profile
    }

    // MARK: - Configuration Methods

    public func setShouldFailLoad(_ value: Bool) {
        self.shouldFailLoad = value
    }

    public func setShouldFailSave(_ value: Bool) {
        self.shouldFailSave = value
    }

    public func setProfileToReturn(_ profile: UserProfile?) {
        self.profileToReturn = profile
    }
}
