import Foundation

// MARK: - Service-Based Use Case Implementations

// MARK: - Slogan Use Case
public final class GetCurrentSlogan: GetCurrentSloganUseCase {
    private let slogansService: SlogansServiceProtocol

    public init(slogansService: SlogansServiceProtocol) {
        self.slogansService = slogansService
    }

    public func execute() -> String {
        slogansService.getCurrentSlogan()
    }

    public func getUniqueSlogans(count: Int, for timeOfDay: TimeOfDay) -> [String] {
        slogansService.getUniqueSlogans(count: count, for: timeOfDay)
    }
}

// MARK: - Notification Use Cases
public final class RequestNotificationPermission: RequestNotificationPermissionUseCase {
    private let notificationService: NotificationService
    
    public init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    public func execute() async throws -> Bool {
        try await notificationService.requestAuthorizationIfNeeded()
    }
}

public final class CheckNotificationStatus: CheckNotificationStatusUseCase {
    private let notificationService: NotificationService
    
    public init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    public func execute() async -> Bool {
        await notificationService.checkAuthorizationStatus()
    }
}

// MARK: - Feature Gating Use Cases
public final class CheckFeatureAccess: CheckFeatureAccessUseCase {
    private let featureGatingService: FeatureGatingService
    
    public init(featureGatingService: FeatureGatingService) {
        self.featureGatingService = featureGatingService
    }
    
    public func execute() -> Bool {
        featureGatingService.hasAdvancedAnalytics
    }
}

public final class CheckHabitCreationLimit: CheckHabitCreationLimitUseCase {
    private let featureGatingService: FeatureGatingService

    public init(featureGatingService: FeatureGatingService) {
        self.featureGatingService = featureGatingService
    }

    public func execute(currentCount: Int) -> Bool {
        return featureGatingService.canCreateMoreHabits(currentCount: currentCount)
    }
}

public final class GetPaywallMessage: GetPaywallMessageUseCase {
    private let featureGatingService: FeatureGatingService
    
    public init(featureGatingService: FeatureGatingService) {
        self.featureGatingService = featureGatingService
    }
    
    public func execute() -> String {
        featureGatingService.getFeatureBlockedMessage(for: .advancedAnalytics)
    }
}

// MARK: - User Action Use Cases
public final class TrackUserAction: TrackUserActionUseCase {
    private let userActionTracker: UserActionTrackerService
    
    public init(userActionTracker: UserActionTrackerService) {
        self.userActionTracker = userActionTracker
    }
    
    public func execute(action: UserActionEvent, context: [String: String]) {
        userActionTracker.track(action, context: context)
    }
}

public final class TrackHabitLogged: TrackHabitLoggedUseCase {
    private let userActionTracker: UserActionTrackerService
    
    public init(userActionTracker: UserActionTrackerService) {
        self.userActionTracker = userActionTracker
    }
    
    public func execute(habitId: String, habitName: String, date: Date, logType: String, value: Double?) {
        userActionTracker.track(.habitLogged(
            habitId: habitId,
            habitName: habitName,
            date: date,
            logType: logType,
            value: value
        ))
    }
}