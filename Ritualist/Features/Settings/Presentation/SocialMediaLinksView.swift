import SwiftUI
import RitualistCore

/// Social media links section for Settings page
struct SocialMediaLinksView: View {
    var body: some View {
        Section("Connect With Us") {
            // Instagram
            SocialMediaButton(
                iconName: "camera.fill",
                iconColor: .purple,
                title: "Instagram",
                url: AppURL.instagram
            )

            // X (Twitter)
            SocialMediaButton(
                iconName: "bird.fill",
                iconColor: .blue,
                title: "X (Twitter)",
                url: AppURL.twitter
            )

            // TikTok
            SocialMediaButton(
                iconName: "music.note",
                iconColor: .black,
                title: "TikTok",
                url: AppURL.tiktok
            )

            // Website/App Link
            SocialMediaButton(
                iconName: "globe",
                iconColor: .green,
                title: "Visit Our Website",
                url: AppURL.website
            )
        }
    }
}

/// Individual social media button row
private struct SocialMediaButton: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let url: URL?

    var body: some View {
        Button {
            openURL()
        } label: {
            HStack(spacing: Spacing.medium) {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.title2)
                    .frame(width: IconSize.large)

                Text(title)
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
        SocialMediaLinksView()
    }
}
