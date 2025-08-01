import Foundation

// MARK: - Secure UserDefaults Protocol

public protocol SecureUserDefaultsProtocol {
    func setSecurely<T: Codable>(_ value: T, forKey key: String) async throws
    func getSecurely<T: Codable>(_ type: T.Type, forKey key: String) async -> T?
    func removeSecurely(forKey key: String) async
    func synchronize() async -> Bool
}

// MARK: - Secure UserDefaults Implementation

public final class SecureUserDefaults: SecureUserDefaultsProtocol, @unchecked Sendable {
    
    private let queue = DispatchQueue(label: "SecureUserDefaults", qos: .userInitiated)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let accessLock = NSLock()
    
    public init() {
        // Configure encoder/decoder for consistent date handling
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Secure Operations
    
    public func setSecurely<T: Codable>(_ value: T, forKey key: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SecureUserDefaultsError.instanceDeallocated)
                    return
                }
                
                self.accessLock.lock()
                defer { self.accessLock.unlock() }
                
                do {
                    let data = try self.encoder.encode(value)
                    UserDefaults.standard.set(data, forKey: key)
                    
                    // Force synchronization to ensure data is written
                    let success = UserDefaults.standard.synchronize()
                    if !success {
                        continuation.resume(throwing: SecureUserDefaultsError.synchronizationFailed)
                        return
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: SecureUserDefaultsError.encodingFailed(error))
                }
            }
        }
    }
    
    public func getSecurely<T: Codable>(_ type: T.Type, forKey key: String) async -> T? {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                self.accessLock.lock()
                defer { self.accessLock.unlock() }
                
                guard let data = UserDefaults.standard.data(forKey: key) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let value = try self.decoder.decode(type, from: data)
                    continuation.resume(returning: value)
                } catch {
                    // If decoding fails, remove the corrupted data
                    UserDefaults.standard.removeObject(forKey: key)
                    _ = UserDefaults.standard.synchronize()
                    print("SecureUserDefaults: Removed corrupted data for key '\(key)': \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    public func removeSecurely(forKey key: String) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                self.accessLock.lock()
                defer { self.accessLock.unlock() }
                
                UserDefaults.standard.removeObject(forKey: key)
                _ = UserDefaults.standard.synchronize()
                continuation.resume()
            }
        }
    }
    
    public func synchronize() async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                self.accessLock.lock()
                defer { self.accessLock.unlock() }
                
                let success = UserDefaults.standard.synchronize()
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Batch Operations
    
    public func setBatch(_ operations: [(key: String, value: Any?)]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SecureUserDefaultsError.instanceDeallocated)
                    return
                }
                
                self.accessLock.lock()
                defer { self.accessLock.unlock() }
                
                // Perform all operations atomically
                for operation in operations {
                    if let value = operation.value {
                        UserDefaults.standard.set(value, forKey: operation.key)
                    } else {
                        UserDefaults.standard.removeObject(forKey: operation.key)
                    }
                }
                
                // Synchronize once for all operations
                let success = UserDefaults.standard.synchronize()
                if !success {
                    continuation.resume(throwing: SecureUserDefaultsError.synchronizationFailed)
                    return
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Validation
    
    public func validateIntegrity(for keys: [String]) async -> [String: Bool] {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [:])
                    return
                }
                
                self.accessLock.lock()
                defer { self.accessLock.unlock() }
                
                var results: [String: Bool] = [:]
                
                for key in keys {
                    guard let data = UserDefaults.standard.data(forKey: key) else {
                        results[key] = true // Missing data is considered valid (no corruption)
                        continue
                    }
                    
                    // Try to decode as JSON to check for corruption
                    do {
                        _ = try JSONSerialization.jsonObject(with: data, options: [])
                        results[key] = true
                    } catch {
                        results[key] = false
                        print("SecureUserDefaults: Corrupted data detected for key '\(key)'")
                    }
                }
                
                continuation.resume(returning: results)
            }
        }
    }
    
    // MARK: - Migration Support
    
    public func migrateFromLegacyKeys(_ migrations: [(old: String, new: String)]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SecureUserDefaultsError.instanceDeallocated)
                    return
                }
                
                self.accessLock.lock()
                defer { self.accessLock.unlock() }
                
                for migration in migrations {
                    if let value = UserDefaults.standard.object(forKey: migration.old) {
                        UserDefaults.standard.set(value, forKey: migration.new)
                        UserDefaults.standard.removeObject(forKey: migration.old)
                    }
                }
                
                let success = UserDefaults.standard.synchronize()
                if !success {
                    continuation.resume(throwing: SecureUserDefaultsError.synchronizationFailed)
                    return
                }
                
                continuation.resume()
            }
        }
    }
}

// MARK: - Error Types

public enum SecureUserDefaultsError: Error, LocalizedError {
    case encodingFailed(Error)
    case synchronizationFailed
    case instanceDeallocated
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .synchronizationFailed:
            return "Failed to synchronize UserDefaults"
        case .instanceDeallocated:
            return "SecureUserDefaults instance was deallocated"
        }
    }
}

// MARK: - Convenience Extensions

extension SecureUserDefaults {
    
    // String convenience methods
    public func setString(_ value: String, forKey key: String) async throws {
        try await setSecurely(value, forKey: key)
    }
    
    public func getString(forKey key: String) async -> String? {
        await getSecurely(String.self, forKey: key)
    }
    
    // Array convenience methods
    public func setStringArray(_ value: [String], forKey key: String) async throws {
        try await setSecurely(value, forKey: key)
    }
    
    public func getStringArray(forKey key: String) async -> [String]? {
        await getSecurely([String].self, forKey: key)
    }
    
    // Bool convenience methods
    public func setBool(_ value: Bool, forKey key: String) async throws {
        try await setSecurely(value, forKey: key)
    }
    
    public func getBool(forKey key: String) async -> Bool? {
        await getSecurely(Bool.self, forKey: key)
    }
}

// MARK: - NoOp Implementation for Testing

public final class NoOpSecureUserDefaults: SecureUserDefaultsProtocol, @unchecked Sendable {
    
    private var storage: [String: Any] = [:]
    private let queue = DispatchQueue(label: "NoOpSecureUserDefaults", qos: .userInitiated)
    
    public init() {}
    
    public func setSecurely<T: Codable>(_ value: T, forKey key: String) async throws {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                self?.storage[key] = value
                continuation.resume()
            }
        }
    }
    
    public func getSecurely<T: Codable>(_ type: T.Type, forKey key: String) async -> T? {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                let value = self?.storage[key] as? T
                continuation.resume(returning: value)
            }
        }
    }
    
    public func removeSecurely(forKey key: String) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                self?.storage.removeValue(forKey: key)
                continuation.resume()
            }
        }
    }
    
    public func synchronize() async -> Bool {
        true
    }
}
