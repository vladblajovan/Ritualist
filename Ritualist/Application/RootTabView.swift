import SwiftUI
import FactoryKit
import RitualistCore

public struct RootTabView: View {
    @Injected(\.rootTabViewModel) var viewModel
    @Injected(\.appearanceManager) var appearanceManager
    @InjectedObject(\.navigationService) var navigationService
    @InjectedObject(\.personalityDeepLinkCoordinator) var deepLinkCoordinator
    @State private var showOnboarding = false
    @State private var isCheckingOnboarding = true
    @State private var overviewKey = 0
    @State private var showingPersonalityAnalysis = false
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
                TabView(selection: $navigationService.selectedTab) {
                    Tab(Strings.Navigation.overview, systemImage: "calendar", value: RitualistPages.overview) {
                            NavigationStack {
                                OverviewV2Root()
                                    .id(overviewKey)
                            }
                        }

                        Tab(Strings.Navigation.habits, systemImage: "checklist", value: RitualistPages.habits) {
                            NavigationStack {
                                HabitsRoot()
                            }
                        }

                        Tab(Strings.Navigation.dashboard, systemImage: "chart.bar.fill", value: RitualistPages.dashboard) {
                            NavigationStack {
                                DashboardRoot()
                            }
                        }

                        Tab(Strings.Navigation.settings, systemImage: "gear", value: RitualistPages.settings) {
                            NavigationStack {
                                SettingsRoot()
                            }
                        }
                }
                .modifier(TabBarMinimizeModifier())
                .preferredColorScheme(appearanceManager.colorScheme)
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
        .onChange(of: showOnboarding) { _, isShowing in
            if !isShowing {
                overviewKey += 1
            }
        }
        .onChange(of: deepLinkCoordinator.shouldShowPersonalityAnalysis) { oldValue, shouldShow in
            if shouldShow {
                if deepLinkCoordinator.shouldNavigateToSettings {
                    // Navigate to settings tab first (for notifications)
                    navigationService.selectedTab = .settings
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        showingPersonalityAnalysis = true
                        // Reset coordinator state immediately after triggering
                        deepLinkCoordinator.resetAnalysisState()
                    }
                } else {
                    // Show directly without tab navigation (for direct calls)
                    showingPersonalityAnalysis = true
                    // Reset coordinator state immediately after triggering
                    deepLinkCoordinator.resetAnalysisState()
                }
            }
        }
        .sheet(isPresented: $showingPersonalityAnalysis) {
            PersonalityAnalysisDeepLinkSheet(
                action: deepLinkCoordinator.pendingNotificationAction
            ) {
                // Only clear the notification action on dismissal
                deepLinkCoordinator.pendingNotificationAction = nil
                showingPersonalityAnalysis = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check for pending navigation when app enters foreground
            if deepLinkCoordinator.processPendingNavigation() {
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
