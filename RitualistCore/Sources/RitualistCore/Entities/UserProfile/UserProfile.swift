//
//  UserProfile.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct UserProfile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var avatarImageData: Data?
    public var appearance: Int // 0 followSystem, 1 light, 2 dark

    // MARK: - Three-Timezone Model

    /// The device's current timezone (auto-detected, read-only)
    /// Updated automatically when device timezone changes (travel, system settings)
    /// Role: Informational - "Where am I right now?"
    public var currentTimezoneIdentifier: String

    /// User's designated home timezone (user-defined, stable)
    /// User sets this to their primary/home location
    /// Role: Semantic - "Where do I live?"
    public var homeTimezoneIdentifier: String

    /// How to display habit data (user chooses: current, home, or custom)
    /// This timezone controls ALL calculations: "Today", streaks, statistics
    /// Role: Functional - "How do I want to view my data?"
    public var displayTimezoneMode: DisplayTimezoneMode

    /// Historical record of timezone changes for debugging and analytics
    public var timezoneChangeHistory: [TimezoneChange]

    // MARK: - Demographics (Added in V11)

    /// User's gender preference (raw value from UserGender enum)
    public var gender: String?

    /// User's age group (raw value from UserAgeGroup enum)
    public var ageGroup: String?

    // MARK: - Metadata

    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String = "",
        avatarImageData: Data? = nil,
        appearance: Int = 0,
        currentTimezoneIdentifier: String = TimeZone.current.identifier,
        homeTimezoneIdentifier: String = TimeZone.current.identifier,
        displayTimezoneMode: DisplayTimezoneMode = .current,
        timezoneChangeHistory: [TimezoneChange] = [],
        gender: String? = nil,
        ageGroup: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.avatarImageData = avatarImageData
        self.appearance = appearance
        self.currentTimezoneIdentifier = currentTimezoneIdentifier
        self.homeTimezoneIdentifier = homeTimezoneIdentifier
        self.displayTimezoneMode = displayTimezoneMode
        self.timezoneChangeHistory = timezoneChangeHistory
        self.gender = gender
        self.ageGroup = ageGroup
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Resolves the actual TimeZone to use for all habit calculations based on display mode
    public var displayTimezone: TimeZone {
        displayTimezoneMode.resolveTimezone(
            currentTimezoneIdentifier: currentTimezoneIdentifier,
            homeTimezoneIdentifier: homeTimezoneIdentifier
        ) ?? .current
    }
}
