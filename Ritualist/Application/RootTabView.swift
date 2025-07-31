import SwiftUI

public enum RootTab: Hashable {
    case overview, habits, settings
}

public struct RootTabView: View {
    @Environment(\.appContainer) private var di
    @State private var selectedTab: RootTab = .overview
    @State private var showOnboarding = false
    @State private var isCheckingOnboarding = true
    @State private var overviewKey = 0

    public init() {}

    public var body: some View {
        Group {
            if isCheckingOnboarding {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        OverviewRoot()
                            .id(overviewKey)
                    }
                    .tabItem { Label(Strings.Navigation.overview, systemImage: "calendar") }
                    .tag(RootTab.overview)

                    NavigationStack {
                        HabitsRoot()
                    }
                    .tabItem { Label(Strings.Navigation.habits, systemImage: "checklist") }
                    .tag(RootTab.habits)

                    NavigationStack {
                        SettingsRoot()
                    }
                    .tabItem { Label(Strings.Navigation.settings, systemImage: "gear") }
                    .tag(RootTab.settings)
                }
            }
        }
        .task {
            await checkOnboardingStatus()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView()
        }
        .onChange(of: showOnboarding) { _, isShowing in
            if !isShowing {
                // Refresh Overview when onboarding completes
                overviewKey += 1
            }
        }
    }
    
    private func checkOnboardingStatus() async {
        do {
            let getOnboardingState = GetOnboardingState(repo: di.onboardingRepository)
            let state = try await getOnboardingState.execute()
            await MainActor.run {
                showOnboarding = !state.isCompleted
                isCheckingOnboarding = false
            }
        } catch {
            print("Failed to check onboarding status: \(error)")
            await MainActor.run {
                showOnboarding = true // Default to showing onboarding on error
                isCheckingOnboarding = false
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(\.appContainer, DefaultAppContainer.createMinimal())
}
