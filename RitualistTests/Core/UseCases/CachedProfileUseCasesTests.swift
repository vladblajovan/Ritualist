//
//  CachedProfileUseCasesTests.swift
//  RitualistTests
//
//  Tests for ProfileCache and cached profile use cases.
//
//  Test Coverage:
//  - ProfileCache TTL expiration
//  - Cache invalidation
//  - Cache hit returns stored profile
//  - Concurrent access thread safety
//  - CachedLoadProfile wrapper behavior
//  - CacheAwareSaveProfile invalidation
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - ProfileCache Tests

@Suite(
    "ProfileCache Tests",
    .tags(.cache, .performance, .businessLogic)
)
@MainActor
struct ProfileCacheTests {

    // MARK: - Cache Hit Tests

    @Test("Cache hit returns stored profile")
    func cacheHitReturnsStoredProfile() async throws {
        let cache = ProfileCache(ttl: 300) // 5 minutes
        let profile = UserProfileBuilder.standard(name: "Cached User")

        // Store profile
        await cache.set(profile)

        // Retrieve from cache
        let cachedProfile = await cache.get()

        #expect(cachedProfile != nil)
        #expect(cachedProfile?.name == "Cached User")
        #expect(cachedProfile?.id == profile.id)
    }

    @Test("Cache returns nil when empty")
    func cacheReturnsNilWhenEmpty() async throws {
        let cache = ProfileCache(ttl: 300)

        // Cache should be empty initially
        let cachedProfile = await cache.get()

        #expect(cachedProfile == nil)
    }

    @Test("isValid returns true for valid cache entry")
    func isValidReturnsTrueForValidCacheEntry() async throws {
        let cache = ProfileCache(ttl: 300)
        let profile = UserProfileBuilder.standard()

        await cache.set(profile)

        let isValid = await cache.isValid

        #expect(isValid == true)
    }

    @Test("isValid returns false for empty cache")
    func isValidReturnsFalseForEmptyCache() async throws {
        let cache = ProfileCache(ttl: 300)

        let isValid = await cache.isValid

        #expect(isValid == false)
    }

    // MARK: - TTL Expiration Tests

    @Test("Cache returns nil after TTL expires")
    func cacheReturnsNilAfterTTLExpires() async throws {
        // Use short TTL for testing (1 second) - enough margin for async scheduling
        let cache = ProfileCache(ttl: 1.0)
        let profile = UserProfileBuilder.standard(name: "Expiring User")

        // Store profile
        await cache.set(profile)

        // Verify it's cached (should be immediate, well within 1s TTL)
        let cachedImmediately = await cache.get()
        #expect(cachedImmediately != nil)

        // Wait for TTL to expire
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        // Cache should now return nil
        let cachedAfterExpiry = await cache.get()
        #expect(cachedAfterExpiry == nil)
    }

    @Test("isValid returns false after TTL expires")
    func isValidReturnsFalseAfterTTLExpires() async throws {
        let cache = ProfileCache(ttl: 1.0) // 1 second - enough margin for async scheduling
        let profile = UserProfileBuilder.standard()

        await cache.set(profile)

        // Initially valid (should be immediate, well within 1s TTL)
        let validBefore = await cache.isValid
        #expect(validBefore == true)

        // Wait for expiry
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        // Should be invalid now
        let validAfter = await cache.isValid
        #expect(validAfter == false)
    }

    // MARK: - Cache Invalidation Tests

    @Test("Cache invalidation clears cached entry")
    func cacheInvalidationClearsCachedEntry() async throws {
        let cache = ProfileCache(ttl: 300)
        let profile = UserProfileBuilder.standard(name: "To Be Invalidated")

        // Store profile
        await cache.set(profile)

        // Verify it's cached
        let cachedBefore = await cache.get()
        #expect(cachedBefore != nil)

        // Invalidate
        await cache.invalidate()

        // Cache should now be empty
        let cachedAfter = await cache.get()
        #expect(cachedAfter == nil)
    }

    @Test("isValid returns false after invalidation")
    func isValidReturnsFalseAfterInvalidation() async throws {
        let cache = ProfileCache(ttl: 300)
        let profile = UserProfileBuilder.standard()

        await cache.set(profile)
        #expect(await cache.isValid == true)

        await cache.invalidate()
        #expect(await cache.isValid == false)
    }

    @Test("Invalidation on empty cache is safe")
    func invalidationOnEmptyCacheIsSafe() async throws {
        let cache = ProfileCache(ttl: 300)

        // Should not throw or crash
        await cache.invalidate()

        let cachedProfile = await cache.get()
        #expect(cachedProfile == nil)
    }

    // MARK: - Cache Update Tests

    @Test("Setting new profile replaces old one")
    func settingNewProfileReplacesOldOne() async throws {
        let cache = ProfileCache(ttl: 300)
        let profile1 = UserProfileBuilder.standard(name: "First User")
        let profile2 = UserProfileBuilder.standard(name: "Second User")

        await cache.set(profile1)
        let first = await cache.get()
        #expect(first?.name == "First User")

        await cache.set(profile2)
        let second = await cache.get()
        #expect(second?.name == "Second User")
    }

    // MARK: - Concurrent Access Tests

    @Test("Concurrent access is thread-safe")
    func concurrentAccessIsThreadSafe() async throws {
        let cache = ProfileCache(ttl: 300)
        let profile = UserProfileBuilder.standard(name: "Concurrent User")

        // Pre-populate cache
        await cache.set(profile)

        // Run many concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // 50 concurrent reads
            for _ in 0..<50 {
                group.addTask {
                    _ = await cache.get()
                }
            }

            // 10 concurrent writes
            for i in 0..<10 {
                group.addTask {
                    let newProfile = UserProfileBuilder.standard(name: "User \(i)")
                    await cache.set(newProfile)
                }
            }

            // 5 concurrent invalidations
            for _ in 0..<5 {
                group.addTask {
                    await cache.invalidate()
                }
            }

            // 10 concurrent isValid checks
            for _ in 0..<10 {
                group.addTask {
                    _ = await cache.isValid
                }
            }
        }

        // Test passes if no crashes or data races occurred
        // The actor isolation guarantees thread safety
    }

    @Test("Concurrent reads return consistent data")
    func concurrentReadsReturnConsistentData() async throws {
        let cache = ProfileCache(ttl: 300)
        let profile = UserProfileBuilder.standard(name: "Consistent User")

        await cache.set(profile)

        // Run 100 concurrent reads
        let results = await withTaskGroup(of: String?.self, returning: [String?].self) { group in
            for _ in 0..<100 {
                group.addTask {
                    let cached = await cache.get()
                    return cached?.name
                }
            }

            var names: [String?] = []
            for await name in group {
                names.append(name)
            }
            return names
        }

        // All reads should return the same value
        let nonNilResults = results.compactMap { $0 }
        for name in nonNilResults {
            #expect(name == "Consistent User")
        }
    }
}

// MARK: - CachedLoadProfile Tests

@Suite(
    "CachedLoadProfile Tests",
    .tags(.cache, .useCase, .businessLogic)
)
@MainActor
struct CachedLoadProfileTests {

    @Test("Returns cached profile on cache hit")
    func returnsCachedProfileOnCacheHit() async throws {
        let cache = ProfileCache(ttl: 300)
        let mockInner = MockLoadProfileUseCase()
        let cachedProfile = UserProfileBuilder.standard(name: "Cached")

        // Pre-populate cache
        await cache.set(cachedProfile)

        let cachedLoadProfile = CachedLoadProfile(
            innerLoadProfile: mockInner,
            cache: cache
        )

        let result = try await cachedLoadProfile.execute()

        // Should return cached profile without calling inner
        #expect(result.name == "Cached")
        #expect(await mockInner.executeCallCount == 0)
    }

    @Test("Fetches from inner on cache miss")
    func fetchesFromInnerOnCacheMiss() async throws {
        let cache = ProfileCache(ttl: 300)
        let mockInner = MockLoadProfileUseCase()
        let freshProfile = UserProfileBuilder.standard(name: "Fresh From Database")
        await mockInner.setProfileToReturn(freshProfile)

        let cachedLoadProfile = CachedLoadProfile(
            innerLoadProfile: mockInner,
            cache: cache
        )

        let result = try await cachedLoadProfile.execute()

        // Should call inner use case
        #expect(result.name == "Fresh From Database")
        #expect(await mockInner.executeCallCount == 1)

        // Should now be cached
        let cachedResult = await cache.get()
        #expect(cachedResult?.name == "Fresh From Database")
    }
}

// MARK: - CacheAwareSaveProfile Tests

@Suite(
    "CacheAwareSaveProfile Tests",
    .tags(.cache, .useCase, .businessLogic)
)
@MainActor
struct CacheAwareSaveProfileTests {

    @Test("Save updates cache with new profile")
    func saveUpdatesCache() async throws {
        let cache = ProfileCache(ttl: 300)
        let mockInner = MockSaveProfileUseCase()
        let profile = UserProfileBuilder.standard(name: "To Save")

        // Pre-populate cache with different profile
        let oldProfile = UserProfileBuilder.standard(name: "Old Profile")
        await cache.set(oldProfile)
        #expect(await cache.isValid == true)

        let cacheAwareSave = CacheAwareSaveProfile(
            innerSaveProfile: mockInner,
            cache: cache
        )

        try await cacheAwareSave.execute(profile)

        // Cache should be updated with the saved profile (not invalidated)
        #expect(await cache.isValid == true)
        #expect(await cache.get()?.name == "To Save")
    }

    @Test("Save calls inner use case")
    func saveCallsInnerUseCase() async throws {
        let cache = ProfileCache(ttl: 300)
        let mockInner = MockSaveProfileUseCase()
        let profile = UserProfileBuilder.standard(name: "Saved User")

        let cacheAwareSave = CacheAwareSaveProfile(
            innerSaveProfile: mockInner,
            cache: cache
        )

        try await cacheAwareSave.execute(profile)

        // Inner should be called
        #expect(await mockInner.executeCallCount == 1)
        let savedProfile = await mockInner.lastSavedProfile
        #expect(savedProfile?.name == "Saved User")
    }

    @Test("Save propagates errors from inner")
    func savePropagatesErrorsFromInner() async throws {
        let cache = ProfileCache(ttl: 300)
        let mockInner = MockSaveProfileUseCase()
        await mockInner.setShouldFail(true)
        let profile = UserProfileBuilder.standard()

        // Pre-populate cache
        await cache.set(profile)

        let cacheAwareSave = CacheAwareSaveProfile(
            innerSaveProfile: mockInner,
            cache: cache
        )

        do {
            try await cacheAwareSave.execute(profile)
            Issue.record("Expected error to be thrown")
        } catch {
            // Error should be propagated
            #expect(error.localizedDescription.contains("Save failed"))
        }

        // Cache should NOT be invalidated on error (save failed)
        // Note: Current implementation invalidates after save, so if save throws,
        // invalidation is not reached. This test verifies error propagation.
    }
}

// MARK: - Mock Use Cases

/// Mock LoadProfileUseCase for testing
private actor MockLoadProfileUseCase: LoadProfileUseCase {
    private var profileToReturn: UserProfile = UserProfileBuilder.standard()
    private var _executeCallCount = 0

    var executeCallCount: Int {
        _executeCallCount
    }

    func setProfileToReturn(_ profile: UserProfile) {
        profileToReturn = profile
    }

    func execute() async throws -> UserProfile {
        _executeCallCount += 1
        return profileToReturn
    }
}

/// Mock SaveProfileUseCase for testing
private actor MockSaveProfileUseCase: SaveProfileUseCase {
    private var _executeCallCount = 0
    private var _lastSavedProfile: UserProfile?
    private var shouldFail = false

    var executeCallCount: Int {
        _executeCallCount
    }

    var lastSavedProfile: UserProfile? {
        _lastSavedProfile
    }

    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }

    func execute(_ profile: UserProfile) async throws {
        if shouldFail {
            throw MockSaveError.saveFailed
        }
        _executeCallCount += 1
        _lastSavedProfile = profile
    }
}

private enum MockSaveError: Error, LocalizedError {
    case saveFailed

    var errorDescription: String? {
        "Save failed"
    }
}
