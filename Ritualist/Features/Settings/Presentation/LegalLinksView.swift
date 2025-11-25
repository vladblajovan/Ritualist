//
//  LegalLinksView.swift
//  Ritualist
//
//  Legal links section for Settings page (Privacy Policy, Terms of Service)
//  Required for App Store compliance with in-app purchases
//

import SwiftUI
import RitualistCore

/// Legal links section for Settings page
struct LegalLinksView: View {
    var body: some View {
        Section("Legal") {
            // Privacy Policy
            LegalLinkButton(
                title: "Privacy Policy",
                systemImage: "hand.raised.fill",
                url: AppURL.privacyPolicy
            )

            // Terms of Service
            LegalLinkButton(
                title: "Terms of Service",
                systemImage: "doc.text.fill",
                url: AppURL.termsOfService
            )
        }
    }
}

/// Individual legal link button row
private struct LegalLinkButton: View {
    let title: String
    let systemImage: String
    let url: URL?

    var body: some View {
        Button {
            openURL()
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func openURL() {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    Form {
        LegalLinksView()
    }
}
