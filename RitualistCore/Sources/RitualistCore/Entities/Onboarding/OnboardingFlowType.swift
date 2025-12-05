//
//  OnboardingFlowType.swift
//  RitualistCore
//
//  Created by Claude on 27.11.2025.
//
//  Determines which onboarding flow to show based on existing iCloud data.
//

import Foundation

/// The type of onboarding flow to show the user
public enum OnboardingFlowType: Equatable {
    /// New user - show full onboarding (name, avatar, habits, permissions)
    case newUser

    /// Returning user with existing iCloud data - show welcome back + permissions only
    case returningUser(summary: SyncedDataSummary)
}

/// Summary of data synced from iCloud for returning user display
public struct SyncedDataSummary: Equatable {
    /// Number of habits synced from iCloud
    public let habitsCount: Int

    /// Number of categories synced from iCloud
    public let categoriesCount: Int

    /// Whether a user profile exists with data
    public let hasProfile: Bool

    /// User's name from profile (if available)
    public let profileName: String?

    /// User's avatar data from profile (if available)
    public let profileAvatar: Data?

    /// User's gender from profile (if available)
    public let profileGender: String?

    /// User's age group from profile (if available)
    public let profileAgeGroup: String?

    public init(
        habitsCount: Int,
        categoriesCount: Int,
        hasProfile: Bool,
        profileName: String?,
        profileAvatar: Data?,
        profileGender: String? = nil,
        profileAgeGroup: String? = nil
    ) {
        self.habitsCount = habitsCount
        self.categoriesCount = categoriesCount
        self.hasProfile = hasProfile
        self.profileName = profileName
        self.profileAvatar = profileAvatar
        self.profileGender = profileGender
        self.profileAgeGroup = profileAgeGroup
    }

    /// Whether any meaningful data was synced
    public var hasData: Bool {
        habitsCount > 0 || hasProfile
    }

    /// Whether profile demographics are incomplete (missing gender or ageGroup)
    /// Note: Name is not required - user may have skipped it during onboarding
    public var needsProfileCompletion: Bool {
        let hasGender = profileGender != nil
        let hasAgeGroup = profileAgeGroup != nil
        return !hasGender || !hasAgeGroup
    }

    /// Empty summary (no data found)
    public static let empty = SyncedDataSummary(
        habitsCount: 0,
        categoriesCount: 0,
        hasProfile: false,
        profileName: nil,
        profileAvatar: nil,
        profileGender: nil,
        profileAgeGroup: nil
    )
}
