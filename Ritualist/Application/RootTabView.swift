import SwiftUI
import FactoryKit

public enum RootTab: Hashable {
    case overview, habits, dashboard, settings
}

public struct RootTabView: View {
    @Injected(\.getOnboardingState) var getOnboardingState
    @Injected(\.appearanceManager) var appearanceManager
    @Injected(\.loadProfile) var loadProfile
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
                    Tab(Strings.Navigation.overview, systemImage: "calendar", value: RootTab.overview) {
                            NavigationStack {
                                OverviewV2Root()
                                    .id(overviewKey)
                            }
                        }

                        Tab(Strings.Navigation.habits, systemImage: "checklist", value: RootTab.habits) {
                            NavigationStack {
                                HabitsRoot()
                            }
                        }

                        Tab(Strings.Navigation.dashboard, systemImage: "chart.bar.fill", value: RootTab.dashboard) {
                            NavigationStack {
                                DashboardRoot()
                            }
                        }

                        Tab(Strings.Navigation.settings, systemImage: "gear", value: RootTab.settings) {
                            NavigationStack {
                                SettingsRoot()
                            }
                        }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .preferredColorScheme(appearanceManager.colorScheme)
            }
        }
        .task {
            await checkOnboardingStatus()
            await loadUserAppearancePreference()
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
            if !shouldShow {
                // Handle dismissal
                showingPersonalityAnalysis = false
            } else if shouldShow {
                if deepLinkCoordinator.shouldNavigateToSettings {
                    // Navigate to settings tab first (for notifications)
                    navigationService.selectedTab = .settings
                    // Small delay to ensure tab switch completes
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        await MainActor.run {
                            showingPersonalityAnalysis = true
                        }
                    }
                } else {
                    // Show directly without tab navigation (for direct calls)
                    showingPersonalityAnalysis = true
                }
            }
        }
        .sheet(isPresented: $showingPersonalityAnalysis) {
            PersonalityAnalysisDeepLinkSheet(
                action: deepLinkCoordinator.pendingNotificationAction
            ) {
                deepLinkCoordinator.clearPendingNavigation()
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
    
    private func loadUserAppearancePreference() async {
        do {
            let profile = try await loadProfile.execute()
            await MainActor.run {
                appearanceManager.updateFromProfile(profile)
            }
        } catch {
            print("Failed to load user appearance preference: \(error)")
            // Continue with default appearance (follow system)
        }
    }
}

#Preview {
    RootTabView()
}
