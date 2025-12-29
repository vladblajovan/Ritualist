//
//  AppBrandHeader.swift
//  Ritualist
//
//  Reusable app branding header with animated progress bar.
//  Displays the app icon + name with gradient coloring based on completion percentage.
//

import SwiftUI
import RitualistCore
import FactoryKit

/// Reusable app branding header with optional progress bar.
///
/// Features:
/// - App icon + "Ritualist" text with gradient overlay
/// - Gradient colors adapt based on completion percentage (red → orange → green)
/// - Optional progress bar with matching gradient
/// - Glow animation when reaching 100% completion
/// - Profile avatar with tap-to-settings navigation (self-contained)
///
/// Usage:
/// ```swift
/// AppBrandHeader(completionPercentage: viewModel.completionPercentage)
/// ```
struct AppBrandHeader: View {
    // MARK: - Input

    /// Current completion percentage (0.0 to 1.0). Pass nil to hide progress bar.
    let completionPercentage: Double?

    /// Whether to show the progress bar. Defaults to true.
    var showProgressBar: Bool = true

    /// Whether to animate the progress bar on initial load. Defaults to true.
    var animateProgressOnLoad: Bool = true

    /// Whether to show the profile avatar. Defaults to true.
    /// Set to false when used in Settings to avoid redundancy.
    var showProfileAvatar: Bool = true

    // MARK: - Injected Dependencies

    @Injected(\.settingsViewModel) private var settingsVM
    @Injected(\.navigationService) private var navigationService

    // MARK: - Profile Avatar Size

    /// Size for the profile avatar (slightly smaller than the header text)
    private let profileAvatarSize: CGFloat = 32

    // MARK: - Profile Avatar View

    /// Custom avatar view without disabled tint (AvatarView's button is disabled when showEditBadge is false)
    @ViewBuilder
    private var profileAvatarView: some View {
        ZStack {
            Circle()
                .fill(avatarBackgroundColor)
                .frame(width: profileAvatarSize, height: profileAvatarSize)

            if let imageData = settingsVM.profile.avatarImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: profileAvatarSize, height: profileAvatarSize)
                    .clipShape(Circle())
            } else if !avatarInitials.isEmpty {
                Text(avatarInitials)
                    .font(.system(size: profileAvatarSize * 0.4, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }

    private var avatarInitials: String {
        let name = settingsVM.profile.name
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

    private var avatarBackgroundColor: Color {
        if settingsVM.profile.avatarImageData != nil {
            return .clear
        } else if !avatarInitials.isEmpty {
            // Generate consistent color based on name
            let hash = settingsVM.profile.name.hashValue
            let colors: [Color] = [AppColors.brand, .blue, .green, .orange, .purple, .red, .pink, .indigo]
            return colors[abs(hash) % colors.count]
        }
        return Color(.systemGray4)
    }

    // MARK: - Animation State

    @State private var animatedCompletionPercentage: Double = 0.0
    @State private var showProgressGlow = false
    @State private var hasInitializedProgress = false
    @State private var progressGlowTask: Task<Void, Never>?

    // MARK: - Constants

    /// App name from bundle (uses display name if available, falls back to bundle name)
    private static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Ritualist"

    /// Animation timing constants (in nanoseconds)
    private enum AnimationTiming {
        static let progressAnimationDelay: UInt64 = 600_000_000   // 0.6s - match progress bar animation
        static let glowFadeDelay: UInt64 = 2_000_000_000          // 2s - glow fade out delay
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            gradientTitle
            if showProgressBar && completionPercentage != nil {
                progressBar
            }
        }
        .onAppear {
            // Initialize progress immediately when view appears
            // No animation on appear - prevents jarring animation when toggling sticky mode
            if let percentage = completionPercentage {
                animatedCompletionPercentage = percentage
                hasInitializedProgress = true
            }
        }
        .task {
            // Ensure profile is loaded (SettingsViewModel only loads when Settings view appears)
            if settingsVM.profile.name.isEmpty {
                await settingsVM.load()
            }
        }
        .onChange(of: completionPercentage) { oldValue, newValue in
            handleCompletionPercentageChange(oldValue: oldValue, newValue: newValue)
        }
        .onDisappear {
            progressGlowTask?.cancel()
        }
    }

    // MARK: - Gradient Title

    @ViewBuilder
    private var gradientTitle: some View {
        HStack(spacing: Spacing.screenMargin) {
            // App icon - shown as-is without gradient overlay
            Image("LaunchIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: CardDesign.brandHeaderFontSize, height: CardDesign.brandHeaderFontSize)
                .shadow(
                    color: showProgressGlow ? Color.green.opacity(CardDesign.glowOpacity) : .clear,
                    radius: showProgressGlow ? CardDesign.glowRadius : 0,
                    x: 0,
                    y: 0
                )

            // App name with gradient overlay
            Text(Self.appName)
                .font(.system(size: CardDesign.brandHeaderFontSize, weight: .bold))
                .overlay(
                    LinearGradient(
                        colors: progressGradientColors(for: completionPercentage ?? 0.0),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        Text(Self.appName)
                            .font(.system(size: CardDesign.brandHeaderFontSize, weight: .bold))
                    )
                )
                .shadow(
                    color: showProgressGlow ? Color.green.opacity(CardDesign.glowOpacity) : .clear,
                    radius: showProgressGlow ? CardDesign.glowRadius : 0,
                    x: 0,
                    y: 0
                )

            Spacer()

            // Profile avatar - navigates to settings on tap
            if showProfileAvatar {
                Button {
                    navigationService.selectedTab = .settings
                } label: {
                    profileAvatarView
                }
                .buttonStyle(.plain)
                .transaction { $0.animation = nil } // Prevent progress bar animation from affecting avatar
                .accessibilityLabel("Profile")
                .accessibilityHint("Double tap to open settings")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.appName) progress header")
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(CardDesign.secondaryBackground)
                    .frame(height: CardDesign.progressBarHeight)

                // Progress fill with gradient
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(
                        .linearGradient(
                            colors: progressGradientColors(for: animatedCompletionPercentage),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedCompletionPercentage, height: CardDesign.progressBarHeight)
                    .shadow(
                        color: showProgressGlow ? Color.green.opacity(CardDesign.glowOpacity) : .clear,
                        radius: showProgressGlow ? CardDesign.glowRadius : 0,
                        x: 0,
                        y: 0
                    )
            }
        }
        .frame(height: CardDesign.progressBarHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int((completionPercentage ?? 0) * 100)) percent")
    }

    // MARK: - Helpers

    /// Calculate gradient colors based on completion percentage.
    /// Delegates to CircularProgressView.adaptiveProgressColors to maintain consistency.
    private func progressGradientColors(for completion: Double) -> [Color] {
        CircularProgressView.adaptiveProgressColors(for: completion)
    }

    /// Handle completion percentage changes with animation and glow effects.
    private func handleCompletionPercentageChange(oldValue: Double?, newValue: Double?) {
        guard let newValue = newValue else { return }

        let shouldAnimate = hasInitializedProgress ? true : animateProgressOnLoad

        if shouldAnimate {
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedCompletionPercentage = newValue
            }
        } else {
            animatedCompletionPercentage = newValue
        }

        hasInitializedProgress = true

        // Trigger glow animation when reaching 100%
        if shouldAnimate && newValue >= 1.0, oldValue ?? 0.0 < 1.0 {
            progressGlowTask?.cancel()
            progressGlowTask = Task {
                try? await Task.sleep(nanoseconds: AnimationTiming.progressAnimationDelay)
                withAnimation(.easeInOut(duration: 0.3)) {
                    showProgressGlow = true
                }
                try? await Task.sleep(nanoseconds: AnimationTiming.glowFadeDelay)
                withAnimation(.easeOut(duration: 0.5)) {
                    showProgressGlow = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Progress") {
    VStack(spacing: 32) {
        AppBrandHeader(completionPercentage: 0.3)
        AppBrandHeader(completionPercentage: 0.6)
        AppBrandHeader(completionPercentage: 1.0)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Without Progress") {
    AppBrandHeader(completionPercentage: nil)
        .padding()
        .background(Color(.systemGroupedBackground))
}
