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
                    AuthenticationFlowView()
                        .environment(\.appContainer, container)
                        .preferredColorScheme(container.appearanceManager.colorScheme)
                        .task {
                            do {
                                let profile = try await container.profileRepository.loadProfile()
                                await MainActor.run {
                                    container.appearanceManager.updateFromProfile(profile)
                                }
                            } catch {
                                print("Failed to load profile: \(error)")
                            }
                        }
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
