import Foundation
import FactoryKit
import RitualistCore

// MARK: - Services Container Extensions

extension Container {
    
    // MARK: - Core Services
    
    var errorHandler: Factory<ErrorHandler> {
        self { 
            ErrorHandler(maxLogSize: 1000, analyticsEnabled: true)
        }
        .singleton
    }
    
    @MainActor
    var navigationService: Factory<NavigationService> {
        self { @MainActor in 
            let service = NavigationService()
            service.trackingService = self.userActionTracker()
            return service
        }
        .singleton
    }
    
    var notificationService: Factory<NotificationService> {
        self { 
            let service = LocalNotificationService(
                habitCompletionCheckService: self.habitCompletionCheckService(),
                errorHandler: self.errorHandler()
            )
            service.trackingService = self.userActionTracker()
            
            // Configure the action handler to use dependency injection
            service.actionHandler = { [weak self] action, habitId, habitName, habitKind, reminderTime in
                guard let self = self else { return }
                try await self.handleNotificationAction().execute(
                    action: action,
                    habitId: habitId,
                    habitName: habitName,
                    habitKind: habitKind,
                    reminderTime: reminderTime
                )
                
                // Handle numeric habits: fetch habit and set as pending, then navigate to Overview
                if action == .log && habitKind == .numeric {
                    Task {
                        // Fetch the habit object
                        do {
                            if let habit = try await self.habitRepository().fetchHabit(by: habitId) {
                                // Set the habit as pending on the OverviewViewModel
                                await MainActor.run {
                                    self.overviewViewModel().setPendingNumericHabit(habit)
                                    self.navigationService().navigateToOverview(shouldRefresh: true)
                                }
                            }
                        } catch {
                            // Fallback: just navigate to Overview without the automatic sheet
                            await MainActor.run {
                                self.navigationService().navigateToOverview(shouldRefresh: true)
                            }
                        }
                    }
                }
            }
            
            return service
        }
        .singleton
    }
    
    var appearanceManager: Factory<AppearanceManager> {
        self { RitualistCore.AppearanceManager() }
            .singleton
    }
    
    var habitSuggestionsService: Factory<HabitSuggestionsService> {
        self { DefaultHabitSuggestionsService() }
            .singleton
    }
    
    var slogansService: Factory<SlogansServiceProtocol> {
        self { SlogansService() }
            .singleton
    }
    
    @MainActor
    var hapticFeedbackService: Factory<HapticFeedbackService> {
        self { @MainActor in HapticFeedbackService.shared }
            .singleton
    }
    
    var widgetRefreshService: Factory<WidgetRefreshServiceProtocol> {
        self { WidgetRefreshService() }
            .singleton
    }
    
    var scheduleAwareCompletionCalculator: Factory<ScheduleAwareCompletionCalculator> {
        self { DefaultScheduleAwareCompletionCalculator(habitCompletionService: self.habitCompletionService()) }
            .singleton
    }
    
    var habitCompletionService: Factory<HabitCompletionService> {
        self { DefaultHabitCompletionService() }
            .singleton
    }
    
    var habitCompletionCheckService: Factory<HabitCompletionCheckService> {
        self { 
            DefaultHabitCompletionCheckService(
                habitRepository: self.habitRepository(),
                logRepository: self.logRepository(),
                habitCompletionService: self.habitCompletionService(),
                calendar: Calendar.current,
                errorHandler: self.errorHandler()
            )
        }
        .singleton
    }
    
    var dailyNotificationScheduler: Factory<DailyNotificationSchedulerService> {
        self {
            RitualistCore.DefaultDailyNotificationScheduler(
                habitRepository: self.habitRepository(),
                scheduleHabitReminders: self.scheduleHabitReminders(),
                notificationService: self.notificationService()
            )
        }
        .singleton
    }
    
    var streakCalculationService: Factory<RitualistCore.StreakCalculationService> {
        self { 
            RitualistCore.DefaultStreakCalculationService(
                habitCompletionService: self.habitCompletionService()
            )
        }
        .singleton
    }
    
    var historicalDateValidationService: Factory<HistoricalDateValidationServiceProtocol> {
        self { DefaultHistoricalDateValidationService() }
            .singleton
    }
    
    // MARK: - User & Analytics Services
    
    var userActionTracker: Factory<UserActionTrackerService> {
        self {
            #if DEBUG
            return RitualistCore.DebugUserActionTrackerService()
            #else
            return RitualistCore.NoOpUserActionTrackerService()
            #endif
        }
        .singleton
    }
    
    // MARK: - User Business Service
    
    var userBusinessService: Factory<UserBusinessService> {
        self {
            #if DEBUG
            return MockUserBusinessService(
                loadProfile: self.loadProfile(), 
                saveProfile: self.saveProfile(),
                errorHandler: self.errorHandler()
            )
            #else
            return ICloudUserBusinessService(errorHandler: self.errorHandler())
            #endif
        }
        .singleton
    }
    
    // MARK: - Legacy User Service
    
    @available(*, deprecated, message: "Use userUIService instead")
    var userService: Factory<UserService> {
        self {
            #if DEBUG
            return MockUserService(
                loadProfile: self.loadProfile(), 
                saveProfile: self.saveProfile(),
                errorHandler: self.errorHandler()
            )
            #else
            return ICloudUserService(errorHandler: self.errorHandler())
            #endif
        }
        .singleton
    }
    
    // MARK: - Subscription Service
    
    var secureSubscriptionService: Factory<SecureSubscriptionService> {
        self { RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler()) }
        .singleton
    }
    
    // MARK: - Paywall Business Service
    
    var paywallBusinessService: Factory<PaywallBusinessService> {
        self {
            #if DEBUG
            let mockBusiness = MockPaywallBusinessService(
                testingScenario: .randomResults
            )
            mockBusiness.configure(scenario: .randomResults, delay: 1.5, failureRate: 0.15)
            return mockBusiness
            #else
            return NoOpPaywallBusinessService() // TODO: Replace with StoreKit business service
            #endif
        }
        .singleton
    }
    
    // MARK: - Legacy Paywall Service (Deprecated)
    
    @available(*, deprecated, message: "Use paywallUIService instead")
    var paywallService: Factory<PaywallService> {
        self {
            #if DEBUG
            let mockPaywall = MockPaywallService(
                subscriptionService: self.secureSubscriptionService(),
                testingScenario: .randomResults
            )
            mockPaywall.configure(scenario: .randomResults, delay: 1.5, failureRate: 0.15)
            return mockPaywall
            #else
            // MainActor-isolated service creation
            return MainActor.assumeIsolated {
                StoreKitPaywallService()
            }
            #endif
        }
        .singleton
    }
    
    // MARK: - Build Configuration Service
    
    var buildConfigurationService: Factory<BuildConfigurationService> {
        self { DefaultBuildConfigurationService() }
            .singleton
    }
    
    // MARK: - Standard Feature Gating Services
    
    var defaultFeatureGatingService: Factory<FeatureGatingService> {
        self { DefaultFeatureGatingService(userService: self.userService(), errorHandler: self.errorHandler()) }
            .singleton
    }
    
    var defaultFeatureGatingBusinessService: Factory<FeatureGatingBusinessService> {
        self { DefaultFeatureGatingBusinessService(userService: self.userService(), errorHandler: self.errorHandler()) }
            .singleton
    }
    
    // MARK: - Feature Gating Service
    
    // MARK: - Feature Gating Business Service
    
    var featureGatingBusinessService: Factory<FeatureGatingBusinessService> {
        self {
            #if ALL_FEATURES_ENABLED
            return MockFeatureGatingBusinessService(errorHandler: self.errorHandler())
            #else
            return BuildConfigFeatureGatingBusinessService(
                buildConfigService: self.buildConfigurationService(),
                standardFeatureGating: self.defaultFeatureGatingBusinessService()
            )
            #endif
        }
        .singleton
    }
    
    // MARK: - Legacy Feature Gating Service
    
    @available(*, deprecated, message: "Use featureGatingUIService instead")
    var featureGatingService: Factory<FeatureGatingService> {
        self {
            #if ALL_FEATURES_ENABLED
            return MockFeatureGatingService(errorHandler: self.errorHandler())
            #else
            return BuildConfigFeatureGatingService(
                buildConfigService: self.buildConfigurationService(),
                standardFeatureGating: self.defaultFeatureGatingService()
            )
            #endif
        }
        .singleton
    }

    // MARK: - Deep Link Coordination
    
    @MainActor
    var personalityDeepLinkCoordinator: Factory<PersonalityDeepLinkCoordinator> {
        self { @MainActor in RitualistCore.PersonalityDeepLinkCoordinator.shared }
        .singleton
    }
    
    var urlValidationService: Factory<URLValidationService> {
        self { DefaultURLValidationService() }
        .singleton
    }
    
    // MARK: - Debug Services
    
    #if DEBUG
    var debugService: Factory<DebugServiceProtocol> {
        self { 
            guard let container = self.persistenceContainer() else {
                fatalError("Failed to get PersistenceContainer for DebugService")
            }
            return DebugService(persistenceContainer: container)
        }
        .singleton
    }
    
    var testDataPopulationService: Factory<TestDataPopulationServiceProtocol> {
        self { TestDataPopulationService() }
        .singleton
    }
    #endif
}
