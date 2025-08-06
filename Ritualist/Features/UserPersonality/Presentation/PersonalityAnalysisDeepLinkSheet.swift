//
//  PersonalityAnalysisDeepLinkSheet.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import SwiftUI
import FactoryKit

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
            if showWelcomeMessage, let action = action {
                WelcomeMessageView(action: action)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Use PersonalityInsightsView without wrapping in another NavigationView
            PersonalityInsightsView(viewModel: viewModel)
        }
        .onAppear {
            handleNotificationAction()
            
            // Show welcome message briefly
            withAnimation(.easeInOut(duration: 0.5)) {
                showWelcomeMessage = true
            }
            
            // Hide welcome message after 3 seconds
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showWelcomeMessage = false
                    }
                }
            }
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
            }
        }
    }
    
    private func handleDismiss() {
        onDismiss()
        dismiss()
    }
}

// MARK: - Welcome Message View

private struct WelcomeMessageView: View {
    let action: PersonalityDeepLinkCoordinator.PersonalityNotificationAction
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch action {
        case .openAnalysis(let trait, _):
            return trait?.displayEmoji ?? "✨"
        case .openRequirements:
            return "🌱"
        case .checkAnalysis:
            return "🔍"
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
}