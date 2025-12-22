//
//  CachedProfileUseCases.swift
//  RitualistCore
//
//  Created by Claude on 22.12.2025.
//
//  Provides cached versions of profile use cases to reduce disk I/O.
//  Uses a shared actor-based cache with configurable TTL.
//

import Foundation

// MARK: - Profile Cache

/// Thread-safe cache for UserProfile with TTL support
///
/// This actor provides a shared cache that can be used by both LoadProfile
/// and SaveProfile to reduce redundant database reads while maintaining
/// data consistency.
///
/// ## Usage:
/// ```swift
/// let cache = ProfileCache()
///
/// // Get cached profile (or nil if expired/empty)
/// if let profile = await cache.get() {
///     return profile
/// }
///
/// // Store profile in cache
/// await cache.set(profile)
///
/// // Invalidate on save
/// await cache.invalidate()
/// ```
public actor ProfileCache {

    // MARK: - Cache Entry

    private struct CacheEntry {
        let profile: UserProfile
        let timestamp: Date
    }

    // MARK: - Properties

    private var entry: CacheEntry?
    private let ttl: TimeInterval
    private let logger: DebugLogger

    // MARK: - Initialization

    /// Initialize cache with configurable TTL
    /// - Parameter ttl: Time-to-live in seconds (default: 5 minutes)
    public init(
        ttl: TimeInterval = 300, // 5 minutes
        logger: DebugLogger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "profile-cache")
    ) {
        self.ttl = ttl
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Get cached profile if valid (not expired)
    /// - Returns: Cached profile or nil if cache is empty/expired
    public func get() -> UserProfile? {
        guard let entry = entry else {
            logger.log("Cache miss - no entry", level: .debug, category: .performance)
            return nil
        }

        let age = Date().timeIntervalSince(entry.timestamp)
        guard age < ttl else {
            logger.log(
                "Cache miss - expired",
                level: .debug,
                category: .performance,
                metadata: ["age_seconds": String(format: "%.1f", age), "ttl": String(format: "%.0f", ttl)]
            )
            self.entry = nil
            return nil
        }

        logger.log(
            "Cache hit",
            level: .debug,
            category: .performance,
            metadata: ["age_seconds": String(format: "%.1f", age)]
        )
        return entry.profile
    }

    /// Store profile in cache
    /// - Parameter profile: Profile to cache
    public func set(_ profile: UserProfile) {
        entry = CacheEntry(profile: profile, timestamp: Date())
        logger.log("Cache updated", level: .debug, category: .performance)
    }

    /// Invalidate cache (call on save/update)
    public func invalidate() {
        if entry != nil {
            entry = nil
            logger.log("Cache invalidated", level: .debug, category: .performance)
        }
    }

    /// Check if cache has a valid (non-expired) entry
    public var isValid: Bool {
        guard let entry = entry else { return false }
        return Date().timeIntervalSince(entry.timestamp) < ttl
    }
}

// MARK: - Cached Load Profile

/// Cached wrapper for LoadProfile that reduces database reads
///
/// Uses a shared ProfileCache with 5-minute TTL. Cache is automatically
/// invalidated when SaveProfile is called (via shared cache reference).
///
/// ## Performance Impact:
/// - First call: Database read + cache store
/// - Subsequent calls within TTL: Cache hit (no database read)
/// - After TTL expires: Database read + cache refresh
public final class CachedLoadProfile: LoadProfileUseCase {

    private let innerLoadProfile: LoadProfileUseCase
    private let cache: ProfileCache

    /// Initialize with inner use case and shared cache
    /// - Parameters:
    ///   - innerLoadProfile: The underlying LoadProfile use case
    ///   - cache: Shared ProfileCache instance
    public init(
        innerLoadProfile: LoadProfileUseCase,
        cache: ProfileCache
    ) {
        self.innerLoadProfile = innerLoadProfile
        self.cache = cache
    }

    public func execute() async throws -> UserProfile {
        // Check cache first
        if let cached = await cache.get() {
            return cached
        }

        // Cache miss - load from database
        let profile = try await innerLoadProfile.execute()

        // Store in cache
        await cache.set(profile)

        return profile
    }
}

// MARK: - Cache-Aware Save Profile

/// SaveProfile wrapper that invalidates cache on save
///
/// Ensures cache consistency by invalidating the shared ProfileCache
/// whenever a profile is saved to the database.
public final class CacheAwareSaveProfile: SaveProfileUseCase {

    private let innerSaveProfile: SaveProfileUseCase
    private let cache: ProfileCache

    /// Initialize with inner use case and shared cache
    /// - Parameters:
    ///   - innerSaveProfile: The underlying SaveProfile use case
    ///   - cache: Shared ProfileCache instance (same instance as CachedLoadProfile)
    public init(
        innerSaveProfile: SaveProfileUseCase,
        cache: ProfileCache
    ) {
        self.innerSaveProfile = innerSaveProfile
        self.cache = cache
    }

    public func execute(_ profile: UserProfile) async throws {
        // Save to database
        try await innerSaveProfile.execute(profile)

        // Invalidate cache to ensure next read gets fresh data
        await cache.invalidate()
    }
}
