//
//  AppBrandHeaderViewLogic.swift
//  Ritualist
//
//  View logic for AppBrandHeader component.
//  Extracted for testability.
//

import Foundation

/// View logic for AppBrandHeader component
/// Handles decisions about what to display based on profile state
public struct AppBrandHeaderViewLogic {

    // MARK: - Avatar Content

    /// Represents what content to display inside the avatar circle
    public enum AvatarContentType: Equatable {
        /// Show user's profile image
        case image
        /// Show initials derived from name
        case initials
        /// Show nothing (just the progress gradient ring)
        case empty
    }

    /// Determines what content to display inside the avatar circle
    ///
    /// The avatar circle with progress gradient is always visible.
    /// This determines what goes inside:
    /// - Image if available
    /// - Initials if name is available
    /// - Empty (just gradient ring) otherwise
    ///
    /// - Parameters:
    ///   - hasAvatarImage: Whether user has set a profile image
    ///   - name: User's profile name
    /// - Returns: The content type to display
    public static func avatarContentType(hasAvatarImage: Bool, name: String) -> AvatarContentType {
        if hasAvatarImage {
            return .image
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return .initials
        }

        return .empty
    }

    // MARK: - Avatar Initials

    /// Generates initials from a name for avatar display
    ///
    /// - Parameter name: User's profile name
    /// - Returns: 1-2 character initials, or empty string if name is empty
    public static func avatarInitials(from name: String) -> String {
        let words = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        if words.count >= 2 {
            return String(words[0].prefix(1)).uppercased() + String(words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(first.count >= 2 ? 2 : 1)).uppercased()
        }
        return ""
    }
}
