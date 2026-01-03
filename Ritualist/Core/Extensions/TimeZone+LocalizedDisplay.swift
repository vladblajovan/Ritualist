//
//  TimeZone+LocalizedDisplay.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 22.12.2025.
//
//  Provides localized timezone display names for better UX.
//  Uses iOS built-in localization to show user-friendly names.
//

import Foundation

extension TimeZone {

    /// Returns a user-friendly localized timezone name
    ///
    /// Examples:
    /// - "America/New_York" → "Eastern Time (US & Canada)"
    /// - "Europe/London" → "Greenwich Mean Time – London"
    /// - "Asia/Tokyo" → "Japan Standard Time"
    ///
    /// Falls back to cleaned identifier if localization unavailable.
    var localizedDisplayName: String {
        // Use the generic name which gives timezone region names
        if let name = localizedName(for: .generic, locale: .current), !name.isEmpty {
            return name
        }
        // Fallback: use standard name
        if let name = localizedName(for: .standard, locale: .current), !name.isEmpty {
            return name
        }
        // Last resort: clean up the identifier
        return cleanedIdentifier
    }

    /// Returns the city/region portion of the identifier
    ///
    /// Examples:
    /// - "America/New_York" → "New York"
    /// - "Europe/London" → "London"
    /// - "Asia/Tokyo" → "Tokyo"
    var cityName: String {
        // Get the last component and clean it
        let components = identifier.split(separator: "/")
        if let city = components.last {
            return String(city).replacingOccurrences(of: "_", with: " ")
        }
        return cleanedIdentifier
    }

    /// Returns a compact display format with abbreviation and offset
    ///
    /// Examples:
    /// - "EST (GMT-5)"
    /// - "JST (GMT+9)"
    /// - "GMT (GMT+0)"
    var compactDisplayName: String {
        let abbrev = abbreviation() ?? identifier
        return "\(abbrev) (\(gmtOffsetString))"
    }

    /// Returns a full display with city and offset
    ///
    /// Examples:
    /// - "New York (GMT-5)"
    /// - "Tokyo (GMT+9)"
    var cityWithOffset: String {
        "\(cityName) (\(gmtOffsetString))"
    }

    /// Returns the identifier with underscores replaced by spaces
    var cleanedIdentifier: String {
        identifier.replacingOccurrences(of: "_", with: " ")
    }

    /// Returns GMT offset string
    ///
    /// Examples:
    /// - "GMT-5"
    /// - "GMT+9"
    /// - "GMT+0"
    var gmtOffsetString: String {
        let totalSeconds = secondsFromGMT()
        let hours = totalSeconds / 3600
        let minutes = abs(totalSeconds % 3600) / 60

        if minutes == 0 {
            let sign = hours >= 0 ? "+" : ""
            return "GMT\(sign)\(hours)"
        } else {
            let sign = hours >= 0 ? "+" : "-"
            return "GMT\(sign)\(abs(hours)):\(String(format: "%02d", minutes))"
        }
    }

    /// Returns a searchable string combining multiple representations
    /// Useful for timezone picker search functionality
    var searchableText: String {
        [
            identifier,
            localizedDisplayName,
            cityName,
            abbreviation() ?? ""
        ].joined(separator: " ")
    }
}
