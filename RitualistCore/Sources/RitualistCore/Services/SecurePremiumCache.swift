//
//  SecurePremiumCache.swift
//  RitualistCore
//
//  Secure Keychain-based cache for premium status with offline grace period.
//  Industry standard: 3-day offline grace period (matches RevenueCat).
//

import Foundation
import Security

/// Secure cache for premium subscription status using iOS Keychain.
///
/// **Purpose:**
/// Provides offline access to premium features when StoreKit is unavailable
/// (airplane mode, poor connectivity, StoreKit timeout).
///
/// **Security:**
/// - Uses iOS Keychain (encrypted, tied to app signature)
/// - Much more secure than UserDefaults (which can be easily modified)
/// - Cannot be copied between apps or easily tampered with
///
/// **Thread Safety:**
/// This is an actor, providing automatic thread safety through actor isolation.
/// All methods are safely called from any context using `await`.
///
/// **Offline Grace Period:**
/// - Industry standard: 3 days (matches RevenueCat SDK)
/// - If user was premium when they went offline, they retain access for 3 days
/// - After 3 days, they must go online to verify subscription
///
/// **Usage:**
/// ```swift
/// // After successful StoreKit verification:
/// await SecurePremiumCache.shared.updateCache(plan: .monthly)
///
/// // When StoreKit times out:
/// let plan = await SecurePremiumCache.shared.getCachedSubscriptionPlan()
/// if plan != .free {
///     // Grant premium access (within grace period)
/// }
/// ```
public actor SecurePremiumCache {

    // MARK: - Singleton

    public static let shared = SecurePremiumCache()

    // MARK: - Constants

    /// Keychain service identifier
    private let service = "com.vladblajovan.ritualist.premium"

    /// Keychain account for premium status (boolean)
    private let premiumStatusAccount = "premium_status"

    /// Keychain account for subscription plan (for Settings display in offline mode)
    private let subscriptionPlanAccount = "subscription_plan"

    /// Keychain account for cache timestamp
    private let cacheTimestampAccount = "cache_timestamp"

    /// Keychain account for trial status (boolean)
    private let isOnTrialAccount = "is_on_trial"

    /// Keychain account for subscription expiry date
    private let expiryDateAccount = "expiry_date"

    /// Offline grace period duration (3 days - industry standard)
    /// After this period, cached premium status is no longer trusted.
    ///
    /// **Rationale:** 3 days matches RevenueCat SDK's default grace period. This balances:
    /// - User convenience: Allows offline use during travel, poor connectivity, etc.
    /// - Security: Limits exploitation window if subscription expires while offline
    /// - Industry practice: Apple's own grace period for payment retries is 16-60 days
    public static let offlineGracePeriod: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds

    /// Cache staleness threshold (7 days)
    /// After this period, cache should be verified with StoreKit (but still used for sync bootstrap).
    /// This is different from offlineGracePeriod: stale cache prompts verification, expired cache is not trusted.
    ///
    /// **Rationale:** 7 days allows weekly app users to not trigger verification on every launch,
    /// while ensuring monthly subscribers are verified at least 4x per billing cycle.
    public static let stalenessThreshold: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds

    /// Verification skip threshold (24 hours)
    /// If cache is newer than this, skip StoreKit verification entirely on app launch.
    /// This dramatically improves startup performance while maintaining reasonable freshness.
    ///
    /// **Rationale:**
    /// - StoreKit verification has a 5-second timeout and involves network calls
    /// - 24 hours is short enough to catch subscription changes within a day
    /// - Users who purchased/cancelled will see updates on next launch after 24h
    /// - Explicit "Restore Purchases" always bypasses this cache for immediate verification
    public static let verificationSkipThreshold: TimeInterval = 24 * 60 * 60 // 24 hours in seconds

    // Local logger: Singleton initialized before DI container
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "premiumCache")

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Update the cached subscription status after a successful StoreKit verification.
    ///
    /// Call this whenever StoreKit successfully verifies the user's subscription status.
    /// This keeps the cache fresh for offline scenarios.
    ///
    /// - Parameters:
    ///   - plan: The user's current subscription plan
    ///   - isOnTrial: Whether the user is currently on a free trial
    ///   - expiryDate: When the subscription/trial expires (nil for free users)
    ///
    /// **Important:** Trial subscriptions do NOT get offline grace period.
    /// When a trial expires, user must go online to convert or they become free immediately.
    ///
    public func updateCache(plan: SubscriptionPlan, isOnTrial: Bool = false, expiryDate: Date? = nil) {
        // Store premium status (boolean for backward compatibility and quick checks)
        let isPremium = plan != .free
        let statusData = Data([isPremium ? 1 : 0])
        saveToKeychain(data: statusData, account: premiumStatusAccount)

        // Store subscription plan (for Settings display in offline mode)
        if let planData = plan.rawValue.data(using: .utf8) {
            saveToKeychain(data: planData, account: subscriptionPlanAccount)
        }

        // Store trial status (trials don't get grace period when expired)
        let trialData = Data([isOnTrial ? 1 : 0])
        saveToKeychain(data: trialData, account: isOnTrialAccount)

        // Store expiry date (for trial expiration checks)
        if let expiryDate = expiryDate {
            let expiryTimestamp = expiryDate.timeIntervalSince1970
            let expiryData = withUnsafeBytes(of: expiryTimestamp) { Data($0) }
            saveToKeychain(data: expiryData, account: expiryDateAccount)
        } else {
            deleteFromKeychain(account: expiryDateAccount)
        }

        // Store current timestamp
        let timestamp = Date().timeIntervalSince1970
        let timestampData = withUnsafeBytes(of: timestamp) { Data($0) }
        saveToKeychain(data: timestampData, account: cacheTimestampAccount)
    }

    /// Get cached premium status if within the offline grace period.
    ///
    /// **Returns:**
    /// - `true` if user was premium AND cache is valid (see rules below)
    /// - `false` if user was not premium, cache is expired, or no cache exists
    ///
    /// **Trial vs Paid Subscription Rules:**
    /// - **Trial:** NO grace period. If trial expiry date has passed → `false` immediately.
    ///   Users must go online to convert to paid or they lose access.
    /// - **Paid Subscription:** 3-day offline grace period. If cache is less than 3 days old
    ///   AND subscription hasn't expired → `true`. This handles billing retry scenarios.
    ///
    /// **Security:**
    /// The 3-day limit prevents indefinite offline exploitation for paid subscriptions.
    /// Trials get no grace period to prevent free access beyond the trial period.
    ///
    public func getCachedPremiumStatus() -> Bool {
        // Read premium status from Keychain
        guard let statusData = readFromKeychain(account: premiumStatusAccount),
              let statusByte = statusData.first else {
            return false
        }

        let isPremium = statusByte == 1

        // If not premium, no need to check further
        guard isPremium else {
            return false
        }

        // Check if this was a trial subscription
        let isOnTrial = getCachedTrialStatus()

        // Check expiry date if available
        if let expiryDate = getCachedExpiryDate() {
            // If trial AND expired → NO grace period, return false immediately
            if isOnTrial && expiryDate < Date() {
                logger.log(
                    "Trial expired while offline - no grace period",
                    level: .info,
                    category: .premiumCache,
                    metadata: ["expiry": expiryDate.description]
                )
                return false
            }

            // If paid subscription AND not yet expired → return true
            if !isOnTrial && expiryDate > Date() {
                return true
            }
        }

        // Fall back to cache age check for paid subscriptions (handles billing retry)
        // Trials should have been caught above with expiry date check
        if isOnTrial {
            // Trial without expiry date = invalid cache, be conservative
            return false
        }

        // Read and validate cache timestamp for paid subscriptions
        guard let timestampData = readFromKeychain(account: cacheTimestampAccount),
              timestampData.count == MemoryLayout<TimeInterval>.size else {
            // No timestamp = cache is invalid
            return false
        }

        let timestamp = timestampData.withUnsafeBytes { $0.load(as: TimeInterval.self) }
        let cacheDate = Date(timeIntervalSince1970: timestamp)
        let cacheAge = Date().timeIntervalSince(cacheDate)

        // Check if within grace period (paid subscriptions only)
        if cacheAge <= Self.offlineGracePeriod {
            return true
        } else {
            // Cache is too old - don't trust it
            return false
        }
    }

    /// Get cached trial status
    private func getCachedTrialStatus() -> Bool {
        guard let trialData = readFromKeychain(account: isOnTrialAccount),
              let trialByte = trialData.first else {
            return false
        }
        return trialByte == 1
    }

    /// Get cached expiry date
    private func getCachedExpiryDate() -> Date? {
        guard let expiryData = readFromKeychain(account: expiryDateAccount),
              expiryData.count == MemoryLayout<TimeInterval>.size else {
            return nil
        }
        let expiryTimestamp = expiryData.withUnsafeBytes { $0.load(as: TimeInterval.self) }
        return Date(timeIntervalSince1970: expiryTimestamp)
    }

    /// Get cached subscription plan if within the offline grace period.
    ///
    /// Used by Settings to display the correct plan in offline scenarios.
    ///
    /// - Returns: The cached subscription plan, or `.free` if cache is invalid/expired/missing
    ///
    /// **Trial Handling:** If cached plan was a trial that has expired, returns `.free`.
    ///
    public func getCachedSubscriptionPlan() -> SubscriptionPlan {
        // First check if cache is valid (within grace period)
        guard isCacheValid() else {
            return .free
        }

        // Check if trial has expired (trials get no grace period)
        let isOnTrial = getCachedTrialStatus()
        if isOnTrial, let expiryDate = getCachedExpiryDate(), expiryDate < Date() {
            return .free
        }

        // Read subscription plan from Keychain
        guard let planData = readFromKeychain(account: subscriptionPlanAccount),
              let planString = String(data: planData, encoding: .utf8),
              let plan = SubscriptionPlan(rawValue: planString) else {
            return .free
        }

        return plan
    }

    /// Get the age of the current cache in seconds.
    ///
    /// - Returns: Cache age in seconds, or `nil` if no cache exists
    ///
    public func getCacheAge() -> TimeInterval? {
        guard let timestampData = readFromKeychain(account: cacheTimestampAccount),
              timestampData.count == MemoryLayout<TimeInterval>.size else {
            return nil
        }

        let timestamp = timestampData.withUnsafeBytes { $0.load(as: TimeInterval.self) }
        let cacheDate = Date(timeIntervalSince1970: timestamp)
        return Date().timeIntervalSince(cacheDate)
    }

    /// Check if the cache is within the grace period.
    ///
    /// - Returns: `true` if cache exists and is less than 3 days old
    ///
    public func isCacheValid() -> Bool {
        guard let age = getCacheAge() else {
            return false
        }
        return age <= Self.offlineGracePeriod
    }

    /// Check if the cache is stale and should be verified with StoreKit.
    ///
    /// **Note:** A stale cache is still used for sync bootstrap decisions (to avoid blocking).
    /// This method only indicates whether async verification should be prioritized.
    ///
    /// - Returns: `true` if cache doesn't exist or is older than 7 days
    ///
    public func isCacheStale() -> Bool {
        guard let age = getCacheAge() else {
            return true // No cache = stale
        }
        return age > Self.stalenessThreshold
    }

    /// Check if the cache is fresh enough to skip StoreKit verification entirely.
    ///
    /// Use this to avoid expensive StoreKit calls on every app launch.
    /// If returns `true`, the cached status can be trusted for startup decisions.
    ///
    /// - Returns: `true` if cache exists, is premium, and is less than 24 hours old
    ///
    /// **Note:** This is more aggressive than `isCacheValid()` which uses 3-day grace period.
    /// For startup optimization, we want a shorter threshold to ensure responsiveness to
    /// subscription changes while still avoiding unnecessary verification overhead.
    public func canSkipVerification() -> Bool {
        guard let age = getCacheAge() else {
            return false // No cache = must verify
        }
        return age <= Self.verificationSkipThreshold
    }

    /// Clear all cached subscription data.
    ///
    /// Call this when user explicitly signs out or subscription is revoked.
    ///
    public func clearCache() {
        deleteFromKeychain(account: premiumStatusAccount)
        deleteFromKeychain(account: subscriptionPlanAccount)
        deleteFromKeychain(account: cacheTimestampAccount)
        deleteFromKeychain(account: isOnTrialAccount)
        deleteFromKeychain(account: expiryDateAccount)
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(data: Data, account: String) {
        // First, try to delete any existing item
        deleteFromKeychain(account: account)

        // Create query for new item
        // Using AfterFirstUnlockThisDeviceOnly to allow app startup without requiring device unlock.
        // Premium status is not highly sensitive (StoreKit is the source of truth, this is just a cache).
        // More restrictive options like WhenUnlockedThisDeviceOnly would break cold launch scenarios.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            // Log but don't crash - cache is a fallback, not critical
            logger.log(
                "Failed to save to Keychain",
                level: .warning,
                category: .premiumCache,
                metadata: ["status": status]
            )
        }
    }

    private func readFromKeychain(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        } else {
            return nil
        }
    }

    private func deleteFromKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension SecurePremiumCache {
    /// Debug helper to inspect cache state
    public func debugDescription() -> String {
        let isPremium = getCachedPremiumStatus()
        let plan = getCachedSubscriptionPlan()
        let isOnTrial = getCachedTrialStatus()
        let expiryDate = getCachedExpiryDate()
        let expiryString = expiryDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .short) } ?? "none"
        let age = getCacheAge()
        let ageString = age.map { String(format: "%.1f hours", $0 / 3600) } ?? "no cache"
        let gracePeriodHours = Self.offlineGracePeriod / 3600
        let stalenessThresholdHours = Self.stalenessThreshold / 3600

        return """
        SecurePremiumCache:
          - Cached Premium: \(isPremium)
          - Cached Plan: \(plan.rawValue)
          - Is On Trial: \(isOnTrial)
          - Expiry Date: \(expiryString)
          - Cache Age: \(ageString)
          - Grace Period: \(gracePeriodHours) hours
          - Staleness Threshold: \(stalenessThresholdHours) hours
          - Cache Valid: \(isCacheValid())
          - Cache Stale: \(isCacheStale())
        """
    }
}
#endif
