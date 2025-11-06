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
                url: "https://instagram.com/ritualist.app"
            )

            // X (Twitter)
            SocialMediaButton(
                iconName: "bird.fill",
                iconColor: .blue,
                title: "X (Twitter)",
                url: "https://x.com/ritualist_app"
            )

            // TikTok
            SocialMediaButton(
                iconName: "music.note",
                iconColor: .black,
                title: "TikTok",
                url: "https://tiktok.com/@ritualist.app"
            )

            // Website/App Link
            SocialMediaButton(
                iconName: "globe",
                iconColor: .green,
                title: "Visit Our Website",
                url: "https://ritualist.app"
            )
        }
    }
}

/// Individual social media button row
private struct SocialMediaButton: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let url: String

    var body: some View {
        Button {
            openURL(url)
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

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    Form {
        SocialMediaLinksView()
    }
}
