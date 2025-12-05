//
//  UserDemographics.swift
//  RitualistCore
//
//  User demographic enums for profile data.
//

import Foundation

// MARK: - User Gender

/// Represents user gender options for profile data
public enum UserGender: String, CaseIterable, Identifiable, Codable {
    case preferNotToSay = "prefer_not_to_say"
    case male = "male"
    case female = "female"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .preferNotToSay: return "Prefer not to say"
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

// MARK: - User Age Group

/// Represents user age group options for profile data
public enum UserAgeGroup: String, CaseIterable, Identifiable, Codable {
    case preferNotToSay = "prefer_not_to_say"
    case under18 = "under_18"
    case age18to24 = "18_24"
    case age25to34 = "25_34"
    case age35to44 = "35_44"
    case age45to54 = "45_54"
    case age55plus = "55_plus"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .preferNotToSay: return "Prefer not to say"
        case .under18: return "Under 18"
        case .age18to24: return "18-24"
        case .age25to34: return "25-34"
        case .age35to44: return "35-44"
        case .age45to54: return "45-54"
        case .age55plus: return "55+"
        }
    }
}
