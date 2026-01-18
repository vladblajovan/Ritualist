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

    // MARK: - Dependencies (Internal for Extension Access)

    @Injected(\.settingsViewModel) var settingsVM
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Size Constants (Internal for Extension Access)

    let avatarOuterSize: CGFloat = 36
    let avatarRingWidth: CGFloat = 3
    let circularProgressLineWidth: CGFloat = 4
    var avatarInnerSize: CGFloat { avatarOuterSize - (avatarRingWidth * 2) }

    let crownBadgeSize: CGFloat = 14
    let circularProgressGap: CGFloat = 8
    var circularProgressSize: CGFloat { avatarOuterSize + circularProgressGap }

    let actionButtonSize: CGFloat = 36
    var actionButtonBackground: Color {
        colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }

    // MARK: - Animation State (Internal for Extension Access)

    @State var animatedCompletionPercentage: Double = 0.0
    @State var showProgressGlow = false
    @State var hasInitializedProgress = false
    @State var progressGlowTask: Task<Void, Never>?
    @State private var showingSettings = false
    @State private var profileRefreshTrigger = UUID()
    private let circleProgressTip = CircleProgressTip()

    // MARK: - Computed Properties (Internal for Extension Access)

    var glowShadowColor: Color {
        showProgressGlow ? Color.green.opacity(CardDesign.glowOpacity) : .clear
    }

    var glowRadius: CGFloat {
        showProgressGlow ? CardDesign.glowRadius : 0
    }

    // MARK: - Constants

    private static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Ritualist"

    private var circularProgressOverhang: CGFloat {
        (circularProgressGap + circularProgressLineWidth) / 2
    }

    // MARK: - Profile Avatar Button

    @ViewBuilder
    private var profileAvatarButton: some View {
        let button = Button {
            showingSettings = true
        } label: {
            profileAvatarViewWithoutCrown
        }
        .buttonStyle(.plain)
        .transaction { $0.animation = nil }
        .accessibilityLabel("Profile")
        .accessibilityHint("Double tap to open settings")
        .id(profileRefreshTrigger)

        if showAvatarTip {
            button.popoverTip(circleProgressTip, arrowEdge: .top)
        } else {
            button
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            gradientTitle

            if showProgressBar && completionPercentage != nil && progressDisplayStyle == .linear {
                progressBar
            }
        }
        .padding(.horizontal, Spacing.xxlarge)
        .padding(.bottom, circularProgressOverhang)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color(.systemGroupedBackground).opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 16)
            .offset(y: 16)
            .allowsHitTesting(false)
        }
        .onAppear {
            if let percentage = completionPercentage {
                animatedCompletionPercentage = percentage
                hasInitializedProgress = true
            }
        }
        .task {
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
            Task { @MainActor in
                await settingsVM.refreshSubscriptionStatus()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileDidChange)) { _ in
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
            Image("LaunchIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: CardDesign.brandHeaderFontSize, height: CardDesign.brandHeaderFontSize)
                .shadow(color: glowShadowColor, radius: glowRadius, x: 0, y: 0)

            Text(Self.appName)
                .font(CardDesign.brandHeaderFont)
                .overlay(
                    LinearGradient(
                        colors: progressGradientColors(for: completionPercentage ?? 0.0),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(Text(Self.appName).font(CardDesign.brandHeaderFont))
                )
                .shadow(color: glowShadowColor, radius: glowRadius, x: 0, y: 0)

            Spacer()

            ForEach(actions.prefix(3)) { action in
                actionButton(action)
            }

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

                    if settingsVM.isPremiumUser {
                        premiumCrownBadge
                            .allowsHitTesting(false)
                    }
                }
                .padding(.leading, Spacing.xsmall)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.appName) progress header")
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
