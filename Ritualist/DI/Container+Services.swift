import Foundation
import FactoryKit
import RitualistCore

// MARK: - Services Container Extensions

extension Container {
    
    // MARK: - Core Services

    var debugLogger: Factory<DebugLogger> {
        self {
            DebugLogger(subsystem: "com.ritualist.app", category: "general")
        }
        .singleton
    }

    var errorHandler: Factory<ErrorHandler> {
        self {
            ErrorHandler(maxLogSize: 1000, analyticsEnabled: true, logger: self.debugLogger())
        }
        .singleton
    }

    var categoryDefinitionsService: Factory<CategoryDefinitionsServiceProtocol> {
        self { CategoryDefinitionsService() }
            .singleton
    }

    var habitMaintenanceService: Factory<HabitMaintenanceServiceProtocol> {
        self {
            HabitMaintenanceService(modelContainer: self.persistenceContainer().container)
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
                errorHandler: self.errorHandler(),
                logger: self.debugLogger()
            )
            service.trackingService = self.userActionTracker()

            // Set personality deep link coordinator for handling personality notifications
            Task { @MainActor in
                service.personalityDeepLinkCoordinator = self.personalityDeepLinkCoordinator()
            }

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

    @MainActor
    var migrationStatusService: Factory<MigrationStatusService> {
        self { @MainActor in RitualistCore.MigrationStatusService.shared }
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

    var personalizedMessageGenerator: Factory<PersonalizedMessageGeneratorProtocol> {
        self { PersonalizedMessageGenerator() }
            .singleton
    }

    @MainActor
    var hapticFeedbackService: Factory<HapticFeedbackService> {
        self { @MainActor in HapticFeedbackService.shared }
            .singleton
    }
    
    var widgetRefreshService: Factory<WidgetRefreshServiceProtocol> {
        self { WidgetRefreshService(logger: self.debugLogger()) }
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
                calendar: CalendarUtils.currentLocalCalendar,
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
                notificationService: self.notificationService(),
                logger: self.debugLogger()
            )
        }
        .singleton
    }
    
    var streakCalculationService: Factory<RitualistCore.StreakCalculationService> {
        self {
            RitualistCore.DefaultStreakCalculationService(
                habitCompletionService: self.habitCompletionService(),
                logger: self.debugLogger()
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
            return RitualistCore.DebugUserActionTrackerService(logger: self.debugLogger())
            #else
            return RitualistCore.NoOpUserActionTrackerService()
            #endif
        }
        .singleton
    }
    
    // MARK: - User Business Service
    
    var userBusinessService: Factory<UserBusinessService> {
        self {
            // ⚠️ TEMPORARY: Using MockUserBusinessService for both DEBUG and Release
            // CloudKit entitlements are currently disabled (requires paid Apple Developer Program)
            //
            // TO RE-ENABLE iCloud sync:
            // 1. Uncomment CloudKit entitlements in Ritualist.entitlements
            // 2. Uncomment the #else branch below to use ICloudUserBusinessService in production
            // 3. Follow CLOUDKIT-SETUP-GUIDE.md for complete setup
            //
            // See ICLOUD-INVESTIGATION-SUMMARY.md for details

            return MockUserBusinessService(
                loadProfile: self.loadProfile(),
                saveProfile: self.saveProfile(),
                errorHandler: self.errorHandler()
            )

            // #if DEBUG
            // return MockUserBusinessService(
            //     loadProfile: self.loadProfile(),
            //     saveProfile: self.saveProfile(),
            //     errorHandler: self.errorHandler()
            // )
            // #else
            // return ICloudUserBusinessService(errorHandler: self.errorHandler())
            // #endif
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
        self {
            // ⚠️ TEMPORARY: Using MockSecureSubscriptionService
            // StoreKit entitlements require Apple Developer Program subscription ($99/year)
            //
            // TO RE-ENABLE StoreKit:
            // 1. Purchase Apple Developer Program membership
            // 2. Create IAP products in App Store Connect (see StoreKitConstants.swift)
            // 3. Uncomment StoreKitSubscriptionService below
            // 4. Follow docs/STOREKIT-SETUP-GUIDE.md for complete setup

            return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())

            // Production StoreKit implementation (ready to enable):
            // return StoreKitSubscriptionService(errorHandler: self.errorHandler())
        }
        .singleton
    }

    // Alias for subscription service (used by ViewModels)
    var subscriptionService: Factory<SecureSubscriptionService> {
        secureSubscriptionService
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
            // ⚠️ TEMPORARY: Using MockPaywallService for all builds
            // StoreKit entitlements require Apple Developer Program subscription ($99/year)
            //
            // TO RE-ENABLE StoreKit:
            // 1. Purchase Apple Developer Program membership
            // 2. Create IAP products in App Store Connect (see StoreKitConstants.swift)
            // 3. Uncomment the #if/#else branches below
            // 4. Follow docs/STOREKIT-SETUP-GUIDE.md for complete setup

            let mockPaywall = MockPaywallService(
                subscriptionService: self.secureSubscriptionService(),
                testingScenario: .randomResults
            )
            mockPaywall.configure(scenario: .randomResults, delay: 1.5, failureRate: 0.15)
            return mockPaywall

            // #if DEBUG
            // let mockPaywall = MockPaywallService(
            //     subscriptionService: self.secureSubscriptionService(),
            //     testingScenario: .randomResults
            // )
            // mockPaywall.configure(scenario: .randomResults, delay: 1.5, failureRate: 0.15)
            // return mockPaywall
            // #else
            // // Production StoreKit implementation (ready to enable)
            // return MainActor.assumeIsolated {
            //     StoreKitPaywallService(
            //         subscriptionService: self.secureSubscriptionService(),
            //         logger: self.debugLogger()
            //     )
            // }
            // #endif
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
        self { DefaultFeatureGatingService(subscriptionService: self.subscriptionService(), errorHandler: self.errorHandler()) }
            .singleton
    }

    var defaultFeatureGatingBusinessService: Factory<FeatureGatingBusinessService> {
        self { DefaultFeatureGatingBusinessService(subscriptionService: self.subscriptionService(), errorHandler: self.errorHandler()) }
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
            let container = self.persistenceContainer()
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
