//
//  UserProfileBuilder.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// A fluent builder for creating UserProfile test instances with sensible defaults.
///
/// Usage:
/// ```swift
/// let profile = UserProfileBuilder()
///     .withName("John Doe")
///     .withSubscription(.monthly)
///     .withActiveSubscription()
///     .build()
/// ```
public class UserProfileBuilder {
    private var id = UUID()
    private var name = "Test User"
    private var avatarImageData: Data? = nil
    private var appearance = 0  // Follow system
    private var subscriptionPlan: SubscriptionPlan = .free
    private var subscriptionExpiryDate: Date? = nil
    private var createdAt = Date()
    private var updatedAt = Date()
    
    public init() {}
    
    // MARK: - Fluent API
    
    /// Sets a custom UUID for the profile. If not called, a random UUID is generated.
    @discardableResult
    public func withId(_ id: UUID) -> UserProfileBuilder {
        self.id = id
        return self
    }
    
    /// Sets the user's name.
    @discardableResult
    public func withName(_ name: String) -> UserProfileBuilder {
        self.name = name
        return self
    }
    
    /// Sets the user's avatar image data.
    @discardableResult
    public func withAvatarImageData(_ data: Data?) -> UserProfileBuilder {
        self.avatarImageData = data
        return self
    }
    
    /// Sets the user's appearance preference.
    /// - Parameter appearance: 0 = follow system, 1 = light, 2 = dark
    @discardableResult
    public func withAppearance(_ appearance: Int) -> UserProfileBuilder {
        self.appearance = appearance
        return self
    }
    
    /// Sets the user's subscription plan.
    @discardableResult
    public func withSubscriptionPlan(_ plan: SubscriptionPlan) -> UserProfileBuilder {
        self.subscriptionPlan = plan
        return self
    }
    
    /// Sets the subscription expiry date.
    @discardableResult
    public func withSubscriptionExpiryDate(_ date: Date?) -> UserProfileBuilder {
        self.subscriptionExpiryDate = date
        return self
    }
    
    /// Sets the profile creation date.
    @discardableResult
    public func withCreatedAt(_ date: Date) -> UserProfileBuilder {
        self.createdAt = date
        return self
    }
    
    /// Sets the profile last update date.
    @discardableResult
    public func withUpdatedAt(_ date: Date) -> UserProfileBuilder {
        self.updatedAt = date
        return self
    }
    
    // MARK: - Appearance Convenience Methods
    
    /// Sets appearance to follow system settings.
    @discardableResult
    public func followSystemAppearance() -> UserProfileBuilder {
        return self.withAppearance(0)
    }
    
    /// Sets appearance to light mode.
    @discardableResult
    public func withLightAppearance() -> UserProfileBuilder {
        return self.withAppearance(1)
    }
    
    /// Sets appearance to dark mode.
    @discardableResult
    public func withDarkAppearance() -> UserProfileBuilder {
        return self.withAppearance(2)
    }
    
    // MARK: - Subscription Convenience Methods
    
    /// Sets a free subscription (default).
    @discardableResult
    public func withFreeSubscription() -> UserProfileBuilder {
        return self
            .withSubscriptionPlan(.free)
            .withSubscriptionExpiryDate(nil)
    }
    
    /// Sets a monthly subscription.
    @discardableResult
    public func withMonthlySubscription() -> UserProfileBuilder {
        return self.withSubscriptionPlan(.monthly)
    }
    
    /// Sets an annual subscription.
    @discardableResult
    public func withAnnualSubscription() -> UserProfileBuilder {
        return self.withSubscriptionPlan(.annual)
    }
    
    /// Sets an active subscription (valid for next 30 days).
    @discardableResult
    public func withActiveSubscription() -> UserProfileBuilder {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return self.withSubscriptionExpiryDate(futureDate)
    }
    
    /// Sets an expired subscription.
    @discardableResult
    public func withExpiredSubscription() -> UserProfileBuilder {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return self.withSubscriptionExpiryDate(pastDate)
    }
    
    /// Sets an expiring subscription (expires within 7 days).
    @discardableResult
    public func withExpiringSubscription() -> UserProfileBuilder {
        let nearFutureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return self.withSubscriptionExpiryDate(nearFutureDate)
    }
    
    /// Sets a recently purchased subscription (purchased today).
    @discardableResult
    public func withRecentSubscription() -> UserProfileBuilder {
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        return self
            .withSubscriptionExpiryDate(oneYearFromNow)
            .withUpdatedAt(Date())  // Recent update
    }
    
    // MARK: - Avatar Convenience Methods
    
    /// Sets a mock avatar image data (1x1 pixel PNG).
    @discardableResult
    public func withMockAvatar() -> UserProfileBuilder {
        // Create a minimal 1x1 pixel PNG data for testing
        let mockPNGData = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  // PNG signature
            0x00, 0x00, 0x00, 0x0D,  // IHDR chunk length
            0x49, 0x48, 0x44, 0x52,  // IHDR
            0x00, 0x00, 0x00, 0x01,  // Width: 1
            0x00, 0x00, 0x00, 0x01,  // Height: 1
            0x08, 0x02, 0x00, 0x00, 0x00,  // Bit depth: 8, Color type: 2, Compression: 0, Filter: 0, Interlace: 0
            0x90, 0x77, 0x53, 0xDE,  // CRC
            0x00, 0x00, 0x00, 0x0C,  // IDAT chunk length
            0x49, 0x44, 0x41, 0x54,  // IDAT
            0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01,  // Compressed image data
            0x00, 0x00, 0x00, 0x00,  // IEND chunk length
            0x49, 0x45, 0x4E, 0x44,  // IEND
            0xAE, 0x42, 0x60, 0x82   // CRC
        ])
        return self.withAvatarImageData(mockPNGData)
    }
    
    /// Removes the avatar image.
    @discardableResult
    public func withoutAvatar() -> UserProfileBuilder {
        return self.withAvatarImageData(nil)
    }
    
    // MARK: - Date Convenience Methods
    
    /// Sets the creation date to a specific number of days ago.
    @discardableResult
    public func createdDaysAgo(_ days: Int) -> UserProfileBuilder {
        let pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self.withCreatedAt(pastDate)
    }
    
    /// Sets the update date to a specific number of days ago.
    @discardableResult
    public func updatedDaysAgo(_ days: Int) -> UserProfileBuilder {
        let pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self.withUpdatedAt(pastDate)
    }
    
    /// Sets both creation and update dates to the same time.
    @discardableResult
    public func withSameDates(_ date: Date) -> UserProfileBuilder {
        return self
            .withCreatedAt(date)
            .withUpdatedAt(date)
    }
    
    // MARK: - Build
    
    /// Creates the UserProfile instance with all configured properties.
    public func build() -> UserProfile {
        return UserProfile(
            id: id,
            name: name,
            avatarImageData: avatarImageData,
            appearance: appearance,
            subscriptionPlan: subscriptionPlan,
            subscriptionExpiryDate: subscriptionExpiryDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Predefined User Profiles

public extension UserProfileBuilder {
    /// Creates a new free user profile.
    static func newFreeUser() -> UserProfileBuilder {
        return UserProfileBuilder()
            .withName("New User")
            .withFreeSubscription()
            .withSameDates(Date())
    }
    
    /// Creates an established free user (created months ago).
    static func establishedFreeUser() -> UserProfileBuilder {
        let creationDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let updateDate = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        
        return UserProfileBuilder()
            .withName("Established User")
            .withFreeSubscription()
            .withMockAvatar()
            .withCreatedAt(creationDate)
            .withUpdatedAt(updateDate)
    }
    
    /// Creates a premium user with active monthly subscription.
    static func premiumMonthlyUser() -> UserProfileBuilder {
        return UserProfileBuilder()
            .withName("Premium User")
            .withMonthlySubscription()
            .withActiveSubscription()
            .withMockAvatar()
            .withDarkAppearance()
    }
    
    /// Creates a premium user with active annual subscription.
    static func premiumAnnualUser() -> UserProfileBuilder {
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        
        return UserProfileBuilder()
            .withName("Annual Premium User")
            .withAnnualSubscription()
            .withSubscriptionExpiryDate(oneYearFromNow)
            .withMockAvatar()
    }
    
    /// Creates a user with an expiring subscription.
    static func expiringUser() -> UserProfileBuilder {
        return UserProfileBuilder()
            .withName("Expiring User")
            .withMonthlySubscription()
            .withExpiringSubscription()
    }
    
    /// Creates a user with an expired subscription.
    static func expiredUser() -> UserProfileBuilder {
        return UserProfileBuilder()
            .withName("Expired User")
            .withMonthlySubscription()
            .withExpiredSubscription()
    }
    
    /// Creates a long-time user with no subscription.
    static func veteranFreeUser() -> UserProfileBuilder {
        let creationDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let updateDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        
        return UserProfileBuilder()
            .withName("Veteran User")
            .withFreeSubscription()
            .withMockAvatar()
            .withLightAppearance()
            .withCreatedAt(creationDate)
            .withUpdatedAt(updateDate)
    }
    
    /// Creates a user for testing premium features.
    static func testPremiumUser() -> UserProfileBuilder {
        return UserProfileBuilder()
            .withName("Test Premium")
            .withAnnualSubscription()
            .withActiveSubscription()
    }
    
    /// Creates a user for testing free limitations.
    static func testFreeUser() -> UserProfileBuilder {
        return UserProfileBuilder()
            .withName("Test Free")
            .withFreeSubscription()
    }
}

// MARK: - Batch Creation Methods

public extension UserProfileBuilder {
    /// Creates a variety of user profiles for comprehensive testing.
    static func createVarietyOfUsers() -> [UserProfile] {
        return [
            newFreeUser().build(),
            establishedFreeUser().build(),
            premiumMonthlyUser().build(),
            premiumAnnualUser().build(),
            expiringUser().build(),
            expiredUser().build(),
            veteranFreeUser().build()
        ]
    }
    
    /// Creates multiple users with different subscription states.
    static func createSubscriptionTestUsers() -> [UserProfile] {
        return [
            testFreeUser().build(),
            testPremiumUser().withMonthlySubscription().build(),
            testPremiumUser().withAnnualSubscription().build(),
            expiringUser().build(),
            expiredUser().build()
        ]
    }
    
    /// Creates users for appearance testing (light, dark, system).
    static func createAppearanceTestUsers() -> [UserProfile] {
        return [
            newFreeUser().followSystemAppearance().withName("System User").build(),
            premiumMonthlyUser().withLightAppearance().withName("Light User").build(),
            premiumAnnualUser().withDarkAppearance().withName("Dark User").build()
        ]
    }
}

// MARK: - Validation Helpers

public extension UserProfileBuilder {
    /// Validates that a user profile has all required fields set.
    func validate() -> Bool {
        return !name.isEmpty && appearance >= 0 && appearance <= 2
    }
    
    /// Creates a profile with intentionally invalid data for error testing.
    static func invalidProfile() -> UserProfileBuilder {
        return UserProfileBuilder()
            .withName("")  // Invalid: empty name
            .withAppearance(999)  // Invalid: out of range
    }
    
    /// Checks if the built profile would have an active subscription.
    func willHaveActiveSubscription() -> Bool {
        let profile = build()
        return profile.hasActiveSubscription
    }
    
    /// Checks if the built profile would be a premium user.
    func willBePremiumUser() -> Bool {
        let profile = build()
        return profile.isPremiumUser
    }
}