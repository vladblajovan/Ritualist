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
    
    var body: some View {
        AuthenticationFlowView()
            .environment(\.appContainer, container)
            .environment(\.refreshTrigger, container.refreshTrigger)
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
            }
            .onReceive(container.appearanceManager.$currentAppearance) { _ in
                colorScheme = container.appearanceManager.colorScheme
            }
    }
}
