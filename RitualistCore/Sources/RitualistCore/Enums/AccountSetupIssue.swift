//
//  AccountSetupIssue.swift
//  RitualistCore
//
//  Represents issues with account setup that might affect purchases or sync.
//

import Foundation

/// Issues with account setup that might affect purchases or cloud sync
public enum AccountSetupIssue: String, CaseIterable, Identifiable {
    case iCloudNotSignedIn
    case purchasesRestricted
    case noNetwork

    public var id: String { rawValue }

    /// User-friendly title for the issue
    public var title: String {
        switch self {
        case .iCloudNotSignedIn:
            return "iCloud Not Available"
        case .purchasesRestricted:
            return "Purchases"
        case .noNetwork:
            return "Network"
        }
    }

    /// User-friendly description of the issue
    public var description: String {
        switch self {
        case .iCloudNotSignedIn:
            return "Not signed in"
        case .purchasesRestricted:
            return "Restricted by device settings"
        case .noNetwork:
            return "No internet connection"
        }
    }

    /// SF Symbol icon for the issue
    public var icon: String {
        switch self {
        case .iCloudNotSignedIn:
            return "icloud.slash"
        case .purchasesRestricted:
            return "lock.fill"
        case .noNetwork:
            return "wifi.slash"
        }
    }

    /// Guidance on how to resolve the issue
    public var resolution: String {
        switch self {
        case .iCloudNotSignedIn:
            return "Sign in at Settings → Apple ID"
        case .purchasesRestricted:
            return "Check Screen Time or parental controls"
        case .noNetwork:
            return "Connect to Wi-Fi or cellular data"
        }
    }

    /// Whether this issue is critical (blocks purchases entirely)
    public var isCritical: Bool {
        switch self {
        case .purchasesRestricted:
            return true // Device-level block
        case .iCloudNotSignedIn, .noNetwork:
            return false // Can still attempt, system will prompt
        }
    }
}
