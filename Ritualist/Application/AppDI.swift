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
                featureGatingService: FeatureGatingService) {
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
    }

    // Bootstrap with SwiftData and default services (async version)
    public static func bootstrap() async -> DefaultAppContainer {
        let stack = try? SwiftDataStack()
        let dateProvider = SystemDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: dateProvider)

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
        let paywallService: PaywallService = await MockPaywallService()
        let featureGatingService: FeatureGatingService = DefaultFeatureGatingService(userSession: userSession)

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
            featureGatingService: featureGatingService
        )
    }
    
    // Synchronous bootstrap for environment defaults
    @MainActor
    public static func bootstrapSync(userSession: any UserSessionProtocol) -> DefaultAppContainer {
        let stack = try? SwiftDataStack()
        let dateProvider = SystemDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: dateProvider)

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
            featureGatingService: featureGatingService
        )
    }
    
    // Minimal container for environment defaults - creates non-async services
    public static func createMinimal() -> DefaultAppContainer {
        // This is a simplified version for environment defaults only
        // Real app should use the async bootstrap method
        let stack = try? SwiftDataStack()
        let dateProvider = SystemDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: dateProvider)

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
            featureGatingService: featureGatingService
        )
    }
}
