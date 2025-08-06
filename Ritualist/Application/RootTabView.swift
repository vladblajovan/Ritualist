import SwiftUI
import FactoryKit

public enum RootTab: Hashable {
    case overview, habits, settings
}

public struct RootTabView: View {
    @Injected(\.getOnboardingState) var getOnboardingState
    @State private var selectedTab: RootTab = .overview
    @State private var showOnboarding = false
    @State private var isCheckingOnboarding = true
    @State private var overviewKey = 0
    @Namespace private var glassUnionNamespace

    public init() {}

    @ViewBuilder
    public var body: some View {
        Group {
            if isCheckingOnboarding {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            } else {
                TabView(selection: $selectedTab) {
                    Tab(Strings.Navigation.overview, systemImage: "calendar", value: RootTab.overview) {
                            NavigationStack {
                                OverviewRoot()
                                    .id(overviewKey)
                            }
                        }

                        Tab(Strings.Navigation.habits, systemImage: "checklist", value: RootTab.habits) {
                            NavigationStack {
                                HabitsRoot()
                            }
                        }

                        Tab(Strings.Navigation.settings, systemImage: "gear", value: RootTab.settings) {
                            NavigationStack {
                                SettingsRoot()
                            }
                        }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
            }
        }
        .task {
            await checkOnboardingStatus()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(onComplete: {
                showOnboarding = false
            })
        }
        .onChange(of: showOnboarding) { _, isShowing in
            if !isShowing {
                overviewKey += 1
            }
        }
    }
    
    private func checkOnboardingStatus() async {
        do {
            let state = try await getOnboardingState.execute()
            await MainActor.run {
                showOnboarding = !state.isCompleted
                isCheckingOnboarding = false
            }
        } catch {
            print("Failed to check onboarding status: \(error)")
            await MainActor.run {
                showOnboarding = true
                isCheckingOnboarding = false
            }
        }
    }
}

#Preview {
    RootTabView()
}
