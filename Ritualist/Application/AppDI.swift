import Foundation
import SwiftData

// MARK: - Default DI Container

public final class DefaultAppContainer: AppContainer {
    public let habitRepository: HabitRepository
    public let logRepository: LogRepository
    public let profileRepository: ProfileRepository
    public let tipRepository: TipRepository
    public let onboardingRepository: OnboardingRepository
    public let categoryRepository: CategoryRepository
    public let notificationService: NotificationService
    public let appearanceManager: AppearanceManager
    public let habitSuggestionsService: HabitSuggestionsService
    public let userActionTracker: UserActionTrackerService
    public let userService: UserService
    public let paywallService: PaywallService
    public let featureGatingService: FeatureGatingService
    public let slogansService: SlogansServiceProtocol
    
    // Domain UseCases
    public lazy var createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase = {
        let createHabit = CreateHabit(repo: habitRepository)
        let getHabitCount = GetHabitCount(habitRepository: habitRepository)
        let checkHabitCreationLimit = CheckHabitCreationLimit(featureGatingService: featureGatingService)
        
        return CreateHabitFromSuggestion(
            createHabit: createHabit,
            getHabitCount: getHabitCount,
            checkHabitCreationLimit: checkHabitCreationLimit,
            featureGatingService: featureGatingService
        )
    }()
    
    // Shared ViewModels
    @MainActor
    public var habitsAssistantViewModel: HabitsAssistantViewModel {
        habitsAssistantFactory.makeViewModel()
    }
    
    // Feature factories
    public lazy var onboardingFactory = OnboardingFactory(container: self)
    public lazy var habitDetailFactory = HabitDetailFactory(container: self)
    public lazy var paywallFactory = PaywallFactory(container: self)
    public lazy var habitsAssistantFactory = HabitsAssistantFactory(container: self)

    public init(habitRepository: HabitRepository,
                logRepository: LogRepository,
                profileRepository: ProfileRepository,
                tipRepository: TipRepository,
                onboardingRepository: OnboardingRepository,
                categoryRepository: CategoryRepository,
                notificationService: NotificationService,
                appearanceManager: AppearanceManager,
                habitSuggestionsService: HabitSuggestionsService,
                userActionTracker: UserActionTrackerService,
                userService: UserService,
                paywallService: PaywallService,
                featureGatingService: FeatureGatingService,
                slogansService: SlogansServiceProtocol) {
        self.habitRepository = habitRepository
        self.logRepository = logRepository
        self.profileRepository = profileRepository
        self.tipRepository = tipRepository
        self.onboardingRepository = onboardingRepository
        self.categoryRepository = categoryRepository
        self.notificationService = notificationService
        self.appearanceManager = appearanceManager
        self.habitSuggestionsService = habitSuggestionsService
        self.userActionTracker = userActionTracker
        self.userService = userService
        self.paywallService = paywallService
        self.featureGatingService = featureGatingService
        self.slogansService = slogansService
    }

    // Bootstrap with SwiftData and default services (async version)
    @MainActor
    public static func bootstrap() async -> DefaultAppContainer {
        let stack = try? SwiftDataStack()

        let habitDS = HabitLocalDataSource(context: stack?.context)
        let logDS   = LogLocalDataSource(context: stack?.context)
        let profileDS = ProfileLocalDataSource(context: stack?.context)
        let tipDS = TipLocalDataSource()
        let onboardingDS = OnboardingLocalDataSource(context: stack?.context)
        let categoryDS = SwiftDataCategoryLocalDataSource(context: stack?.context)

        let habitRepo: HabitRepository = HabitRepositoryImpl(local: habitDS)
        let logRepo: LogRepository = LogRepositoryImpl(local: logDS)
        let profileRepo: ProfileRepository = ProfileRepositoryImpl(local: profileDS)
        let tipRepo: TipRepository = TipRepositoryImpl(local: tipDS)
        let onboardingRepo: OnboardingRepository = OnboardingRepositoryImpl(local: onboardingDS)
        let categoryRepo: CategoryRepository = CategoryRepositoryImpl(local: categoryDS)
        let notifications: NotificationService = LocalNotificationService()
        let appearanceManager = AppearanceManager()
        let habitSuggestionsService: HabitSuggestionsService = DefaultHabitSuggestionsService()
        
        // Use DebugUserActionTracker in development, NoOpUserActionTracker in production
        // You can easily swap this with your preferred analytics provider later
        #if DEBUG
        let userActionTracker: UserActionTrackerService = DebugUserActionTrackerService()
        #else
        let userActionTracker: UserActionTrackerService = NoOpUserActionTrackerService()
        #endif
        
        // User services - use mock in debug, can be swapped for production
        #if DEBUG
        let userService: UserService = MockUserService()
        #else
        // TODO: Replace with iCloudUserService when implemented
        let userService: UserService = ICloudUserService()
        #endif
        
        // Paywall services - configured for optimal development experience
        #if DEBUG
        // Use enhanced mock with realistic testing scenarios
        let mockPaywall = MockPaywallService(testingScenario: .randomResults)
        mockPaywall.configure(scenario: .randomResults, delay: 1.5, failureRate: 0.15) // 85% success rate, faster for development
        let paywallService: PaywallService = mockPaywall
        #else
        // Production - StoreKit integration stub
        let paywallService: PaywallService = StoreKitPaywallService()
        #endif
        
        // Feature gating service - conditional based on build configuration
        let featureGatingService: FeatureGatingService = {
            #if ALL_FEATURES_ENABLED
            // All features enabled - use mock service that grants everything
            return MockFeatureGatingService()
            #else
            // Subscription-based gating - use build config aware service with standard logic
            return BuildConfigFeatureGatingService.create(userService: userService)
            #endif
        }()
        
        // State coordination services
        
        // Phase 2: Reliability services
        let logger = DebugLogger(subsystem: "com.ritualist.app", category: "system")

        return DefaultAppContainer(
            habitRepository: habitRepo,
            logRepository: logRepo,
            profileRepository: profileRepo,
            tipRepository: tipRepo,
            onboardingRepository: onboardingRepo,
            categoryRepository: categoryRepo,
            notificationService: notifications,
            appearanceManager: appearanceManager,
            habitSuggestionsService: habitSuggestionsService,
            userActionTracker: userActionTracker,
            userService: userService,
            paywallService: paywallService,
            featureGatingService: featureGatingService,
            slogansService: SlogansService()
        )
    }
    
    // Minimal container for environment defaults - creates non-async services
    @MainActor
    public static func createMinimal() -> DefaultAppContainer {
        // This is a simplified version for environment defaults only
        // Real app should use the async bootstrap method
        let stack = try? SwiftDataStack()

        let habitDS = HabitLocalDataSource(context: stack?.context)
        let logDS   = LogLocalDataSource(context: stack?.context)
        let profileDS = ProfileLocalDataSource(context: stack?.context)
        let tipDS = TipLocalDataSource()
        let onboardingDS = OnboardingLocalDataSource(context: stack?.context)
        let categoryDS = SwiftDataCategoryLocalDataSource(context: stack?.context)

        let habitRepo: HabitRepository = HabitRepositoryImpl(local: habitDS)
        let logRepo: LogRepository = LogRepositoryImpl(local: logDS)
        let profileRepo: ProfileRepository = ProfileRepositoryImpl(local: profileDS)
        let tipRepo: TipRepository = TipRepositoryImpl(local: tipDS)
        let onboardingRepo: OnboardingRepository = OnboardingRepositoryImpl(local: onboardingDS)
        let categoryRepo: CategoryRepository = CategoryRepositoryImpl(local: categoryDS)
        let notifications: NotificationService = LocalNotificationService()
        let appearanceManager = AppearanceManager()
        let habitSuggestionsService: HabitSuggestionsService = DefaultHabitSuggestionsService()
        
        #if DEBUG
        let userActionTracker: UserActionTrackerService = DebugUserActionTrackerService()
        #else
        let userActionTracker: UserActionTrackerService = NoOpUserActionTrackerService()
        #endif
        
        // Create minimal user service
        // For minimal container used in previews, we use nonisolated implementations
        let userService: UserService = NoOpUserService()
        
        // Paywall services - use mock for minimal container
        let paywallService: PaywallService = SimplePaywallService()
        
        // Feature gating service - conditional based on build configuration (minimal container)
        let featureGatingService: FeatureGatingService = {
            #if ALL_FEATURES_ENABLED
            // All features enabled - use mock service that grants everything
            return MockFeatureGatingService()
            #else
            // Subscription-based gating - use build config aware service
            return BuildConfigFeatureGatingService.create(userService: userService)
            #endif
        }()
        
        // State coordination services - use NoOp for minimal container
        
        // Minimal Phase 2 services for createMinimal - use simplified versions
        let logger = DebugLogger()  
        
        return DefaultAppContainer(
            habitRepository: habitRepo,
            logRepository: logRepo,
            profileRepository: profileRepo,
            tipRepository: tipRepo,
            onboardingRepository: onboardingRepo,
            categoryRepository: categoryRepo,
            notificationService: notifications,
            appearanceManager: appearanceManager,
            habitSuggestionsService: habitSuggestionsService,
            userActionTracker: userActionTracker,
            userService: userService,
            paywallService: paywallService,
            featureGatingService: featureGatingService,
            slogansService: SlogansService()
        )
    }
}
