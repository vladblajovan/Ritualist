//
//  AppURLConstants.swift
//  RitualistCore
//
//  Centralized URL constants for the Ritualist application.
//  All external URLs should be defined here for easy maintenance.
//

import Foundation

/// Centralized URL constants for external links
///
/// Usage:
/// ```swift
/// if let url = AppURL.privacyPolicy {
///     UIApplication.shared.open(url)
/// }
/// ```
public enum AppURL {

    // MARK: - Base Domain

    /// Base website domain
    public static let baseDomain = "https://ritualist.app"

    // MARK: - Legal URLs

    /// Privacy Policy page
    public static let privacyPolicy = URL(string: "\(baseDomain)/privacy")

    /// Terms of Service page
    public static let termsOfService = URL(string: "\(baseDomain)/terms")

    // MARK: - Support URLs

    /// General support contact
    public static let support = URL(string: "mailto:support@ritualist.app")

    /// Privacy-related inquiries (GDPR/CCPA)
    public static let privacySupport = URL(string: "mailto:privacy@ritualist.app")

    // MARK: - Social Media URLs

    /// Main website
    public static let website = URL(string: baseDomain)

    /// Instagram profile
    public static let instagram = URL(string: "https://instagram.com/ritualist.app")

    /// X (Twitter) profile
    public static let twitter = URL(string: "https://x.com/ritualist_app")

    /// TikTok profile
    public static let tiktok = URL(string: "https://tiktok.com/@ritualist.app")

    // MARK: - App Store URLs

    /// App Store page (update with actual ID after launch)
    public static let appStore = URL(string: "https://apps.apple.com/app/ritualist/id000000000")

    /// Write a review on App Store
    public static let writeReview = URL(string: "https://apps.apple.com/app/ritualist/id000000000?action=write-review")
}
