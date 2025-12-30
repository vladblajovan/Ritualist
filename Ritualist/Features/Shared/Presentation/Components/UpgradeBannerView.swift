//
//  UpgradeBannerView.swift
//  Ritualist
//
//  Generic upgrade banner for promoting premium features.
//

import SwiftUI
import RitualistCore

/// Generic upgrade banner that can be configured for different contexts
/// Thin wrapper around ProUpgradeBanner for backward compatibility
struct UpgradeBannerView: View {
    let title: String
    let subtitle: String?
    let onUpgradeTap: () -> Void

    init(
        title: String = "Unlock all features",
        subtitle: String? = "Get unlimited habits, insights, and more",
        onUpgradeTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onUpgradeTap = onUpgradeTap
    }

    var body: some View {
        ProUpgradeBanner(
            style: .row(title: title, subtitle: subtitle),
            onUnlock: onUpgradeTap
        )
    }
}

#Preview("Default") {
    List {
        Section {
            UpgradeBannerView(onUpgradeTap: {})
        }
    }
}

#Preview("Custom Text") {
    List {
        Section {
            UpgradeBannerView(
                title: "Unlock iCloud Sync",
                subtitle: "Keep your habits in sync everywhere",
                onUpgradeTap: {}
            )
        }
    }
}
