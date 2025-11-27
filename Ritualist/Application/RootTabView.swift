import SwiftUI
import FactoryKit
import RitualistCore

// swiftlint:disable:next type_body_length
public struct RootTabView: View {
    @Injected(\.rootTabViewModel) var viewModel
    @Injected(\.settingsViewModel) var settingsViewModel
    @Injected(\.loadHabitsData) var loadHabitsData
    @Injected(\.checkHabitCreationLimit) var checkHabitCreationLimit
    @Injected(\.debugLogger) var logger
    @State private var showOnboarding = false
    @State private var isCheckingOnboarding = true
    @State private var showingPersonalityAnalysis = false
    @State private var showingPostOnboardingAssistant = false
    @State private var existingHabits: [Habit] = []
    @State private var migrationService = MigrationStatusService.shared
    @State private var pendingPersonalitySheetAfterTabSwitch = false
    @State private var showSyncToast = false

    // Quick Actions state
    @State private var quickActionCoordinator = QuickActionCoordinator.shared
    @State private var showingQuickActionAddHabit = false
    @State private var showingQuickActionHabitsAssistant = false

    /// UserDefaults key for tracking if we've shown the first iCloud sync toast
    private static let hasShownFirstSyncToastKey = "hasShownFirstiCloudSyncToast"

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

                        Tab(Strings.Navigation.stats, systemImage: "chart.bar.fill", value: Pages.stats) {
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
                .overlay(alignment: .top) {
                    if showSyncToast {
                        ICloudSyncToast(onDismiss: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showSyncToast = false
                            }
                        })
                        .padding(.top, 50)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                    // Show one-time toast when iCloud syncs data for the first time
                    handleFirstiCloudSync()
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
                isFirstVisit: true, // Show enhanced intro on first visit post-onboarding
                onShowPaywall: nil
            )
            .onDisappear {
                Task {
                    // Refresh habits after assistant dismissal
                    await loadCurrentHabits()
                    // Check for iCloud sync toast now that all sheets are dismissed
                    handleFirstiCloudSync()
                }
            }
        }
        .onChange(of: vm.personalityDeepLinkCoordinator.shouldShowPersonalityAnalysis) { oldValue, shouldShow in
            if shouldShow {
                logger.logPersonalitySheet(
                    state: "shouldShow triggered",
                    shouldSwitchTab: vm.personalityDeepLinkCoordinator.shouldSwitchTab,
                    currentTab: "\(vm.navigationService.selectedTab)",
                    metadata: ["oldValue": oldValue, "shouldShow": shouldShow]
                )

                if vm.personalityDeepLinkCoordinator.shouldSwitchTab {
                    // Navigate to overview tab first (for notifications)
                    logger.logPersonalitySheet(
                        state: "Navigating to overview tab",
                        shouldSwitchTab: true,
                        currentTab: "\(vm.navigationService.selectedTab)"
                    )

                    pendingPersonalitySheetAfterTabSwitch = true
                    vm.navigationService.selectedTab = .overview

                    logger.logPersonalitySheet(
                        state: "selectedTab assigned",
                        currentTab: "\(vm.navigationService.selectedTab)"
                    )
                    // Sheet will show via onChange(of: selectedTab) below
                } else {
                    // Show directly without tab navigation (for direct calls)
                    logger.logPersonalitySheet(
                        state: "Showing sheet directly (no tab navigation)",
                        shouldSwitchTab: false
                    )

                    showingPersonalityAnalysis = true
                    // Reset coordinator state immediately after triggering
                    vm.personalityDeepLinkCoordinator.resetAnalysisState()
                }
            }
        }
        .onChange(of: vm.navigationService.selectedTab) { oldTab, newTab in
            logger.logNavigation(
                event: "Tab changed",
                from: "\(oldTab)",
                to: "\(newTab)",
                metadata: ["pendingPersonalitySheet": pendingPersonalitySheetAfterTabSwitch]
            )

            // When tab switches and we have a pending personality sheet, show it
            if pendingPersonalitySheetAfterTabSwitch && newTab == .overview {
                logger.logPersonalitySheet(
                    state: "Tab switched to overview, showing sheet",
                    currentTab: "\(newTab)"
                )

                pendingPersonalitySheetAfterTabSwitch = false
                showingPersonalityAnalysis = true
                vm.personalityDeepLinkCoordinator.resetAnalysisState()
            }
        }
        .sheet(isPresented: $showingPersonalityAnalysis) {
            logger.logPersonalitySheet(state: "Sheet is being presented")

            return PersonalityAnalysisDeepLinkSheet(
                action: vm.personalityDeepLinkCoordinator.pendingNotificationAction
            ) {
                logger.logPersonalitySheet(state: "Sheet dismissed by user")

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
        // MARK: - Quick Actions Handling
        .onAppear {
            logger.log(
                "RootTabView onAppear - checking for pending Quick Action",
                level: .info,
                category: .ui,
                metadata: ["pendingAction": String(describing: quickActionCoordinator.pendingAction)]
            )
            // Process any pending Quick Action from cold start
            // Small delay to ensure UI is ready
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                logger.log("RootTabView: Processing pending Quick Action after delay", level: .debug, category: .ui)
                quickActionCoordinator.processPendingAction()
            }
        }
        .onChange(of: quickActionCoordinator.shouldShowAddHabit) { oldValue, shouldShow in
            logger.log(
                "Quick Action onChange: shouldShowAddHabit",
                level: .info,
                category: .ui,
                metadata: ["oldValue": oldValue, "newValue": shouldShow]
            )
            if shouldShow {
                logger.log("Quick Action: Add Habit triggered - switching to habits tab", level: .info, category: .ui)

                // Dismiss any other open quick action sheet first
                let needsDismissal = showingQuickActionHabitsAssistant
                if needsDismissal {
                    showingQuickActionHabitsAssistant = false
                }

                vm.navigationService.selectedTab = .habits
                // Delay to allow tab switch and sheet dismissal if needed
                Task {
                    try? await Task.sleep(for: .milliseconds(needsDismissal ? 400 : 100))
                    logger.log("Quick Action: Showing Add Habit sheet", level: .info, category: .ui)
                    showingQuickActionAddHabit = true
                    quickActionCoordinator.resetTriggers()
                }
            }
        }
        .onChange(of: quickActionCoordinator.shouldShowHabitsAssistant) { oldValue, shouldShow in
            logger.log(
                "Quick Action onChange: shouldShowHabitsAssistant",
                level: .info,
                category: .ui,
                metadata: ["oldValue": oldValue, "newValue": shouldShow]
            )
            if shouldShow {
                logger.log("Quick Action: Habits Assistant triggered - switching to habits tab", level: .info, category: .ui)

                // Dismiss any other open quick action sheet first
                let needsDismissal = showingQuickActionAddHabit
                if needsDismissal {
                    showingQuickActionAddHabit = false
                }

                vm.navigationService.selectedTab = .habits
                // Delay to allow tab switch and sheet dismissal if needed
                Task {
                    try? await Task.sleep(for: .milliseconds(needsDismissal ? 400 : 100))
                    logger.log("Quick Action: Showing Habits Assistant sheet", level: .info, category: .ui)
                    showingQuickActionHabitsAssistant = true
                    quickActionCoordinator.resetTriggers()
                }
            }
        }
        .onChange(of: quickActionCoordinator.shouldNavigateToStats) { oldValue, shouldShow in
            logger.log(
                "Quick Action onChange: shouldNavigateToStats",
                level: .info,
                category: .ui,
                metadata: ["oldValue": oldValue, "newValue": shouldShow]
            )
            if shouldShow {
                logger.log("Quick Action: Stats triggered - switching to stats tab", level: .info, category: .ui)

                // Dismiss any open quick action sheets first
                let needsDismissal = showingQuickActionAddHabit || showingQuickActionHabitsAssistant
                if showingQuickActionAddHabit {
                    showingQuickActionAddHabit = false
                }
                if showingQuickActionHabitsAssistant {
                    showingQuickActionHabitsAssistant = false
                }

                Task {
                    if needsDismissal {
                        try? await Task.sleep(for: .milliseconds(400))
                    }
                    vm.navigationService.selectedTab = .stats
                    quickActionCoordinator.resetTriggers()
                }
            }
        }
        .sheet(isPresented: $showingQuickActionAddHabit) {
            let detailVM = HabitDetailViewModel(habit: nil)
            HabitDetailView(vm: detailVM)
                .onDisappear {
                    Task {
                        await loadCurrentHabits()
                    }
                }
        }
        .sheet(isPresented: $showingQuickActionHabitsAssistant) {
            HabitsAssistantSheet(
                existingHabits: existingHabits,
                isFirstVisit: false,
                onShowPaywall: nil
            )
            .onDisappear {
                Task {
                    await loadCurrentHabits()
                }
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

        // NOTE: Don't call handleFirstiCloudSync() here - the assistant sheet will open next
        // and the toast would appear behind it. Instead, we trigger the toast when the
        // assistant sheet dismisses (see onDisappear handler).

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
            Container.shared.debugLogger().log("Failed to load habits for post-onboarding check: \(error)", level: .error, category: .ui)
            existingHabits = []
        }
    }

    /// Handle first iCloud sync - show toast only once per device lifetime
    /// Uses retry logic because data may not be available immediately when notification fires
    private func handleFirstiCloudSync(retryCount: Int = 0) {
        // Check if we've already shown this toast (check BEFORE spawning async work)
        guard !UserDefaults.standard.bool(forKey: Self.hasShownFirstSyncToastKey) else {
            return
        }

        // Don't show toast during onboarding or while assistant sheet is open
        // It would appear behind the fullScreenCover/sheet
        guard !showOnboarding && !isCheckingOnboarding && !showingPostOnboardingAssistant else {
            logger.log(
                "☁️ iCloud sync detected but modal active - deferring toast",
                level: .debug,
                category: .system,
                metadata: [
                    "showOnboarding": showOnboarding,
                    "isCheckingOnboarding": isCheckingOnboarding,
                    "showingAssistant": showingPostOnboardingAssistant
                ]
            )
            return
        }

        // Load habits to check if data actually synced
        Task {
            // Double-check flag inside Task to prevent race conditions from multiple notifications
            guard !UserDefaults.standard.bool(forKey: Self.hasShownFirstSyncToastKey) else {
                return
            }

            await loadCurrentHabits()

            // Only show toast if we actually have habits from iCloud
            guard !existingHabits.isEmpty else {
                // Retry up to 3 times with increasing delays (1s, 2s, 3s)
                // CloudKit data may take a moment to fully sync and become available
                if retryCount < 3 {
                    logger.log(
                        "☁️ iCloud sync detected but no habits found yet - will retry",
                        level: .debug,
                        category: .system,
                        metadata: ["retry_count": retryCount + 1]
                    )
                    try? await Task.sleep(for: .seconds(Double(retryCount + 1)))
                    handleFirstiCloudSync(retryCount: retryCount + 1)
                } else {
                    logger.log(
                        "☁️ iCloud sync detected but no habits found after retries - skipping toast",
                        level: .debug,
                        category: .system
                    )
                }
                return
            }

            // Mark as shown IMMEDIATELY to prevent race conditions
            UserDefaults.standard.set(true, forKey: Self.hasShownFirstSyncToastKey)

            logger.log(
                "☁️ First iCloud sync with data - showing welcome toast",
                level: .info,
                category: .system,
                metadata: ["habits_count": existingHabits.count]
            )

            // Show the toast with animation
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showSyncToast = true
                }

                // Auto-dismiss after 4 seconds
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSyncToast = false
                    }
                }
            }
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
