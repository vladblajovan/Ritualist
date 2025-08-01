import SwiftUI

struct AuthenticationFlowView: View {
    @Environment(\.appContainer) private var container
    
    var body: some View {
        // Cast to specific types since @ObservedObject can't work with existentials
        Group {
            if let userSession = container.userSession as? UserSession {
                ReactiveAuthFlow(userSession: userSession, container: container)
            } else if let userSession = container.userSession as? NoOpUserSession {
                ReactiveNoOpAuthFlow(userSession: userSession, container: container)
            } else {
                // This should never happen, but provide fallback
                Text("Authentication system unavailable")
                    .foregroundColor(.red)
            }
        }
    }
}

private struct ReactiveAuthFlow: View {
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

private struct ReactiveNoOpAuthFlow: View {
    @ObservedObject var userSession: NoOpUserSession
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

#Preview("Not Authenticated") {
    AuthenticationFlowView()
}

#Preview("Authenticated") {
    let container = DefaultAppContainer.createMinimal()
    // Simulate authenticated state
    return AuthenticationFlowView()
        .environment(\.appContainer, container)
}
