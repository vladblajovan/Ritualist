import Foundation
import SwiftData

// MARK: - Default DI Container

public final class DefaultAppContainer: AppContainer {
    public let habitRepository: HabitRepository
    public let logRepository: LogRepository
    public let profileRepository: ProfileRepository
    public let tipRepository: TipRepository
    public let onboardingRepository: OnboardingRepository
    public let userAuthRepository: UserAuthRepository
    public let notificationService: NotificationService
    public let dateProvider: DateProvider
    public let streakEngine: StreakEngine
    public let appearanceManager: AppearanceManager
    public let habitSuggestionsService: HabitSuggestionsService
    public let userActionTracker: UserActionTracker
    public let authenticationService: any AuthenticationService
    public let userSession: any UserSessionProtocol
    public let paywallService: PaywallService
    public let featureGatingService: FeatureGatingService
    public let stateCoordinator: any StateCoordinatorProtocol
    public let secureUserDefaults: SecureUserDefaults
    public let stateValidationService: any StateValidationServiceProtocol
    public let errorRecoveryService: any ErrorRecoveryServiceProtocol
    public let systemHealthMonitor: any SystemHealthMonitorProtocol
    public let errorHandlingStrategy: any ErrorHandlingStrategyProtocol
    public let refreshTrigger: RefreshTrigger
    public let slogansService: SlogansServiceProtocol
    
    // Factory methods
    public lazy var onboardingFactory = OnboardingFactory(container: self)

    public init(habitRepository: HabitRepository,
                logRepository: LogRepository,
                profileRepository: ProfileRepository,
                tipRepository: TipRepository,
                onboardingRepository: OnboardingRepository,
                userAuthRepository: UserAuthRepository,
                notificationService: NotificationService,
                dateProvider: DateProvider,
                streakEngine: StreakEngine,
                appearanceManager: AppearanceManager,
                habitSuggestionsService: HabitSuggestionsService,
                userActionTracker: UserActionTracker,
                authenticationService: any AuthenticationService,
                userSession: any UserSessionProtocol,
                paywallService: PaywallService,
                featureGatingService: FeatureGatingService,
                stateCoordinator: any StateCoordinatorProtocol,
                secureUserDefaults: SecureUserDefaults,
                stateValidationService: any StateValidationServiceProtocol,
                errorRecoveryService: any ErrorRecoveryServiceProtocol,
                systemHealthMonitor: any SystemHealthMonitorProtocol,
                errorHandlingStrategy: any ErrorHandlingStrategyProtocol,
                refreshTrigger: RefreshTrigger,
                slogansService: SlogansServiceProtocol) {
        self.habitRepository = habitRepository
        self.logRepository = logRepository
        self.profileRepository = profileRepository
        self.tipRepository = tipRepository
        self.onboardingRepository = onboardingRepository
        self.userAuthRepository = userAuthRepository
        self.notificationService = notificationService
        self.dateProvider = dateProvider
        self.streakEngine = streakEngine
        self.appearanceManager = appearanceManager
        self.habitSuggestionsService = habitSuggestionsService
        self.userActionTracker = userActionTracker
        self.authenticationService = authenticationService
        self.userSession = userSession
        self.paywallService = paywallService
        self.featureGatingService = featureGatingService
        self.stateCoordinator = stateCoordinator
        self.secureUserDefaults = secureUserDefaults
        self.stateValidationService = stateValidationService
        self.errorRecoveryService = errorRecoveryService
        self.systemHealthMonitor = systemHealthMonitor
        self.errorHandlingStrategy = errorHandlingStrategy
        self.refreshTrigger = refreshTrigger
        self.slogansService = slogansService
    }

    // Bootstrap with SwiftData and default services (async version)
    public static func bootstrap() async -> DefaultAppContainer {
        let stack = try? SwiftDataStack()
        let dateProvider = SystemDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: dateProvider)
        let refreshTrigger = RefreshTrigger()

        let habitDS = HabitLocalDataSource(context: stack?.context)
        let logDS   = LogLocalDataSource(context: stack?.context)
        let profileDS = ProfileLocalDataSource(context: stack?.context)
        let tipDS = TipLocalDataSource()
        let onboardingDS = OnboardingLocalDataSource(context: stack?.context)

        let habitRepo: HabitRepository = HabitRepositoryImpl(local: habitDS)
        let logRepo: LogRepository = LogRepositoryImpl(local: logDS)
        let profileRepo: ProfileRepository = ProfileRepositoryImpl(local: profileDS)
        let tipRepo: TipRepository = TipRepositoryImpl(local: tipDS)
        let onboardingRepo: OnboardingRepository = OnboardingRepositoryImpl(local: onboardingDS)
        let userAuthRepo: UserAuthRepository = MockUserAuthRepositoryImpl()
        let notifications: NotificationService = LocalNotificationService()
        let appearanceManager = AppearanceManager()
        let habitSuggestionsService: HabitSuggestionsService = DefaultHabitSuggestionsService()
        
        // Use DebugUserActionTracker in development, NoOpUserActionTracker in production
        // You can easily swap this with your preferred analytics provider later
        #if DEBUG
        let userActionTracker: UserActionTracker = DebugUserActionTracker()
        #else
        let userActionTracker: UserActionTracker = NoOpUserActionTracker()
        #endif
        
        // Authentication services - use mock in debug, can be swapped for production
        let authService: any AuthenticationService = await MockAuthenticationService()
        let userSession = await UserSession(authService: authService)
        
        // Paywall services
        let paywallService: PaywallService = MockPaywallService()
        let featureGatingService: FeatureGatingService = DefaultFeatureGatingService(userSession: userSession)
        
        // State coordination services
        let secureUserDefaults = SecureUserDefaults()
        let stateCoordinator: any StateCoordinatorProtocol = StateCoordinator(
            paywallService: paywallService,
            authService: authService,
            userSession: userSession,
            secureDefaults: secureUserDefaults
        )
        
        // Wire up coordination
        await userSession.setStateCoordinator(stateCoordinator)
        
        // Phase 2: Reliability services
        let logger = DebugLogger(subsystem: "com.ritualist.app", category: "system")
        let stateValidationService: any StateValidationServiceProtocol = StateValidationService(
            dateProvider: dateProvider,
            logger: logger,
            userSession: userSession,
            profileRepository: profileRepo
        )
        
        let errorRecoveryService: any ErrorRecoveryServiceProtocol = ErrorRecoveryService(
            logger: logger,
            userSession: userSession,
            stateCoordinator: stateCoordinator,
            secureUserDefaults: secureUserDefaults,
            profileRepository: profileRepo,
            validationService: stateValidationService
        )
        
        let systemHealthMonitor: any SystemHealthMonitorProtocol = SystemHealthMonitor(
            userSession: userSession,
            validationService: stateValidationService,
            logger: logger,
            dateProvider: dateProvider
        )
        
        let errorHandlingStrategy: any ErrorHandlingStrategyProtocol = ErrorHandlingStrategy(
            recoveryService: errorRecoveryService,
            validationService: stateValidationService,
            healthMonitor: systemHealthMonitor,
            logger: logger,
            userSession: userSession
        )

        return DefaultAppContainer(
            habitRepository: habitRepo,
            logRepository: logRepo,
            profileRepository: profileRepo,
            tipRepository: tipRepo,
            onboardingRepository: onboardingRepo,
            userAuthRepository: userAuthRepo,
            notificationService: notifications,
            dateProvider: dateProvider,
            streakEngine: streakEngine,
            appearanceManager: appearanceManager,
            habitSuggestionsService: habitSuggestionsService,
            userActionTracker: userActionTracker,
            authenticationService: authService,
            userSession: userSession,
            paywallService: paywallService,
            featureGatingService: featureGatingService,
            stateCoordinator: stateCoordinator,
            secureUserDefaults: secureUserDefaults,
            stateValidationService: stateValidationService,
            errorRecoveryService: errorRecoveryService,
            systemHealthMonitor: systemHealthMonitor,
            errorHandlingStrategy: errorHandlingStrategy,
            refreshTrigger: refreshTrigger,
            slogansService: SlogansService(dateProvider: dateProvider)
        )
    }
    
    // Synchronous bootstrap for environment defaults
    @MainActor
    public static func bootstrapSync(userSession: any UserSessionProtocol) -> DefaultAppContainer {
        let stack = try? SwiftDataStack()
        let dateProvider = SystemDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: dateProvider)
        let refreshTrigger = RefreshTrigger()

        let habitDS = HabitLocalDataSource(context: stack?.context)
        let logDS   = LogLocalDataSource(context: stack?.context)
        let profileDS = ProfileLocalDataSource(context: stack?.context)
        let tipDS = TipLocalDataSource()
        let onboardingDS = OnboardingLocalDataSource(context: stack?.context)

        let habitRepo: HabitRepository = HabitRepositoryImpl(local: habitDS)
        let logRepo: LogRepository = LogRepositoryImpl(local: logDS)
        let profileRepo: ProfileRepository = ProfileRepositoryImpl(local: profileDS)
        let tipRepo: TipRepository = TipRepositoryImpl(local: tipDS)
        let onboardingRepo: OnboardingRepository = OnboardingRepositoryImpl(local: onboardingDS)
        let userAuthRepo: UserAuthRepository = MockUserAuthRepositoryImpl()
        let notifications: NotificationService = LocalNotificationService()
        let appearanceManager = AppearanceManager()
        let habitSuggestionsService: HabitSuggestionsService = DefaultHabitSuggestionsService()
        
        #if DEBUG
        let userActionTracker: UserActionTracker = DebugUserActionTracker()
        #else
        let userActionTracker: UserActionTracker = NoOpUserActionTracker()
        #endif
        
        // Paywall services
        let paywallService: PaywallService = MockPaywallService()
        let featureGatingService: FeatureGatingService = DefaultFeatureGatingService(userSession: userSession)
        
        // State coordination services - use NoOp for sync bootstrap
        let secureUserDefaults = SecureUserDefaults()
        let stateCoordinator: any StateCoordinatorProtocol = StateCoordinator(
            paywallService: paywallService,
            authService: userSession.authService,
            userSession: userSession,
            secureDefaults: secureUserDefaults
        )
        
        // Minimal Phase 2 services for sync bootstrap
        let logger = DebugLogger()
        let stateValidationService: any StateValidationServiceProtocol = StateValidationService(
            dateProvider: dateProvider,
            logger: logger,
            userSession: userSession,
            profileRepository: profileRepo
        )
        
        let errorRecoveryService: any ErrorRecoveryServiceProtocol = ErrorRecoveryService(
            logger: logger,
            userSession: userSession,
            stateCoordinator: stateCoordinator,
            secureUserDefaults: secureUserDefaults,
            profileRepository: profileRepo,
            validationService: stateValidationService
        )
        
        let systemHealthMonitor: any SystemHealthMonitorProtocol = SystemHealthMonitor(
            userSession: userSession,
            validationService: stateValidationService,
            logger: logger,
            dateProvider: dateProvider
        )
        
        let errorHandlingStrategy: any ErrorHandlingStrategyProtocol = ErrorHandlingStrategy(
            recoveryService: errorRecoveryService,
            validationService: stateValidationService,
            healthMonitor: systemHealthMonitor,
            logger: logger,
            userSession: userSession
        )

        return DefaultAppContainer(
            habitRepository: habitRepo,
            logRepository: logRepo,
            profileRepository: profileRepo,
            tipRepository: tipRepo,
            onboardingRepository: onboardingRepo,
            userAuthRepository: userAuthRepo,
            notificationService: notifications,
            dateProvider: dateProvider,
            streakEngine: streakEngine,
            appearanceManager: appearanceManager,
            habitSuggestionsService: habitSuggestionsService,
            userActionTracker: userActionTracker,
            authenticationService: userSession.authService,
            userSession: userSession,
            paywallService: paywallService,
            featureGatingService: featureGatingService,
            stateCoordinator: stateCoordinator,
            secureUserDefaults: secureUserDefaults,
            stateValidationService: stateValidationService,
            errorRecoveryService: errorRecoveryService,
            systemHealthMonitor: systemHealthMonitor,
            errorHandlingStrategy: errorHandlingStrategy,
            refreshTrigger: refreshTrigger,
            slogansService: SlogansService(dateProvider: dateProvider)
        )
    }
    
    // Minimal container for environment defaults - creates non-async services
    public static func createMinimal() -> DefaultAppContainer {
        // This is a simplified version for environment defaults only
        // Real app should use the async bootstrap method
        let stack = try? SwiftDataStack()
        let dateProvider = SystemDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: dateProvider)
        let refreshTrigger = RefreshTrigger()

        let habitDS = HabitLocalDataSource(context: stack?.context)
        let logDS   = LogLocalDataSource(context: stack?.context)
        let profileDS = ProfileLocalDataSource(context: stack?.context)
        let tipDS = TipLocalDataSource()
        let onboardingDS = OnboardingLocalDataSource(context: stack?.context)

        let habitRepo: HabitRepository = HabitRepositoryImpl(local: habitDS)
        let logRepo: LogRepository = LogRepositoryImpl(local: logDS)
        let profileRepo: ProfileRepository = ProfileRepositoryImpl(local: profileDS)
        let tipRepo: TipRepository = TipRepositoryImpl(local: tipDS)
        let onboardingRepo: OnboardingRepository = OnboardingRepositoryImpl(local: onboardingDS)
        let userAuthRepo: UserAuthRepository = MockUserAuthRepositoryImpl()
        let notifications: NotificationService = LocalNotificationService()
        let appearanceManager = AppearanceManager()
        let habitSuggestionsService: HabitSuggestionsService = DefaultHabitSuggestionsService()
        
        #if DEBUG
        let userActionTracker: UserActionTracker = DebugUserActionTracker()
        #else
        let userActionTracker: UserActionTracker = NoOpUserActionTracker()
        #endif
        
        // Create minimal auth service (non-MainActor)
        let authService: any AuthenticationService = NoOpAuthenticationService()
        let userSession = NoOpUserSession()
        
        // Paywall services - use mock for minimal container
        let paywallService: PaywallService = MockPaywallService()
        let featureGatingService: FeatureGatingService = MockFeatureGatingService()
        
        // State coordination services - use NoOp for minimal container
        let secureUserDefaults = SecureUserDefaults()
        let stateCoordinator: any StateCoordinatorProtocol = StateCoordinator(
            paywallService: paywallService,
            authService: authService,
            userSession: userSession,
            secureDefaults: secureUserDefaults
        )
        
        // Minimal Phase 2 services for createMinimal
        let logger = DebugLogger()
        let stateValidationService: any StateValidationServiceProtocol = StateValidationService(
            dateProvider: dateProvider,
            logger: logger,
            userSession: userSession,
            profileRepository: profileRepo
        )
        
        let errorRecoveryService: any ErrorRecoveryServiceProtocol = ErrorRecoveryService(
            logger: logger,
            userSession: userSession,
            stateCoordinator: stateCoordinator,
            secureUserDefaults: secureUserDefaults,
            profileRepository: profileRepo,
            validationService: stateValidationService
        )
        
        let systemHealthMonitor: any SystemHealthMonitorProtocol = SystemHealthMonitor(
            userSession: userSession,
            validationService: stateValidationService,
            logger: logger,
            dateProvider: dateProvider
        )
        
        let errorHandlingStrategy: any ErrorHandlingStrategyProtocol = ErrorHandlingStrategy(
            recoveryService: errorRecoveryService,
            validationService: stateValidationService,
            healthMonitor: systemHealthMonitor,
            logger: logger,
            userSession: userSession
        )

        return DefaultAppContainer(
            habitRepository: habitRepo,
            logRepository: logRepo,
            profileRepository: profileRepo,
            tipRepository: tipRepo,
            onboardingRepository: onboardingRepo,
            userAuthRepository: userAuthRepo,
            notificationService: notifications,
            dateProvider: dateProvider,
            streakEngine: streakEngine,
            appearanceManager: appearanceManager,
            habitSuggestionsService: habitSuggestionsService,
            userActionTracker: userActionTracker,
            authenticationService: authService,
            userSession: userSession,
            paywallService: paywallService,
            featureGatingService: featureGatingService,
            stateCoordinator: stateCoordinator,
            secureUserDefaults: secureUserDefaults,
            stateValidationService: stateValidationService,
            errorRecoveryService: errorRecoveryService,
            systemHealthMonitor: systemHealthMonitor,
            errorHandlingStrategy: errorHandlingStrategy,
            refreshTrigger: refreshTrigger,
            slogansService: SlogansService(dateProvider: dateProvider)
        )
    }
}
