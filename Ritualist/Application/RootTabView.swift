import SwiftUI
import FactoryKit
import RitualistCore
import CloudKit

public struct RootTabView: View {
    @Injected(\.rootTabViewModel) var viewModel
    @Injected(\.settingsViewModel) var settingsViewModel
    @Injected(\.loadHabitsData) var loadHabitsData
    @Injected(\.loadProfile) var loadProfile
    @Injected(\.checkHabitCreationLimit) var checkHabitCreationLimit
    @Injected(\.debugLogger) var logger
    @Injected(\.userDefaultsService) var userDefaults
    @State var showOnboarding = false
    @State var isCheckingOnboarding = true
    @State var showingPersonalityAnalysis = false
    @State var pendingPersonalitySheetReshow = false
    @State var showingPostOnboardingAssistant = false
    @State var existingHabits: [Habit] = []
    @State var migrationService = MigrationStatusService.shared
    @State var pendingPersonalitySheetAfterTabSwitch = false

    // Quick Actions state (internal for extension access)
    @Injected(\.quickActionCoordinator) var quickActionCoordinator
    @State var showingQuickActionAddHabit = false
    @State var pendingQuickActionAddHabitReshow = false
    @State var showingQuickActionHabitsAssistant = false
    @State var pendingQuickActionHabitsAssistantReshow = false

    public init() {}

    @ViewBuilder
    public var body: some View {
        @Bindable var vm = viewModel

        Group {
            if isCheckingOnboarding || migrationService.isMigrating {
                AppLaunchView(migrationDetails: migrationService.migrationDetails)
            } else {
                mainTabView
            }
        }
        .task {
            await checkOnboardingStatus()
            await viewModel.loadUserAppearancePreference()
        }
        .onChange(of: isCheckingOnboarding) { _, newValue in
            if !newValue && viewModel.pendingReturningUserWelcome {
                viewModel.showSyncingDataToast()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: handleOnboardingDismiss) {
            OnboardingFlowView(onComplete: { showOnboarding = false })
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { viewModel.showReturningUserWelcome },
                set: { if !$0 { viewModel.dismissReturningUserWelcome() } }
            ),
            onDismiss: { handleFirstiCloudSync() },
            content: returningUserWelcomeContent
        )
        .habitsAssistantSheet(
            isPresented: $showingPostOnboardingAssistant,
            existingHabits: existingHabits,
            isFirstVisit: true,
            onDataRefreshNeeded: {
                await loadCurrentHabits()
                handleFirstiCloudSync()
            }
        )
        .onChange(of: vm.personalityDeepLinkCoordinator.shouldShowPersonalityAnalysis) { oldValue, shouldShow in
            handlePersonalityDeepLink(oldValue: oldValue, shouldShow: shouldShow)
        }
        .onChange(of: vm.navigationService.selectedTab) { oldTab, newTab in
            handleTabChange(oldTab: oldTab, newTab: newTab)
        }
        .sheet(isPresented: $showingPersonalityAnalysis, onDismiss: handlePersonalitySheetDismiss) {
            personalityAnalysisSheetContent
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            _ = vm.personalityDeepLinkCoordinator.processPendingNavigation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
            handleFirstiCloudSync()
            handleReturningUserWelcome()
        }
        // Quick Actions
        .onAppear(perform: handleQuickActionOnAppear)
        .onChange(of: quickActionCoordinator.pendingAction) { oldValue, newValue in
            if newValue != nil && oldValue == nil {
                logger.log("RootTabView: Detected new pending Quick Action (warm start)", level: .info, category: .ui, metadata: ["action": String(describing: newValue)])
                quickActionCoordinator.processPendingAction()
            }
        }
        .onChange(of: quickActionCoordinator.shouldShowAddHabit) { _, shouldShow in
            handleShouldShowAddHabit(shouldShow)
        }
        .onChange(of: quickActionCoordinator.shouldShowHabitsAssistant) { _, shouldShow in
            handleShouldShowHabitsAssistant(shouldShow)
        }
        .onChange(of: quickActionCoordinator.shouldNavigateToStats) { _, shouldShow in
            handleShouldNavigateToStats(shouldShow)
        }
        .sheet(isPresented: $showingQuickActionAddHabit, onDismiss: handleQuickActionAddHabitDismiss) {
            quickActionAddHabitSheet()
        }
        .habitsAssistantSheet(
            isPresented: $showingQuickActionHabitsAssistant,
            existingHabits: existingHabits,
            isFirstVisit: false,
            onDataRefreshNeeded: { await handleQuickActionHabitsAssistantRefresh() }
        )
        .overlay(alignment: .top) { toastOverlay }
        .animation(SpringAnimation.interactive, value: viewModel.toastItems.map(\.id))
    }

    // MARK: - Main Tab View

    @ViewBuilder
    private var mainTabView: some View {
        @Bindable var vm = viewModel
        TabView(selection: $vm.navigationService.selectedTab) {
            Tab(Strings.Navigation.overview, systemImage: "calendar", value: Pages.overview) {
                NavigationStack { OverviewRoot() }
                    .accessibilityIdentifier(AccessibilityID.Overview.root)
            }
            Tab(Strings.Navigation.habits, systemImage: "checklist", value: Pages.habits) {
                NavigationStack { HabitsRoot() }
                    .accessibilityIdentifier(AccessibilityID.Habits.root)
            }
            Tab(Strings.Navigation.stats, systemImage: "chart.bar.fill", value: Pages.stats) {
                NavigationStack { StatsRoot() }
                    .accessibilityIdentifier(AccessibilityID.Stats.root)
            }
        }
        .preferredColorScheme(vm.appearanceManager.colorScheme)
    }

    // MARK: - Sheet Content Builders

    @ViewBuilder
    private func returningUserWelcomeContent() -> some View {
        if let summary = viewModel.syncedDataSummary {
            ReturningUserOnboardingView(summary: summary, onComplete: { viewModel.dismissReturningUserWelcome() })
                .onAppear { viewModel.dismissSyncingDataToast() }
        }
    }

    @ViewBuilder
    private var personalityAnalysisSheetContent: some View {
        // swiftlint:disable:next redundant_discardable_let
        let _ = logger.logPersonalitySheet(state: "Sheet is being presented")
        PersonalityAnalysisDeepLinkSheet(action: viewModel.personalityDeepLinkCoordinator.pendingNotificationAction) {
            logger.logPersonalitySheet(state: "Sheet dismissed by user")
            viewModel.personalityDeepLinkCoordinator.pendingNotificationAction = nil
            showingPersonalityAnalysis = false
        }
        .accessibilityIdentifier(AccessibilityID.PersonalityAnalysis.sheet)
    }

    @ViewBuilder
    private var toastOverlay: some View {
        VStack(spacing: 8) {
            ForEach(Array(viewModel.toastItems.enumerated()), id: \.element.id) { index, toast in
                toastView(for: toast)
                    .scaleEffect(1.0 - (Double(index) * ToastVisualHierarchy.scaleReductionPerIndex))
                    .opacity(1.0 - (Double(index) * ToastVisualHierarchy.opacityReductionPerIndex))
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Event Handlers

    private func handleOnboardingDismiss() {
        Task { @MainActor in await handlePostOnboarding() }
    }

    private func handleQuickActionOnAppear() {
        logger.log("RootTabView onAppear - checking for pending Quick Action", level: .info, category: .ui, metadata: ["pendingAction": String(describing: quickActionCoordinator.pendingAction)])
        Task { @MainActor in
            await Task.yield()
            logger.log("RootTabView: Processing pending Quick Action after yield", level: .debug, category: .ui)
            quickActionCoordinator.processPendingAction()
        }
    }

    private func handlePersonalityDeepLink(oldValue: Bool, shouldShow: Bool) {
        guard shouldShow else { return }
        logger.logPersonalitySheet(state: "shouldShow triggered", shouldSwitchTab: viewModel.personalityDeepLinkCoordinator.shouldSwitchTab, currentTab: "\(viewModel.navigationService.selectedTab)", metadata: ["oldValue": oldValue, "shouldShow": shouldShow, "sheetAlreadyOpen": showingPersonalityAnalysis])

        let presentSheet = {
            if showingPersonalityAnalysis {
                logger.logPersonalitySheet(state: "Dismissing existing sheet before re-showing")
                pendingPersonalitySheetReshow = true
                showingPersonalityAnalysis = false
            } else {
                showingPersonalityAnalysis = true
                viewModel.personalityDeepLinkCoordinator.resetAnalysisState()
            }
        }

        if viewModel.personalityDeepLinkCoordinator.shouldSwitchTab {
            logger.logPersonalitySheet(state: "Navigating to overview tab", shouldSwitchTab: true, currentTab: "\(viewModel.navigationService.selectedTab)")
            if viewModel.navigationService.selectedTab == .overview {
                logger.logPersonalitySheet(state: "Already on overview, showing sheet directly", currentTab: "\(viewModel.navigationService.selectedTab)")
                presentSheet()
            } else {
                pendingPersonalitySheetAfterTabSwitch = true
                viewModel.navigationService.selectedTab = .overview
                logger.logPersonalitySheet(state: "selectedTab assigned", currentTab: "\(viewModel.navigationService.selectedTab)")
            }
        } else {
            logger.logPersonalitySheet(state: "Showing sheet directly (no tab navigation)", shouldSwitchTab: false)
            presentSheet()
        }
    }

    private func handleTabChange(oldTab: Pages, newTab: Pages) {
        logger.logNavigation(event: "Tab changed", from: "\(oldTab)", to: "\(newTab)", metadata: ["pendingPersonalitySheet": pendingPersonalitySheetAfterTabSwitch])

        if pendingPersonalitySheetAfterTabSwitch && newTab == .overview {
            logger.logPersonalitySheet(state: "Tab switched to overview, showing sheet", currentTab: "\(newTab)", metadata: ["sheetAlreadyOpen": showingPersonalityAnalysis])
            pendingPersonalitySheetAfterTabSwitch = false

            if showingPersonalityAnalysis {
                logger.logPersonalitySheet(state: "Dismissing existing sheet before re-showing (tab switch)")
                pendingPersonalitySheetReshow = true
                showingPersonalityAnalysis = false
            } else {
                showingPersonalityAnalysis = true
                viewModel.personalityDeepLinkCoordinator.resetAnalysisState()
            }
        }
    }

    private func handlePersonalitySheetDismiss() {
        if pendingPersonalitySheetReshow {
            pendingPersonalitySheetReshow = false
            logger.logPersonalitySheet(state: "Re-showing personality sheet after dismiss")
            showingPersonalityAnalysis = true
            viewModel.personalityDeepLinkCoordinator.resetAnalysisState()
        }
    }
}

#Preview {
    RootTabView()
}
