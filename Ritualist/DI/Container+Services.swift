import Foundation
import FactoryKit
import RitualistCore

// MARK: - Services Container Extensions

extension Container {
    
    // MARK: - Core Services

    var debugLogger: Factory<DebugLogger> {
        self {
            DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "general")
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

    var dataDeduplicationService: Factory<DataDeduplicationServiceProtocol> {
        self {
            DataDeduplicationService(modelContainer: self.persistenceContainer().container)
        }
        .singleton
    }

    /// One-time cleanup service to remove PersonalityAnalysis from CloudKit
    /// REMOVAL NOTICE: This can be removed after all users have updated (2-3 releases)
    var cloudKitCleanupService: Factory<CloudKitCleanupServiceProtocol> {
        self {
            CloudKitCleanupService(
                logger: self.debugLogger(),
                userDefaults: self.userDefaultsService()
            )
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

                // Handle default tap on notification: navigate to Overview
                if action == .openApp {
                    await MainActor.run {
                        self.navigationService().navigateToOverview(shouldRefresh: true)
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
    
    @MainActor
    var widgetRefreshService: Factory<WidgetRefreshServiceProtocol> {
        self { @MainActor in WidgetRefreshService(logger: self.debugLogger()) }
            .singleton
    }

    var iCloudKeyValueService: Factory<iCloudKeyValueService> {
        self { DefaultiCloudKeyValueService(logger: self.debugLogger()) }
            .singleton
    }

    var userDefaultsService: Factory<UserDefaultsService> {
        self { DefaultUserDefaultsService() }
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
                timezoneService: self.timezoneService(),
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
                subscriptionService: self.subscriptionService(),
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

    var timezoneService: Factory<TimezoneService> {
        self {
            DefaultTimezoneService(
                loadProfile: self.loadProfile(),
                saveProfile: self.saveProfile()
            )
        }
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
    
    // MARK: - User Service

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
            // Build flag logic:
            // - ALL_FEATURES_ENABLED: Mock with premium always on (Ritualist-AllFeatures scheme)
            // - No flags (default): Real StoreKit2 for production (Ritualist scheme)
            #if ALL_FEATURES_ENABLED
            return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())
            #else
            return StoreKitSubscriptionService(errorHandler: self.errorHandler())
            #endif
        }
        .singleton
    }

    // Alias for subscription service (used by ViewModels)
    var subscriptionService: Factory<SecureSubscriptionService> {
        secureSubscriptionService
    }
    
    // MARK: - Paywall Service

    var paywallService: Factory<PaywallService> {
        self {
            // Build flag logic:
            // - ALL_FEATURES_ENABLED: NoOp paywall (all features unlocked)
            // - Default: Real StoreKit2 for production
            #if ALL_FEATURES_ENABLED
            return NoOpPaywallService()
            #else
            return StoreKitPaywallService(
                subscriptionService: self.secureSubscriptionService(),
                logger: self.debugLogger()
            )
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
        self { DefaultFeatureGatingService(subscriptionService: self.subscriptionService(), errorHandler: self.errorHandler()) }
            .singleton
    }

    // MARK: - Feature Gating Service

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

    // MARK: - Coordinators

    @MainActor
    var personalityDeepLinkCoordinator: Factory<PersonalityDeepLinkCoordinator> {
        self { @MainActor in
            PersonalityDeepLinkCoordinator(logger: self.debugLogger())
        }
        .singleton
    }

    @MainActor
    var quickActionCoordinator: Factory<QuickActionCoordinator> {
        self { @MainActor in
            QuickActionCoordinator(logger: self.debugLogger())
        }
        .singleton
    }

    @MainActor
    var permissionCoordinator: Factory<PermissionCoordinatorProtocol> {
        self { @MainActor in
            PermissionCoordinator(
                requestNotificationPermission: self.requestNotificationPermission(),
                checkNotificationStatus: self.checkNotificationStatus(),
                requestLocationPermissions: self.requestLocationPermissions(),
                getLocationAuthStatus: self.getLocationAuthStatus(),
                dailyNotificationScheduler: self.dailyNotificationScheduler(),
                restoreGeofenceMonitoring: self.restoreGeofenceMonitoring(),
                logger: self.debugLogger()
            )
        }
        .singleton
    }
    
    var urlValidationService: Factory<URLValidationService> {
        self { DefaultURLValidationService() }
        .singleton
    }

    var importValidationService: Factory<ImportValidationService> {
        self { DefaultImportValidationService(logger: self.debugLogger()) }
        .singleton
    }
    
    // MARK: - Toast Service

    @MainActor
    var toastService: Factory<ToastServiceProtocol> {
        self { @MainActor in ToastService() }
            .singleton
    }

    // MARK: - Inspiration Services

    var inspirationDismissalStore: Factory<InspirationDismissalStoreProtocol> {
        self {
            InspirationDismissalStore(
                userDefaults: self.userDefaultsService(),
                logger: self.debugLogger()
            )
        }
        .singleton
    }

    var completionPatternAnalyzer: Factory<CompletionPatternAnalyzerProtocol> {
        self {
            CompletionPatternAnalyzer(
                getActiveHabits: self.getActiveHabits(),
                getLogs: self.getLogs(),
                logger: self.debugLogger()
            )
        }
        .singleton
    }

    // MARK: - Debug Services

    #if DEBUG
    var debugService: Factory<DebugServiceProtocol> {
        self {
            MainActor.assumeIsolated {
                let container = self.persistenceContainer()
                return DebugService(persistenceContainer: container)
            }
        }
        .singleton
    }
    
    var testDataPopulationService: Factory<TestDataPopulationServiceProtocol> {
        self { TestDataPopulationService() }
        .singleton
    }
    #endif
}
