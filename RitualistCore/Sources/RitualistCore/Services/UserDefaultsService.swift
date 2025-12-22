//
//  UserDefaultsService.swift
//  RitualistCore
//
//  Created by Claude on 22.12.2025.
//
//  Provides an injectable abstraction over UserDefaults for better testability.
//  All UserDefaults access should go through this service to enable mocking in tests.
//

import Foundation

// MARK: - Protocol

/// Protocol for UserDefaults operations, enabling dependency injection and testability
public protocol UserDefaultsService: Sendable {

    // MARK: - Generic Accessors

    func bool(forKey key: String) -> Bool
    func string(forKey key: String) -> String?
    func data(forKey key: String) -> Data?
    func object(forKey key: String) -> Any?
    func date(forKey key: String) -> Date?
    func stringArray(forKey key: String) -> [String]?

    // MARK: - Generic Setters

    func set(_ value: Bool, forKey key: String)
    func set(_ value: String?, forKey key: String)
    func set(_ value: Data?, forKey key: String)
    func set(_ value: Any?, forKey key: String)
    func set(_ value: Date?, forKey key: String)

    // MARK: - Removal

    func removeObject(forKey key: String)

    // MARK: - Sync

    func synchronize()
}

// MARK: - Default Implementation

/// Production implementation wrapping UserDefaults.standard
///
/// Marked as `@unchecked Sendable` because `UserDefaults.standard` is internally thread-safe.
/// Apple's documentation confirms UserDefaults is safe for concurrent access from multiple threads.
public final class DefaultUserDefaultsService: UserDefaultsService, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Generic Accessors

    public func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    public func object(forKey key: String) -> Any? {
        defaults.object(forKey: key)
    }

    public func date(forKey key: String) -> Date? {
        defaults.object(forKey: key) as? Date
    }

    public func stringArray(forKey key: String) -> [String]? {
        defaults.stringArray(forKey: key)
    }

    // MARK: - Generic Setters

    public func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: Data?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: Date?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    // MARK: - Removal

    public func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Sync

    public func synchronize() {
        defaults.synchronize()
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
/// Mock implementation for testing that stores values in memory
///
/// Marked as `@unchecked Sendable` because thread safety is ensured via NSLock.
/// All mutable state access is protected by the lock.
public final class MockUserDefaultsService: UserDefaultsService, @unchecked Sendable {
    private var storage: [String: Any] = [:]
    private let lock = NSLock()

    public init() {}

    public func bool(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] as? Bool ?? false
    }

    public func string(forKey key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] as? String
    }

    public func data(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] as? Data
    }

    public func object(forKey key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    public func date(forKey key: String) -> Date? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] as? Date
    }

    public func stringArray(forKey key: String) -> [String]? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] as? [String]
    }

    public func set(_ value: Bool, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }

    public func set(_ value: String?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        if let value = value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }

    public func set(_ value: Data?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        if let value = value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }

    public func set(_ value: Any?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        if let value = value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }

    public func set(_ value: Date?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        if let value = value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }

    public func removeObject(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    public func synchronize() {
        // No-op for mock
    }

    /// Reset all stored values (for test cleanup)
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }

    /// Check if a key exists (for test assertions)
    public func hasKey(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] != nil
    }
}
#endif
