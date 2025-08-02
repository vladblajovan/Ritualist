//
//  RitualistApp.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import SwiftUI
import SwiftData

@main struct RitualistApp: App {
    @State private var container: DefaultAppContainer?
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let container = container {
                    RootAppView(container: container)
                } else {
                    VStack {
                        ProgressView()
                        Text("Loading...")
                    }
                }
            }
            .task {
                if container == nil {
                    container = await DefaultAppContainer.bootstrap()
                }
            }
        }
    }
}

// Separate view to properly observe AppearanceManager changes
struct RootAppView: View {
    let container: DefaultAppContainer
    @State private var colorScheme: ColorScheme?
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingFlowView {
                    // Complete onboarding - update state to show main app
                    showOnboarding = false
                }
                .environment(\.appContainer, container)
            } else {
                RootTabView()
                    .environment(\.appContainer, container)
            }
        }
        .preferredColorScheme(colorScheme)
        .task {
            do {
                let profile = try await container.profileRepository.loadProfile()
                await MainActor.run {
                    container.appearanceManager.updateFromProfile(profile)
                    colorScheme = container.appearanceManager.colorScheme
                }
            } catch {
                print("Failed to load profile: \(error)")
            }
            
            // Check if user has completed onboarding
            do {
                let onboardingState = try await container.onboardingRepository.getOnboardingState()
                await MainActor.run {
                    showOnboarding = !onboardingState.isCompleted
                }
            } catch {
                // If no onboarding state exists, show onboarding
                await MainActor.run {
                    showOnboarding = true
                }
            }
        }
        .onChange(of: container.appearanceManager.currentAppearance) { _, _ in
            colorScheme = container.appearanceManager.colorScheme
        }
    }
}
