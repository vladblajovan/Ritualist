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
import TipKit

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

/// Display style for the progress indicator
enum ProgressDisplayStyle {
    /// Linear progress bar below the header
    case linear
    /// Circular progress ring around the avatar
    case circular
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

    /// Display style for progress indicator. Defaults to linear.
    var progressDisplayStyle: ProgressDisplayStyle = .linear

    /// Whether to animate the progress bar on initial load. Defaults to true.
    var animateProgressOnLoad: Bool = true

    /// Whether to show the profile avatar. Defaults to true.
    /// Set to false when used in Settings to avoid redundancy.
    var showProfileAvatar: Bool = true

    /// Whether to show the avatar/progress tip. Defaults to false.
    /// Only enable on Overview tab to avoid showing tips on multiple screens.
    var showAvatarTip: Bool = false

    /// Optional action buttons displayed to the left of the profile avatar (max 3)
    var actions: [HeaderAction] = []

    // MARK: - Injected Dependencies

    @Injected(\.settingsViewModel) private var settingsVM
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Profile Avatar Size

    /// Outer size for the profile avatar (includes gradient ring)
    private let avatarOuterSize: CGFloat = 36
    /// Width of the progress gradient ring around the avatar (for solid ring)
    private let avatarRingWidth: CGFloat = 3
    /// Width of the circular progress stroke
    private let circularProgressLineWidth: CGFloat = 4
    /// Inner content size (for image or initials)
    private var avatarInnerSize: CGFloat { avatarOuterSize - (avatarRingWidth * 2) }

    // MARK: - Profile Avatar View

    /// Avatar view with progress gradient ring or circular progress (without crown badge for button label)
    /// - When progressDisplayStyle is .linear: shows solid gradient ring
    /// - When progressDisplayStyle is .circular: shows gradient avatar with circular progress ring on top
    /// - Inside: user image, initials, or empty (just gradient)
    @ViewBuilder
    private var profileAvatarViewWithoutCrown: some View {
        let contentType = AppBrandHeaderViewLogic.avatarContentType(
            hasAvatarImage: settingsVM.profile.avatarImageData != nil,
            name: settingsVM.profile.name
        )

        // Always show circular progress ring when style is circular - shows empty ring (0%) when no progress data
        let showCircularProgress = progressDisplayStyle == .circular && showProgressBar
        let hasAvatarImage = contentType == .image

        ZStack {
            // Show gradient-filled avatar background only when no image is present
            if !hasAvatarImage {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: progressGradientColors(for: completionPercentage ?? 0.0),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarOuterSize, height: avatarOuterSize)
            }

            // Inner content based on type
            switch contentType {
            case .image:
                // Show image at full size (no gradient border)
                if let imageData = settingsVM.profile.avatarImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: avatarOuterSize, height: avatarOuterSize)
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
        .overlay {
            // Circular progress ring as overlay - doesn't affect avatar position
            if showCircularProgress {
                circularProgressRing
            }
        }
    }

    // MARK: - Premium Crown Badge

    /// Size of the crown badge
    private let crownBadgeSize: CGFloat = 14

    @ViewBuilder
    private var premiumCrownBadge: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(GradientTokens.premiumCrown)
            .frame(width: crownBadgeSize, height: crownBadgeSize)
            .background(
                Circle()
                    .fill(colorScheme == .dark ? Color.white : Color.black)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            )
            .offset(x: 5, y: 5) // Offset to sit on the circular progress ring
    }

    // MARK: - Circular Progress Ring

    /// Gap between avatar and progress ring
    private let circularProgressGap: CGFloat = 8

    /// Size of the circular progress ring (larger than avatar to not overlap)
    private var circularProgressSize: CGFloat {
        avatarOuterSize + circularProgressGap
    }

    @ViewBuilder
    private var circularProgressRing: some View {
        let progress = animatedCompletionPercentage

        ZStack {
            // Background track - uses secondary with opacity for better contrast in light mode
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    style: StrokeStyle(lineWidth: circularProgressLineWidth, lineCap: .round)
                )
                .frame(width: circularProgressSize, height: circularProgressSize)

            // Progress arc with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: progressGradientColors(for: progress),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: circularProgressLineWidth, lineCap: .round)
                )
                .frame(width: circularProgressSize, height: circularProgressSize)
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut(duration: 0.6), value: progress)
                .shadow(
                    color: showProgressGlow ? Color.green.opacity(CardDesign.glowOpacity) : .clear,
                    radius: showProgressGlow ? CardDesign.glowRadius : 0,
                    x: 0,
                    y: 0
                )
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
    @State private var showingSettings = false
    @State private var profileRefreshTrigger = UUID()

    // MARK: - Tips

    private let circleProgressTip = CircleProgressTip()

    /// Profile avatar button with optional tip (only shown on Overview)
    @ViewBuilder
    private var profileAvatarButton: some View {
        let button = Button {
            showingSettings = true
        } label: {
            profileAvatarViewWithoutCrown
        }
        .buttonStyle(.plain)
        .transaction { $0.animation = nil } // Prevent progress bar animation from affecting avatar
        .accessibilityLabel("Profile")
        .accessibilityHint("Double tap to open settings")
        .id(profileRefreshTrigger) // Force re-render when profile loads

        if showAvatarTip {
            // CircleProgressTip is the last tip in the chain - no need to donate events on dismissal
            button.popoverTip(circleProgressTip, arrowEdge: .top)
        } else {
            button
        }
    }

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

    /// Extra bottom padding to accommodate circular progress ring overlay
    private var circularProgressOverhang: CGFloat {
        (circularProgressGap + circularProgressLineWidth) / 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            gradientTitle
            if showProgressBar && completionPercentage != nil && progressDisplayStyle == .linear {
                progressBar
            }
        }
        .padding(.bottom, circularProgressOverhang)
        .overlay(alignment: .bottom) {
            // Fade gradient that overlays scroll content for smooth fade effect
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground).opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 16)
            .offset(y: 16)
            .allowsHitTesting(false)
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
        .onReceive(NotificationCenter.default.publisher(for: .premiumStatusDidChange)) { _ in
            // Refresh premium status when purchase completes to update crown badge
            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
            Task { @MainActor in
                await settingsVM.refreshSubscriptionStatus()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileDidChange)) { _ in
            // Force reload profile data AND refresh view when profile changes
            // This ensures avatar initials appear immediately after onboarding completes
            // Simply changing profileRefreshTrigger isn't enough - we need fresh data from repository
            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
            Task { @MainActor in
                await settingsVM.reload()
                profileRefreshTrigger = UUID()
            }
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
                .font(CardDesign.brandHeaderFont)
                .overlay(
                    LinearGradient(
                        colors: progressGradientColors(for: completionPercentage ?? 0.0),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        Text(Self.appName)
                            .font(CardDesign.brandHeaderFont)
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

            // Profile avatar - always visible with progress gradient, opens settings sheet on tap
            if showProfileAvatar {
                ZStack(alignment: .bottomTrailing) {
                    profileAvatarButton
                    .fullScreenCover(isPresented: $showingSettings) {
                        NavigationStack {
                            SettingsRoot()
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button(Strings.Common.close) {
                                            showingSettings = false
                                        }
                                    }
                                }
                        }
                    }

                    // Crown badge outside button so it's not affected by button highlight
                    if settingsVM.isPremiumUser {
                        premiumCrownBadge
                            .allowsHitTesting(false)
                    }
                }
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
        // Default to 0 when nil - shows empty progress ring
        let effectiveNewValue = newValue ?? 0.0

        let shouldAnimate = hasInitializedProgress ? true : animateProgressOnLoad

        if shouldAnimate {
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedCompletionPercentage = effectiveNewValue
            }
        } else {
            animatedCompletionPercentage = effectiveNewValue
        }

        hasInitializedProgress = true

        // Trigger glow animation when reaching 100%
        if shouldAnimate && effectiveNewValue >= 1.0, oldValue ?? 0.0 < 1.0 {
            progressGlowTask?.cancel()
            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
            progressGlowTask = Task { @MainActor in
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

#Preview("Circular Progress") {
    VStack(spacing: 32) {
        AppBrandHeader(completionPercentage: 0.3, progressDisplayStyle: .circular)
        AppBrandHeader(completionPercentage: 0.6, progressDisplayStyle: .circular)
        AppBrandHeader(completionPercentage: 1.0, progressDisplayStyle: .circular)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
