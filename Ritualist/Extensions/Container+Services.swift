import Foundation
import FactoryKit

// MARK: - Services Container Extensions

extension Container {
    
    // MARK: - Core Services
    
    var notificationService: Factory<NotificationService> {
        self { LocalNotificationService() }
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
    
    // UserService requires MainActor isolation
    @MainActor
    var userService: Factory<UserService> {
        self { @MainActor in
            #if DEBUG
            return MockUserService()
            #else
            return ICloudUserService()
            #endif
        }
        .singleton
    }
    
    // MARK: - Paywall Service
    
    // PaywallService requires MainActor isolation
    @MainActor
    var paywallService: Factory<PaywallService> {
        self { @MainActor in
            #if DEBUG
            let mockPaywall = MockPaywallService(testingScenario: .randomResults)
            mockPaywall.configure(scenario: .randomResults, delay: 1.5, failureRate: 0.15)
            return mockPaywall
            #else
            return StoreKitPaywallService()
            #endif
        }
        .singleton
    }
    
    // MARK: - Feature Gating Service
    
    @MainActor
    var featureGatingService: Factory<FeatureGatingService> {
        self { @MainActor in
            #if ALL_FEATURES_ENABLED
            return MockFeatureGatingService()
            #else
            return BuildConfigFeatureGatingService.create(userService: self.userService())
            #endif
        }
        .singleton
    }
}