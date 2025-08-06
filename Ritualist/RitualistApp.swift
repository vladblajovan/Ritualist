//
//  RitualistApp.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import SwiftUI
import SwiftData
import FactoryKit

@main struct RitualistApp: App {
    var body: some Scene {
        WindowGroup {
            RootAppView()
                .task {
                    await setupNotifications()
                }
        }
    }
    
    private func setupNotifications() async {
        // Setup notification categories on app launch
        let notificationService = Container.shared.notificationService()
        await notificationService.setupNotificationCategories()
    }
}

// Separate view to properly observe AppearanceManager changes
struct RootAppView: View {
    var body: some View {
        RootTabView()
            // RootTabView now handles onboarding through Factory injection
    }
}
