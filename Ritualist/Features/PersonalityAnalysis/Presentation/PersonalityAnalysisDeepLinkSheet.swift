//
//  PersonalityAnalysisDeepLinkSheet.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import SwiftUI
import FactoryKit
import UserNotifications
import RitualistCore

#if canImport(UIKit)
import UIKit
#endif

/// Sheet that handles deep linking to personality analysis from notifications
public struct PersonalityAnalysisDeepLinkSheet: View {
    
    let action: PersonalityDeepLinkCoordinator.PersonalityNotificationAction?
    let onDismiss: () -> Void
    
    @Injected(\.personalityInsightsViewModel) private var viewModel: PersonalityInsightsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showWelcomeMessage = false
    
    public init(
        action: PersonalityDeepLinkCoordinator.PersonalityNotificationAction?,
        onDismiss: @escaping () -> Void
    ) {
        self.action = action
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if showWelcomeMessage, let action = action, !isDirectNavigation(action) {
                WelcomeMessageView(action: action, onDismiss: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showWelcomeMessage = false
                    }
                })
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Use PersonalityInsightsView which has its own NavigationView
            PersonalityInsightsView(viewModel: viewModel)
        }
        .deviceAwareSheetSizing(
            compactMultiplier: SizeMultiplier(min: 0.97, ideal: 1.0, max: 1.0),
            regularMultiplier: SizeMultiplier(min: 0.87, ideal: 1.0, max: 1.0),
            largeMultiplier: SizeMultiplier(min: 0.78, ideal: 0.89, max: 1.0)
        )
        // Removed .presentationBackground for full transparency
        .onAppear {
            handleNotificationAction()
            clearNotificationBadge()

            // Show welcome message (user dismisses manually) with haptic feedback
            withAnimation(.easeInOut(duration: 0.5)) {
                showWelcomeMessage = true
            }

            // Haptic feedback when banner appears
            #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        }
    }
    
    private func handleNotificationAction() {
        guard let action = action else { return }
        
        Task {
            switch action {
            case .openAnalysis:
                // Load the personality insights
                await viewModel.loadPersonalityInsights()
                
            case .openRequirements:
                // Load insights which will show requirements if insufficient data
                await viewModel.loadPersonalityInsights()
                
            case .checkAnalysis:
                // Trigger an analysis check
                await viewModel.triggerManualAnalysisCheck()
                
            case .directNavigation:
                // Load the personality insights (same as openAnalysis but without notification context)
                await viewModel.loadPersonalityInsights()
            }
        }
    }
    
    private func handleDismiss() {
        onDismiss()
        dismiss()
    }
    
    private func isDirectNavigation(_ action: PersonalityDeepLinkCoordinator.PersonalityNotificationAction) -> Bool {
        if case .directNavigation = action {
            return true
        }
        return false
    }
    
    private func clearNotificationBadge() {
        // Clear the app badge when user opens the notification
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - Welcome Message View

private struct WelcomeMessageView: View {
    let action: PersonalityDeepLinkCoordinator.PersonalityNotificationAction
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss welcome message")
            .accessibilityHint("Double tap to close this notification banner")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(subtitle)")
    }
    
    private var iconName: String {
        switch action {
        case .openAnalysis(let trait, _):
            return trait?.systemIconName ?? "sparkles"
        case .openRequirements:
            return "leaf"
        case .checkAnalysis:
            return "magnifyingglass"
        case .directNavigation:
            return "chart.bar"
        }
    }
    
    private var iconColor: Color {
        switch action {
        case .openAnalysis:
            return .blue
        case .openRequirements:
            return .orange
        case .checkAnalysis:
            return .purple
        case .directNavigation:
            return .blue
        }
    }
    
    private var title: String {
        switch action {
        case .openAnalysis(let trait, _):
            if let trait = trait {
                return "Welcome! Your \(trait.displayName) insights await"
            } else {
                return "Your personality insights are ready!"
            }
        case .openRequirements:
            return "Keep building those habits!"
        case .checkAnalysis:
            return "Checking your latest patterns..."
        case .directNavigation:
            return "Your personality insights"
        }
    }
    
    private var subtitle: String {
        switch action {
        case .openAnalysis:
            return "Discover what your habits reveal about you"
        case .openRequirements:
            return "You're on track to unlock personality insights"
        case .checkAnalysis:
            return "Analyzing your recent habit data"
        case .directNavigation:
            return "Discover what your habits reveal about you"
        }
    }
}

// MARK: - PersonalityTrait Extensions

private extension PersonalityTrait {
    var displayEmoji: String {
        switch self {
        case .openness: return "🎨"
        case .conscientiousness: return "🎯"
        case .extraversion: return "🌟"
        case .agreeableness: return "💝"
        case .neuroticism: return "🧘"
        }
    }
    
    var systemIconName: String {
        switch self {
        case .openness: return "paintpalette"
        case .conscientiousness: return "target"
        case .extraversion: return "person.2"
        case .agreeableness: return "heart"
        case .neuroticism: return "figure.mind.and.body"
        }
    }
}