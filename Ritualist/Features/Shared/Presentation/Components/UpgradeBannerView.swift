//
//  UpgradeBannerView.swift
//  Ritualist
//
//  Generic upgrade banner for promoting premium features.
//

import SwiftUI
import RitualistCore

/// Generic upgrade banner that can be configured for different contexts
struct UpgradeBannerView: View {
    let title: String
    let subtitle: String?
    let icon: String
    let onUpgradeTap: () -> Void

    init(
        title: String = "Upgrade to Pro",
        subtitle: String? = nil,
        icon: String = "crown.fill",
        onUpgradeTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.onUpgradeTap = onUpgradeTap
    }

    var body: some View {
        Button(action: onUpgradeTap) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    Text(title)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Default") {
    List {
        Section {
            UpgradeBannerView(onUpgradeTap: {})
        }
    }
}

#Preview("With Subtitle") {
    List {
        Section {
            UpgradeBannerView(
                title: "Upgrade to Pro",
                subtitle: "Sync your habits across all your devices",
                onUpgradeTap: {}
            )
        }
    }
}

#Preview("Custom Icon") {
    List {
        Section {
            UpgradeBannerView(
                title: "Unlock iCloud Sync",
                subtitle: "Keep your habits in sync everywhere",
                icon: "icloud.fill",
                onUpgradeTap: {}
            )
        }
    }
}
