import Foundation
import UserNotifications
import FactoryKit
import RitualistCore

@MainActor
@Observable
public final class OnboardingViewModel {
    // Use cases
    private let getOnboardingState: GetOnboardingState
    private let saveOnboardingState: SaveOnboardingState
    private let completeOnboarding: CompleteOnboarding
    private let permissionCoordinator: PermissionCoordinatorProtocol
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.debugLogger) var logger

    // Current state
    public var currentPage: Int = 0
    public var userName: String = "" {
        didSet {
            // Enforce maximum name length
            if userName.count > Self.maxNameLength {
                userName = String(userName.prefix(Self.maxNameLength))
            }
        }
    }
    public var gender: UserGender = .preferNotToSay
    public var ageGroup: UserAgeGroup = .preferNotToSay

    public var hasGrantedNotifications: Bool = false
    public var hasGrantedLocation: Bool = false
    public var isCompleted: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?

    // Constants
    nonisolated public static let maxNameLength = 50
    public let totalPages = 6

    public init(
        getOnboardingState: GetOnboardingState,
        saveOnboardingState: SaveOnboardingState,
        completeOnboarding: CompleteOnboarding,
        permissionCoordinator: PermissionCoordinatorProtocol
    ) {
        self.getOnboardingState = getOnboardingState
        self.saveOnboardingState = saveOnboardingState
        self.completeOnboarding = completeOnboarding
        self.permissionCoordinator = permissionCoordinator
    }
    
    public func loadOnboardingState() async {
        isLoading = true
        do {
            let state = try await getOnboardingState.execute()
            isCompleted = state.isCompleted
            userName = state.userName ?? ""
            hasGrantedNotifications = state.hasGrantedNotifications
            
            // Track onboarding started if not completed
            if !isCompleted {
                userActionTracker.track(.onboardingStarted)
                userActionTracker.track(.onboardingPageViewed(page: currentPage, pageName: pageNameFor(currentPage)))
            }
        } catch {
            logger.log(
                "Failed to load onboarding state",
                level: .error,
                category: .userAction,
                metadata: ["error": error.localizedDescription]
            )
            errorMessage = "Failed to load onboarding state"
        }
        isLoading = false
    }
    
    public func nextPage() {
        guard currentPage < totalPages - 1 else { return }
        let fromPage = currentPage
        currentPage += 1
        
        // Track page navigation
        userActionTracker.track(.onboardingPageNext(fromPage: fromPage, toPage: currentPage))
        userActionTracker.track(.onboardingPageViewed(page: currentPage, pageName: pageNameFor(currentPage)))
    }
    
    public func previousPage() {
        guard currentPage > 0 else { return }
        let fromPage = currentPage
        currentPage -= 1
        
        // Track page navigation
        userActionTracker.track(.onboardingPageBack(fromPage: fromPage, toPage: currentPage))
        userActionTracker.track(.onboardingPageViewed(page: currentPage, pageName: pageNameFor(currentPage)))
    }
    
    public func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        currentPage = page
    }
    
    public func updateUserName(_ name: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Track user name entry
        userActionTracker.track(.onboardingUserNameEntered(hasName: !userName.isEmpty))
    }
    
    public func checkPermissions() async {
        let permissions = await permissionCoordinator.checkAllPermissions()
        hasGrantedNotifications = permissions.notifications
        hasGrantedLocation = permissions.location.hasAnyAuthorization
    }

    public func requestNotificationPermission() async {
        userActionTracker.track(.onboardingNotificationPermissionRequested)

        let result = await permissionCoordinator.requestNotificationPermission()
        hasGrantedNotifications = result.granted

        if result.granted {
            userActionTracker.track(.onboardingNotificationPermissionGranted)
        } else if result.error != nil {
            errorMessage = "Failed to request notification permission"
            userActionTracker.track(.onboardingNotificationPermissionFailed)
        } else {
            userActionTracker.track(.onboardingNotificationPermissionDenied)
        }
    }

    public func requestLocationPermission() async {
        userActionTracker.track(.onboardingLocationPermissionRequested)

        // Request "Always" permission during onboarding for geofence monitoring
        let result = await permissionCoordinator.requestLocationPermission(requestAlways: true)
        hasGrantedLocation = result.isAuthorized

        if result.isAuthorized {
            userActionTracker.track(.onboardingLocationPermissionGranted(status: String(describing: result.status)))
        } else if result.error != nil {
            userActionTracker.track(.onboardingLocationPermissionFailed)
        } else {
            userActionTracker.track(.onboardingLocationPermissionDenied)
        }
    }
    
    public func finishOnboarding() async -> Bool {
        isLoading = true
        do {
            // Always save gender/ageGroup raw values (including prefer_not_to_say)
            // This distinguishes "user declined" from "never asked" (nil)
            // and prevents infinite prompt loops for returning users
            let genderValue = gender.rawValue
            let ageGroupValue = ageGroup.rawValue

            try await completeOnboarding.execute(
                userName: userName.isEmpty ? nil : userName,
                hasNotifications: hasGrantedNotifications,
                hasLocation: hasGrantedLocation,
                gender: genderValue,
                ageGroup: ageGroupValue
            )
            isCompleted = true

            // Track onboarding completion
            userActionTracker.track(.onboardingCompleted)

            isLoading = false
            return true
        } catch {
            logger.log(
                "Failed to complete onboarding",
                level: .error,
                category: .userAction,
                metadata: [
                    "error": error.localizedDescription,
                    "userName": userName.isEmpty ? "empty" : "provided",
                    "gender": gender.rawValue,
                    "ageGroup": ageGroup.rawValue
                ]
            )
            errorMessage = "Failed to complete onboarding"
            isLoading = false
            return false
        }
    }

    /// Skip onboarding entirely and use defaults
    public func skipOnboarding() async -> Bool {
        logger.log(
            "⏭️ Skip onboarding initiated",
            level: .info,
            category: .userAction
        )
        isLoading = true
        do {
            // Complete onboarding with defaults - use preferNotToSay for demographics
            // This ensures returning user detection always finds complete profile data
            // Pass userName (may be empty) - returning user flow handles missing name gracefully
            try await completeOnboarding.execute(
                userName: userName,
                hasNotifications: false,
                hasLocation: false,
                gender: UserGender.preferNotToSay.rawValue,
                ageGroup: UserAgeGroup.preferNotToSay.rawValue
            )
            isCompleted = true

            // Track as skipped
            userActionTracker.track(.onboardingCompleted)

            isLoading = false
            logger.log(
                "✅ Skip onboarding completed successfully",
                level: .info,
                category: .userAction
            )
            return true
        } catch {
            logger.log(
                "❌ Skip onboarding failed",
                level: .error,
                category: .userAction,
                metadata: ["error": error.localizedDescription]
            )
            errorMessage = "Failed to skip onboarding"
            isLoading = false
            return false
        }
    }
}

// MARK: - Computed Properties

extension OnboardingViewModel {
    public var canProceedFromCurrentPage: Bool {
        switch currentPage {
        case 0: // Name input page - reject empty or whitespace-only names
            return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 5: // Final page - can always proceed to complete
            return true
        default: // Information pages
            return true
        }
    }

    public var isFirstPage: Bool {
        currentPage == 0
    }

    public var isLastPage: Bool {
        currentPage == totalPages - 1
    }
}

// MARK: - State Management

extension OnboardingViewModel {
    public func dismissError() {
        errorMessage = nil
    }

    /// Resets the view model to fresh state.
    /// Call this when user deletes all data or force-resets onboarding.
    public func reset() {
        currentPage = 0
        userName = ""
        gender = .preferNotToSay
        ageGroup = .preferNotToSay
        hasGrantedNotifications = false
        hasGrantedLocation = false
        isCompleted = false
        isLoading = false
        errorMessage = nil
    }
}

// MARK: - Private Helpers

extension OnboardingViewModel {
    private func pageNameFor(_ page: Int) -> String {
        switch page {
        case 0: return "welcome_name"
        case 1: return "track_habits"
        case 2: return "customization"
        case 3: return "tips"
        case 4: return "premium_comparison"
        case 5: return "notifications"
        default: return "unknown"
        }
    }
}
