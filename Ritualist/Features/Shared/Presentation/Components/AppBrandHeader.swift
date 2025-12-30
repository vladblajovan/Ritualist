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

/// Configuration for an action button in the header
struct HeaderAction: Identifiable {
    let id = UUID()
    let icon: String
    let action: () -> Void
    let accessibilityLabel: String

    init(icon: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
}

/// Reusable app branding header with optional progress bar.
///
/// Features:
/// - App icon + "Ritualist" text with gradient overlay
/// - Gradient colors adapt based on completion percentage (red → orange → green)
/// - Optional progress bar with matching gradient
/// - Glow animation when reaching 100% completion
/// - Optional configurable action buttons (circular, left of avatar)
/// - Profile avatar with tap-to-settings navigation (self-contained)
///
/// Usage:
/// ```swift
/// AppBrandHeader(completionPercentage: viewModel.completionPercentage)
///
/// // With action buttons:
/// AppBrandHeader(
///     completionPercentage: 0.5,
///     actions: [
///         HeaderAction(icon: "plus", accessibilityLabel: "Add") { print("Add tapped") }
///     ]
/// )
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

    /// Optional action buttons displayed to the left of the profile avatar (max 3)
    var actions: [HeaderAction] = []

    // MARK: - Injected Dependencies

    @Injected(\.settingsViewModel) private var settingsVM
    @Injected(\.navigationService) private var navigationService
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Profile Avatar Size

    /// Outer size for the profile avatar (includes gradient ring)
    private let avatarOuterSize: CGFloat = 36
    /// Width of the progress gradient ring around the avatar
    private let avatarRingWidth: CGFloat = 3
    /// Inner content size (for image or initials)
    private var avatarInnerSize: CGFloat { avatarOuterSize - (avatarRingWidth * 2) }

    // MARK: - Profile Avatar View

    /// Avatar view with progress gradient ring
    /// - Always shows progress gradient ring matching title/progress bar colors
    /// - Inside: user image, initials, or empty (just gradient)
    @ViewBuilder
    private var profileAvatarView: some View {
        let contentType = AppBrandHeaderViewLogic.avatarContentType(
            hasAvatarImage: settingsVM.profile.avatarImageData != nil,
            name: settingsVM.profile.name
        )

        ZStack {
            // Progress gradient circle (always visible as ring or full background)
            Circle()
                .fill(
                    LinearGradient(
                        colors: progressGradientColors(for: completionPercentage ?? 0.0),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: avatarOuterSize, height: avatarOuterSize)

            // Inner content based on type
            switch contentType {
            case .image:
                // Show image with visible gradient ring border
                if let imageData = settingsVM.profile.avatarImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: avatarInnerSize, height: avatarInnerSize)
                        .clipShape(Circle())
                }
            case .initials:
                // Show initials on gradient background (no inner cutout)
                Text(AppBrandHeaderViewLogic.avatarInitials(from: settingsVM.profile.name))
                    .font(.system(size: avatarOuterSize * 0.38, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            case .empty:
                // Just show the gradient circle (no additional content)
                EmptyView()
            }
        }
    }

    // MARK: - Action Button

    /// Size for action buttons (matches avatar for visual consistency)
    private let actionButtonSize: CGFloat = 36

    /// Background color for action buttons - white in light mode, gray in dark mode
    private var actionButtonBackground: Color {
        colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }

    @ViewBuilder
    private func actionButton(_ action: HeaderAction) -> some View {
        Button {
            action.action()
        } label: {
            ZStack {
                Circle()
                    .fill(actionButtonBackground)
                    .frame(width: actionButtonSize, height: actionButtonSize)

                Image(systemName: action.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.accessibilityLabel)
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

            // Action buttons - circular buttons to the left of avatar (max 3)
            ForEach(actions.prefix(3)) { action in
                actionButton(action)
            }

            // Profile avatar - always visible with progress gradient, navigates to settings on tap
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
