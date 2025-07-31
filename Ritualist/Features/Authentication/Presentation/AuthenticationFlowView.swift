import SwiftUI

struct AuthenticationFlowView: View {
    @Environment(\.appContainer) private var container
    
    var body: some View {
        Group {
            // Check if we have a UserSession (which is ObservableObject)
            if let userSession = container.userSession as? UserSession {
                AuthenticatedFlowView(userSession: userSession, container: container)
            } else {
                // Fallback for other UserSession types
                BasicAuthFlow(container: container)
            }
        }
    }
}

private struct AuthenticatedFlowView: View {
    @ObservedObject var userSession: UserSession
    let container: AppContainer
    
    var body: some View {
        Group {
            if userSession.isAuthenticated {
                // User is logged in - show main app
                RootTabView()
                    .environment(\.appContainer, container)
            } else {
                // User not logged in - show login screen
                LoginView(userSession: userSession)
            }
        }
    }
}

private struct BasicAuthFlow: View {
    let container: AppContainer
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                // User is logged in - show main app
                RootTabView()
                    .environment(\.appContainer, container)
            } else {
                // User not logged in - show login screen
                LoginView(userSession: container.userSession)
            }
        }
        .onAppear {
            isAuthenticated = container.userSession.isAuthenticated
        }
        .task {
            // Periodically check authentication state for non-ObservableObject implementations
            while true {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                let newState = container.userSession.isAuthenticated
                if isAuthenticated != newState {
                    await MainActor.run {
                        isAuthenticated = newState
                    }
                }
            }
        }
    }
}

#Preview("Not Authenticated") {
    AuthenticationFlowView()
}

#Preview("Authenticated") {
    let container = DefaultAppContainer.createMinimal()
    // Simulate authenticated state
    return AuthenticationFlowView()
        .environment(\.appContainer, container)
}