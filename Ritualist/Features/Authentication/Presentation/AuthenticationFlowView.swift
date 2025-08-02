import SwiftUI

struct AuthenticationFlowView: View {
    @Environment(\.appContainer) private var container
    
    var body: some View {
        // This view is no longer used - authentication has been removed
        // Keeping for compatibility, but should be cleaned up
        Text("Authentication flow no longer needed")
            .foregroundColor(.red)
    }
}

private struct ReactiveAuthFlow: View {
    @Bindable var userSession: UserSession
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
    @Bindable var userSession: NoOpUserSession
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
