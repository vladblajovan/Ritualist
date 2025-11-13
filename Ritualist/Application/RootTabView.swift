import SwiftUI
import FactoryKit
import RitualistCore

public struct RootTabView: View {
    @Injected(\.rootTabViewModel) var viewModel
    @Injected(\.settingsViewModel) var settingsViewModel
    @Injected(\.loadHabitsData) var loadHabitsData
    @Injected(\.checkHabitCreationLimit) var checkHabitCreationLimit
    @State private var showOnboarding = false
    @State private var isCheckingOnboarding = true
    @State private var showingPersonalityAnalysis = false
    @State private var showingPostOnboardingAssistant = false
    @State private var existingHabits: [Habit] = []
    @State private var migrationService = MigrationStatusService.shared

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
                .tabBarMinimizeOnScroll()
                .preferredColorScheme(vm.appearanceManager.colorScheme)
                #if DEBUG
                .overlay(alignment: .topTrailing) {
                    if settingsViewModel.showFPSOverlay {
                        FPSOverlay()
                    }
                }
                #endif
                .overlay {
                    if migrationService.isMigrating {
                        MigrationLoadingView(details: migrationService.migrationDetails)
                    }
                }
            }
        }
        .task {
            await checkOnboardingStatus()
            await viewModel.loadUserAppearancePreference()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(onComplete: {
                showOnboarding = false
                Task {
                    await handlePostOnboarding()
                }
            })
        }
        .sheet(isPresented: $showingPostOnboardingAssistant) {
            HabitsAssistantSheet(
                existingHabits: existingHabits,
                onShowPaywall: nil
            )
            .onDisappear {
                Task {
                    // Refresh habits after assistant dismissal
                    await loadCurrentHabits()
                }
            }
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

    /// Handle post-onboarding flow - open assistant if user can add more habits
    private func handlePostOnboarding() async {
        await loadCurrentHabits()

        let currentHabitCount = existingHabits.count
        let canAddMoreHabits = checkHabitCreationLimit.execute(currentCount: currentHabitCount)

        // Only open assistant if user hasn't reached the limit
        // For premium users or users with < 5 habits
        if canAddMoreHabits {
            // Small delay to ensure onboarding dismissal animation completes
            try? await Task.sleep(for: .milliseconds(500))
            showingPostOnboardingAssistant = true
        }
        // If at limit (5+ habits for free users), don't open assistant
        // User will land on Overview tab naturally
    }

    /// Load current habits to check count
    private func loadCurrentHabits() async {
        do {
            let habitsData = try await loadHabitsData.execute()
            existingHabits = habitsData.habits
        } catch {
            print("Failed to load habits for post-onboarding check: \(error)")
            existingHabits = []
        }
    }
}

// MARK: - iOS 26+ API Compatibility Extensions

extension View {
    /// Applies tab bar minimize behavior on scroll when available (iOS 26.0+)
    ///
    /// This modifier gracefully degrades on:
    /// - Older iOS versions (< 26.0): No tab bar minimize behavior
    /// - Older SDK/compiler (< Swift 6.2): API not available at compile time
    ///
    /// **Pattern for new iOS 26+ APIs:**
    /// ```swift
    /// extension View {
    ///     func yourNewAPI() -> some View {
    ///         #if compiler(>=6.2)              // Compile-time: Does SDK know this API?
    ///         if #available(iOS 26.0, *) {     // Runtime: Does device support it?
    ///             return self.newAPIMethod()
    ///         } else {
    ///             return self
    ///         }
    ///         #else
    ///         return self
    ///         #endif
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: View with minimize behavior on iOS 26.0+, unmodified view otherwise
    @ViewBuilder
    func tabBarMinimizeOnScroll() -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#Preview {
    RootTabView()
}
