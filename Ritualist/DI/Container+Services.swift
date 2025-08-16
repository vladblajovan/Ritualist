import Foundation
import FactoryKit
import RitualistCore

// MARK: - Services Container Extensions

extension Container {
    
    // MARK: - Core Services
    
    var errorHandlingActor: Factory<ErrorHandlingActor> {
        self { 
            ErrorHandlingActor(maxLogSize: 1000, analyticsEnabled: true)
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
            let service = LocalNotificationService(errorHandler: self.errorHandlingActor())
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
                            let habits = try await self.habitRepository().fetchAllHabits()
                            if let habit = habits.first(where: { $0.id == habitId }) {
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
        self { AppearanceManager() }
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
    
    var scheduleAwareCompletionCalculator: Factory<ScheduleAwareCompletionCalculator> {
        self { DefaultScheduleAwareCompletionCalculator() }
            .singleton
    }
    
    // MARK: - User & Analytics Services
    
    var userActionTracker: Factory<UserActionTrackerService> {
        self {
            #if DEBUG
            return DebugUserActionTrackerService()
            #else
            return NoOpUserActionTrackerService()
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
                errorHandler: self.errorHandlingActor()
            )
            #else
            return ICloudUserBusinessService(errorHandler: self.errorHandlingActor())
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
                errorHandler: self.errorHandlingActor()
            )
            #else
            return ICloudUserService(errorHandler: self.errorHandlingActor())
            #endif
        }
        .singleton
    }
    
    // MARK: - Subscription Service
    
    var secureSubscriptionService: Factory<SecureSubscriptionService> {
        self { MockSecureSubscriptionService(errorHandler: self.errorHandlingActor()) }
        .singleton
    }
    
    // MARK: - Paywall Business Service
    
    var paywallBusinessService: Factory<PaywallBusinessService> {
        self {
            #if DEBUG
            let mockBusiness = MockPaywallBusinessService(
                subscriptionService: self.secureSubscriptionService(),
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
            return StoreKitPaywallService()
            #endif
        }
        .singleton
    }
    
    // MARK: - Feature Gating Service
    
    // MARK: - Feature Gating Business Service
    
    var featureGatingBusinessService: Factory<FeatureGatingBusinessService> {
        self {
            #if ALL_FEATURES_ENABLED
            return MockFeatureGatingBusinessService(errorHandler: self.errorHandlingActor())
            #else
            return BuildConfigFeatureGatingBusinessService.create(
                userService: self.userService(),
                errorHandler: self.errorHandlingActor()
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
            return MockFeatureGatingService(errorHandler: self.errorHandlingActor())
            #else
            return BuildConfigFeatureGatingService.create(
                userService: self.userService(),
                errorHandler: self.errorHandlingActor()
            )
            #endif
        }
        .singleton
    }
    
    
    // MARK: - Deep Link Coordination
    
    @MainActor
    var personalityDeepLinkCoordinator: Factory<PersonalityDeepLinkCoordinator> {
        self { @MainActor in PersonalityDeepLinkCoordinator.shared }
        .singleton
    }

}
