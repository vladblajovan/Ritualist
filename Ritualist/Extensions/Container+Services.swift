import Foundation
import FactoryKit

// MARK: - Services Container Extensions

extension Container {
    
    // MARK: - Core Services
    
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
            let service = LocalNotificationService()
            service.trackingService = self.userActionTracker()
            
            // Configure the action handler to use dependency injection
            service.actionHandler = { [weak self] action, habitId, habitName, reminderTime in
                guard let self = self else { return }
                try await self.handleNotificationAction().execute(
                    action: action,
                    habitId: habitId,
                    habitName: habitName,
                    reminderTime: reminderTime
                )
                
                // Navigate to Overview page after logging habit
                if action == .log {
                    Task {
                        await MainActor.run {
                            self.navigationService().navigateToOverview(shouldRefresh: true)
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
    
    var userService: Factory<UserService> {
        self {
            #if DEBUG
            return MockUserService(
                loadProfile: self.loadProfile(), 
                saveProfile: self.saveProfile()
            )
            #else
            return ICloudUserService()
            #endif
        }
        .singleton
    }
    
    // MARK: - Subscription Service
    
    var secureSubscriptionService: Factory<SecureSubscriptionService> {
        self { MockSecureSubscriptionService() }
        .singleton
    }
    
    // MARK: - Paywall Service
    
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
    
    var featureGatingService: Factory<FeatureGatingService> {
        self {
            #if ALL_FEATURES_ENABLED
            return MockFeatureGatingService()
            #else
            return BuildConfigFeatureGatingService.create(userService: self.userService())
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
