//
//  DeepLinkAction.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 19.08.2025.
//

import Foundation

/// Type-safe enumeration for deep link action types
/// Replaces hardcoded strings for better type safety and maintainability
public enum DeepLinkAction: String, CaseIterable {
    /// View action for completed binary habits - just navigate to view the date
    case view = "view"
    
    /// Progress action for numeric habits - navigate and potentially show progress sheet
    case progress = "progress"
    
    /// Returns the string value for use in query parameters
    public var queryValue: String { rawValue }
    
    /// Friendly description for debugging and logging
    public var description: String {
        switch self {
        case .view:
            return "View completed habit on date"
        case .progress:
            return "Open progress sheet for numeric habit"
        }
    }
}

// MARK: - Validation Extension

public extension DeepLinkAction {
    /// Creates a DeepLinkAction from a string, with fallback to view for unknown actions
    /// - Parameter actionString: The action string from URL query parameters
    /// - Returns: DeepLinkAction enum value, defaults to .view for unknown strings
    static func from(actionString: String?) -> DeepLinkAction {
        guard let actionString = actionString,
              let action = DeepLinkAction(rawValue: actionString) else {
            return .view  // Default fallback
        }
        return action
    }
}
