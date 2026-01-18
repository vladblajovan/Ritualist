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
    @State var pendingPersonalitySheetReshow = false // For dismiss-then-reshow pattern
    @State var showingPostOnboardingAssistant = false
    @State var existingHabits: [Habit] = []
    @State var migrationService = MigrationStatusService.shared
    @State var pendingPersonalitySheetAfterTabSwitch = false

    // Quick Actions state
    @Injected(\.quickActionCoordinator) private var quickActionCoordinator
    @State private var showingQuickActionAddHabit = false
    @State private var pendingQuickActionAddHabitReshow = false // For dismiss-then-reshow pattern
    @State private var showingQuickActionHabitsAssistant = false
    @State private var pendingQuickActionHabitsAssistantReshow = false // For dismiss-then-reshow pattern

    public init() {}

    @ViewBuilder
    public var body: some View {
        @Bindable var vm = viewModel
        
        Group {
            if isCheckingOnboarding || migrationService.isMigrating {
                // Show branded launch screen while detecting iCloud data or during migration
                AppLaunchView(migrationDetails: migrationService.migrationDetails)
            } else {
                TabView(selection: $vm.navigationService.selectedTab) {
                    Tab(Strings.Navigation.overview, systemImage: "calendar", value: Pages.overview) {
                            NavigationStack {
                                OverviewRoot()
                            }
                            .accessibilityIdentifier(AccessibilityID.Overview.root)
                        }

                        Tab(Strings.Navigation.habits, systemImage: "checklist", value: Pages.habits) {
                            NavigationStack {
                                HabitsRoot()
                            }
                            .accessibilityIdentifier(AccessibilityID.Habits.root)
                        }

                        Tab(Strings.Navigation.stats, systemImage: "chart.bar.fill", value: Pages.stats) {
                            NavigationStack {
                                StatsRoot()
                            }
                            .accessibilityIdentifier(AccessibilityID.Stats.root)
                        }
                }
                .preferredColorScheme(vm.appearanceManager.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                    // Show one-time toast when iCloud syncs data for the first time
                    handleFirstiCloudSync()
                    // Check if we need to show returning user welcome
                    handleReturningUserWelcome()
                }
            }
        }
        .task {
            await checkOnboardingStatus()
            await viewModel.loadUserAppearancePreference()
        }
        .onChange(of: isCheckingOnboarding) { _, newValue in
            // Show syncing toast only after launch screen is dismissed
            if !newValue && viewModel.pendingReturningUserWelcome {
                viewModel.showSyncingDataToast()
            }
        }
        .fullScreenCover(
            isPresented: $showOnboarding,
            onDismiss: {
                // Handle post-onboarding after the fullScreenCover has actually dismissed
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await handlePostOnboarding()
                }
            },
            content: {
                // Show new user onboarding flow
                OnboardingFlowView(onComplete: {
                    showOnboarding = false
                })
            }
        )
        // Returning user welcome - shown as sheet AFTER app loads and data syncs
        .fullScreenCover(
            isPresented: Binding(
                get: { viewModel.showReturningUserWelcome },
                set: { if !$0 { viewModel.dismissReturningUserWelcome() } }
            ),
            onDismiss: {
                // Check for iCloud sync toast after welcome screen dismissed
                handleFirstiCloudSync()
            },
            content: {
                if let summary = viewModel.syncedDataSummary {
                    ReturningUserOnboardingView(summary: summary, onComplete: {
                        viewModel.dismissReturningUserWelcome()
                    })
                    .onAppear {
                        // Dismiss syncing toast exactly when returning user welcome appears
                        viewModel.dismissSyncingDataToast()
                    }
                }
            }
        )
        .habitsAssistantSheet(
            isPresented: $showingPostOnboardingAssistant,
            existingHabits: existingHabits,
            isFirstVisit: true,
            onDataRefreshNeeded: {
                await loadCurrentHabits()
                // Check for iCloud sync toast now that all sheets are dismissed
                handleFirstiCloudSync()
            }
        )
        .onChange(of: vm.personalityDeepLinkCoordinator.shouldShowPersonalityAnalysis) { oldValue, shouldShow in
            if shouldShow {
                logger.logPersonalitySheet(
                    state: "shouldShow triggered",
                    shouldSwitchTab: vm.personalityDeepLinkCoordinator.shouldSwitchTab,
                    currentTab: "\(vm.navigationService.selectedTab)",
                    metadata: ["oldValue": oldValue, "shouldShow": shouldShow, "sheetAlreadyOpen": showingPersonalityAnalysis]
                )

                // Helper to show the sheet (with dismiss-first logic if already open)
                let presentSheet = {
                    if showingPersonalityAnalysis {
                        // Sheet already open - dismiss first, onDismiss will re-show
                        logger.logPersonalitySheet(state: "Dismissing existing sheet before re-showing")
                        pendingPersonalitySheetReshow = true
                        showingPersonalityAnalysis = false
                    } else {
                        showingPersonalityAnalysis = true
                        vm.personalityDeepLinkCoordinator.resetAnalysisState()
                    }
                }

                if vm.personalityDeepLinkCoordinator.shouldSwitchTab {
                    // Navigate to overview tab first (for notifications)
                    logger.logPersonalitySheet(
                        state: "Navigating to overview tab",
                        shouldSwitchTab: true,
                        currentTab: "\(vm.navigationService.selectedTab)"
                    )

                    if vm.navigationService.selectedTab == .overview {
                        // Already on overview - show sheet directly
                        logger.logPersonalitySheet(
                            state: "Already on overview, showing sheet directly",
                            currentTab: "\(vm.navigationService.selectedTab)"
                        )
                        presentSheet()
                    } else {
                        // Need to switch tabs first - sheet will show via onChange(of: selectedTab)
                        pendingPersonalitySheetAfterTabSwitch = true
                        vm.navigationService.selectedTab = .overview

                        logger.logPersonalitySheet(
                            state: "selectedTab assigned",
                            currentTab: "\(vm.navigationService.selectedTab)"
                        )
                    }
                } else {
                    // Show directly without tab navigation (for direct calls)
                    logger.logPersonalitySheet(
                        state: "Showing sheet directly (no tab navigation)",
                        shouldSwitchTab: false
                    )
                    presentSheet()
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
                    currentTab: "\(newTab)",
                    metadata: ["sheetAlreadyOpen": showingPersonalityAnalysis]
                )

                pendingPersonalitySheetAfterTabSwitch = false

                if showingPersonalityAnalysis {
                    // Sheet already open - dismiss first, onDismiss will re-show
                    logger.logPersonalitySheet(state: "Dismissing existing sheet before re-showing (tab switch)")
                    pendingPersonalitySheetReshow = true
                    showingPersonalityAnalysis = false
                } else {
                    showingPersonalityAnalysis = true
                    vm.personalityDeepLinkCoordinator.resetAnalysisState()
                }
            }
        }
        .sheet(
            isPresented: $showingPersonalityAnalysis,
            onDismiss: {
                // Check if we need to re-show the sheet (dismiss-then-reshow pattern)
                // onDismiss is called after dismiss animation completes, so we can set state directly
                if pendingPersonalitySheetReshow {
                    pendingPersonalitySheetReshow = false
                    logger.logPersonalitySheet(state: "Re-showing personality sheet after dismiss")
                    showingPersonalityAnalysis = true
                    vm.personalityDeepLinkCoordinator.resetAnalysisState()
                }
            },
            content: {
                logger.logPersonalitySheet(state: "Sheet is being presented")

                return PersonalityAnalysisDeepLinkSheet(
                    action: vm.personalityDeepLinkCoordinator.pendingNotificationAction
                ) {
                    logger.logPersonalitySheet(state: "Sheet dismissed by user")

                    // Only clear the notification action on dismissal
                    vm.personalityDeepLinkCoordinator.pendingNotificationAction = nil
                    showingPersonalityAnalysis = false
                }
                .accessibilityIdentifier(AccessibilityID.PersonalityAnalysis.sheet)
            }
        )
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
            // Yield to next runloop to ensure view is laid out before processing
            Task { @MainActor in
                await Task.yield()
                logger.log("RootTabView: Processing pending Quick Action after yield", level: .debug, category: .ui)
                quickActionCoordinator.processPendingAction()
            }
        }
        .onChange(of: quickActionCoordinator.pendingAction) { oldValue, newValue in
            // Handle warm start Quick Actions - pendingAction is set by scene delegate
            // but processPendingAction() is not called there to avoid race conditions
            if newValue != nil && oldValue == nil {
                logger.log(
                    "RootTabView: Detected new pending Quick Action (warm start)",
                    level: .info,
                    category: .ui,
                    metadata: ["action": String(describing: newValue)]
                )
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
                vm.navigationService.selectedTab = .habits

                // Check if another quick action sheet needs to be dismissed first
                if showingQuickActionHabitsAssistant {
                    // Dismiss current sheet, onDismiss will re-show the new one
                    pendingQuickActionAddHabitReshow = true
                    showingQuickActionHabitsAssistant = false
                } else if showingQuickActionAddHabit {
                    // Same sheet already open - dismiss and re-show
                    pendingQuickActionAddHabitReshow = true
                    showingQuickActionAddHabit = false
                } else {
                    // No sheet open, show directly
                    logger.log("Quick Action: Showing Add Habit sheet", level: .info, category: .ui)
                    showingQuickActionAddHabit = true
                }
                quickActionCoordinator.resetTriggers()
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
                vm.navigationService.selectedTab = .habits

                // Check if another quick action sheet needs to be dismissed first
                if showingQuickActionAddHabit {
                    // Dismiss current sheet, onDismiss will re-show the new one
                    pendingQuickActionHabitsAssistantReshow = true
                    showingQuickActionAddHabit = false
                } else if showingQuickActionHabitsAssistant {
                    // Same sheet already open - dismiss and re-show
                    pendingQuickActionHabitsAssistantReshow = true
                    showingQuickActionHabitsAssistant = false
                } else {
                    // No sheet open, show directly
                    logger.log("Quick Action: Showing Habits Assistant sheet", level: .info, category: .ui)
                    showingQuickActionHabitsAssistant = true
                }
                quickActionCoordinator.resetTriggers()
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

                // Dismiss any open quick action sheets
                showingQuickActionAddHabit = false
                showingQuickActionHabitsAssistant = false

                // Navigate to stats tab - no need to wait for sheet dismissal
                // Tab navigation is independent of sheet state
                vm.navigationService.selectedTab = .stats
                quickActionCoordinator.resetTriggers()
            }
        }
        .sheet(
            isPresented: $showingQuickActionAddHabit,
            onDismiss: {
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await loadCurrentHabits()
                }
                // Check if we need to re-show this sheet or show a different one
                // onDismiss is called after dismiss animation completes, so we can set state directly
                if pendingQuickActionAddHabitReshow {
                    pendingQuickActionAddHabitReshow = false
                    logger.log("Quick Action: Re-showing Add Habit sheet after dismiss", level: .info, category: .ui)
                    showingQuickActionAddHabit = true
                } else if pendingQuickActionHabitsAssistantReshow {
                    pendingQuickActionHabitsAssistantReshow = false
                    logger.log("Quick Action: Showing Habits Assistant sheet after Add Habit dismiss", level: .info, category: .ui)
                    showingQuickActionHabitsAssistant = true
                }
            },
            content: {
                let detailVM = HabitDetailViewModel(habit: nil)
                HabitDetailView(vm: detailVM)
                    .accessibilityIdentifier(AccessibilityID.HabitDetail.sheet)
            }
        )
        .habitsAssistantSheet(
            isPresented: $showingQuickActionHabitsAssistant,
            existingHabits: existingHabits,
            isFirstVisit: false,
            onDataRefreshNeeded: {
                await loadCurrentHabits()
                // Check if we need to re-show this sheet or show a different one
                if pendingQuickActionHabitsAssistantReshow {
                    pendingQuickActionHabitsAssistantReshow = false
                    logger.log("Quick Action: Re-showing Habits Assistant sheet after dismiss", level: .info, category: .ui)
                    showingQuickActionHabitsAssistant = true
                } else if pendingQuickActionAddHabitReshow {
                    pendingQuickActionAddHabitReshow = false
                    logger.log("Quick Action: Showing Add Habit sheet after Habits Assistant dismiss", level: .info, category: .ui)
                    showingQuickActionAddHabit = true
                }
            }
        )
        // MARK: - Centralized Toast Overlay
        // This overlay is at the root level so toasts appear above all content including NavigationStacks
        // Supports multiple stacked toasts with newest on top
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                ForEach(Array(viewModel.toastItems.enumerated()), id: \.element.id) { index, toast in
                    toastView(for: toast)
                        // Visual hierarchy: older toasts recede proportionally
                        .scaleEffect(1.0 - (Double(index) * ToastVisualHierarchy.scaleReductionPerIndex))
                        .opacity(1.0 - (Double(index) * ToastVisualHierarchy.opacityReductionPerIndex))
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(.top, 4)
        }
        .animation(SpringAnimation.interactive, value: viewModel.toastItems.map(\.id))
    }
}

#Preview {
    RootTabView()
}
