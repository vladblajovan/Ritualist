import SwiftUI
import FactoryKit
import RitualistCore

public struct RootTabView: View {
    @Injected(\.rootTabViewModel) var viewModel
    @State private var showOnboarding = false
    @State private var isCheckingOnboarding = true
    @State private var showingPersonalityAnalysis = false

    public init() {}

    @ViewBuilder
    public var body: some View {
        @Bindable var vm = viewModel
        
        Group {
            if isCheckingOnboarding {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            } else {
                TabView(selection: $vm.navigationService.selectedTab) {
                    Tab(Strings.Navigation.overview, systemImage: "calendar", value: Pages.overview) {
                            NavigationStack {
                                OverviewRoot()
                            }
                        }

                        Tab(Strings.Navigation.habits, systemImage: "checklist", value: Pages.habits) {
                            NavigationStack {
                                HabitsRoot()
                            }
                        }

                        Tab(Strings.Navigation.dashboard, systemImage: "chart.bar.fill", value: Pages.dashboard) {
                            NavigationStack {
                                DashboardRoot()
                            }
                        }

                        Tab(Strings.Navigation.settings, systemImage: "gear", value: Pages.settings) {
                            NavigationStack {
                                SettingsRoot()
                            }
                        }
                }
                .modifier(TabBarMinimizeModifier())
                .preferredColorScheme(vm.appearanceManager.colorScheme)
            }
        }
        .task {
            await checkOnboardingStatus()
            await viewModel.loadUserAppearancePreference()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(onComplete: {
                showOnboarding = false
            })
        }
        .onChange(of: vm.personalityDeepLinkCoordinator.shouldShowPersonalityAnalysis) { oldValue, shouldShow in
            if shouldShow {
                if vm.personalityDeepLinkCoordinator.shouldNavigateToSettings {
                    // Navigate to settings tab first (for notifications)
                    vm.navigationService.selectedTab = .settings
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        showingPersonalityAnalysis = true
                        // Reset coordinator state immediately after triggering
                        vm.personalityDeepLinkCoordinator.resetAnalysisState()
                    }
                } else {
                    // Show directly without tab navigation (for direct calls)
                    showingPersonalityAnalysis = true
                    // Reset coordinator state immediately after triggering
                    vm.personalityDeepLinkCoordinator.resetAnalysisState()
                }
            }
        }
        .sheet(isPresented: $showingPersonalityAnalysis) {
            PersonalityAnalysisDeepLinkSheet(
                action: vm.personalityDeepLinkCoordinator.pendingNotificationAction
            ) {
                // Only clear the notification action on dismissal
                vm.personalityDeepLinkCoordinator.pendingNotificationAction = nil
                showingPersonalityAnalysis = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check for pending navigation when app enters foreground
            if vm.personalityDeepLinkCoordinator.processPendingNavigation() {
                // Already handled by onChange above
            }
        }
    }
    
    private func checkOnboardingStatus() async {
        await viewModel.checkOnboardingStatus()
        showOnboarding = viewModel.showOnboarding
        isCheckingOnboarding = viewModel.isCheckingOnboarding
    }
}

private struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

#Preview {
    RootTabView()
}
