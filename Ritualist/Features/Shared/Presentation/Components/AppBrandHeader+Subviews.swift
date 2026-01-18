//
//  AppBrandHeader+Subviews.swift
//  Ritualist
//
//  Subview components extracted from AppBrandHeader to reduce type body length.
//

import SwiftUI
import RitualistCore

// MARK: - Profile Avatar Components

extension AppBrandHeader {

    @ViewBuilder
    var profileAvatarViewWithoutCrown: some View {
        let contentType = AppBrandHeaderViewLogic.avatarContentType(
            hasAvatarImage: settingsVM.profile.avatarImageData != nil,
            name: settingsVM.profile.name
        )
        let showCircularProgress = progressDisplayStyle == .circular && showProgressBar

        ZStack {
            if contentType != .image {
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

            switch contentType {
            case .image:
                if let imageData = settingsVM.profile.avatarImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: avatarOuterSize, height: avatarOuterSize)
                        .clipShape(Circle())
                }

            case .initials:
                Text(AppBrandHeaderViewLogic.avatarInitials(from: settingsVM.profile.name))
                    .font(.system(size: avatarOuterSize * 0.38, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

            case .empty:
                EmptyView()
            }
        }
        .overlay {
            if showCircularProgress {
                circularProgressRing
            }
        }
    }

    @ViewBuilder
    var premiumCrownBadge: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(GradientTokens.premiumCrown)
            .frame(width: crownBadgeSize, height: crownBadgeSize)
            .background(
                Circle()
                    .fill(colorScheme == .dark ? Color.white : Color.black)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            )
            .offset(x: 5, y: 5)
    }
}

// MARK: - Circular Progress Ring

extension AppBrandHeader {

    @ViewBuilder
    var circularProgressRing: some View {
        let progress = animatedCompletionPercentage

        ZStack {
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    style: StrokeStyle(lineWidth: circularProgressLineWidth, lineCap: .round)
                )
                .frame(width: circularProgressSize, height: circularProgressSize)

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
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
                .shadow(
                    color: showProgressGlow ? Color.green.opacity(CardDesign.glowOpacity) : .clear,
                    radius: showProgressGlow ? CardDesign.glowRadius : 0,
                    x: 0,
                    y: 0
                )
        }
    }
}

// MARK: - Action Button

extension AppBrandHeader {

    @ViewBuilder
    func actionButton(_ action: HeaderAction) -> some View {
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
}

// MARK: - Progress Bar

extension AppBrandHeader {

    @ViewBuilder
    var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(CardDesign.secondaryBackground)
                    .frame(height: CardDesign.progressBarHeight)

                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(
                        .linearGradient(
                            colors: progressGradientColors(for: animatedCompletionPercentage),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * animatedCompletionPercentage,
                        height: CardDesign.progressBarHeight
                    )
                    .shadow(color: glowShadowColor, radius: glowRadius, x: 0, y: 0)
            }
        }
        .frame(height: CardDesign.progressBarHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int((completionPercentage ?? 0) * 100)) percent")
    }
}

// MARK: - Helper Methods

extension AppBrandHeader {

    func progressGradientColors(for completion: Double) -> [Color] {
        CircularProgressView.adaptiveProgressColors(for: completion)
    }

    func handleCompletionPercentageChange(oldValue: Double?, newValue: Double?) {
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

        // Trigger glow effect when reaching 100%
        let wasBelow100 = (oldValue ?? 0.0) < 1.0
        if shouldAnimate && effectiveNewValue >= 1.0 && wasBelow100 {
            progressGlowTask?.cancel()
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
