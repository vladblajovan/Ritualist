import Foundation
import UserNotifications
import FactoryKit
import RitualistCore

// MARK: - User Profile Enums

public enum UserGender: String, CaseIterable, Identifiable {
    case preferNotToSay = "prefer_not_to_say"
    case male = "male"
    case female = "female"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .preferNotToSay: return "Prefer not to say"
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

public enum UserAgeGroup: String, CaseIterable, Identifiable {
    case preferNotToSay = "prefer_not_to_say"
    case under18 = "under_18"
    case age18to24 = "18_24"
    case age25to34 = "25_34"
    case age35to44 = "35_44"
    case age45to54 = "45_54"
    case age55plus = "55_plus"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .preferNotToSay: return "Prefer not to say"
        case .under18: return "Under 18"
        case .age18to24: return "18-24"
        case .age25to34: return "25-34"
        case .age35to44: return "35-44"
        case .age45to54: return "45-54"
        case .age55plus: return "55+"
        }
    }
}

@MainActor
@Observable
public final class OnboardingViewModel {
    // Use cases
    private let getOnboardingState: GetOnboardingState
    private let saveOnboardingState: SaveOnboardingState
    private let completeOnboarding: CompleteOnboarding
    private let requestNotificationPermission: RequestNotificationPermissionUseCase
    private let checkNotificationStatus: CheckNotificationStatusUseCase
    private let requestLocationPermissions: RequestLocationPermissionsUseCase
    private let getLocationAuthStatus: GetLocationAuthStatusUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.debugLogger) var logger
    @ObservationIgnored @Injected(\.dailyNotificationScheduler) var dailyNotificationScheduler
    @ObservationIgnored @Injected(\.restoreGeofenceMonitoring) var restoreGeofenceMonitoring

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
    public static let maxNameLength = 50
    public let totalPages = 6
    
    public init(getOnboardingState: GetOnboardingState,
                saveOnboardingState: SaveOnboardingState,
                completeOnboarding: CompleteOnboarding,
                requestNotificationPermission: RequestNotificationPermissionUseCase,
                checkNotificationStatus: CheckNotificationStatusUseCase,
                requestLocationPermissions: RequestLocationPermissionsUseCase,
                getLocationAuthStatus: GetLocationAuthStatusUseCase) {
        self.getOnboardingState = getOnboardingState
        self.saveOnboardingState = saveOnboardingState
        self.completeOnboarding = completeOnboarding
        self.requestNotificationPermission = requestNotificationPermission
        self.checkNotificationStatus = checkNotificationStatus
        self.requestLocationPermissions = requestLocationPermissions
        self.getLocationAuthStatus = getLocationAuthStatus
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
        // Check current permission status (for when page loads with existing permissions)
        // Use async let for parallel execution to improve performance
        async let notificationStatus = checkNotificationStatus.execute()
        async let locationStatus = getLocationAuthStatus.execute()

        hasGrantedNotifications = await notificationStatus
        let location = await locationStatus
        hasGrantedLocation = (location == .authorizedAlways || location == .authorizedWhenInUse)
    }

    public func requestNotificationPermission() async {
        // Track permission request
        userActionTracker.track(.onboardingNotificationPermissionRequested)

        do {
            let granted = try await requestNotificationPermission.execute()
            hasGrantedNotifications = granted

            // Track permission result
            if granted {
                userActionTracker.track(.onboardingNotificationPermissionGranted)

                // CRITICAL: If permission was just granted, schedule notifications for any existing habits
                // This handles the case where user created habits before granting notification permission
                logger.log(
                    "📅 Scheduling notifications after onboarding permission granted",
                    level: .info,
                    category: .notifications
                )
                try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
            } else {
                userActionTracker.track(.onboardingNotificationPermissionDenied)
            }
        } catch {
            logger.log(
                "Failed to request notification permission",
                level: .error,
                category: .notifications,
                metadata: ["error": error.localizedDescription]
            )
            errorMessage = "Failed to request notification permission"
            hasGrantedNotifications = false
            // Track as failed (not denied) - these are different scenarios
            userActionTracker.track(.onboardingNotificationPermissionFailed)
        }
    }

    public func requestLocationPermission() async {
        // Track permission request
        userActionTracker.track(.onboardingLocationPermissionRequested)

        // Request "When In Use" permission during onboarding.
        // If user later enables location-based habits, they'll be prompted to upgrade
        // to "Always" permission in the habit detail screen (progressive permission flow).
        _ = await requestLocationPermissions.execute(requestAlways: false)

        // Check status after request
        let locationStatus = await getLocationAuthStatus.execute()
        hasGrantedLocation = (locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse)

        // Track permission result
        if hasGrantedLocation {
            userActionTracker.track(.onboardingLocationPermissionGranted(status: String(describing: locationStatus)))

            // CRITICAL: If permission was just granted, restore geofences for any existing habits
            // This handles the case where user created location-based habits before granting permission
            logger.log(
                "🌍 Restoring geofences after onboarding location permission granted",
                level: .info,
                category: .location
            )
            do {
                try await restoreGeofenceMonitoring.execute()
            } catch {
                logger.log(
                    "Failed to restore geofences after onboarding location permission granted",
                    level: .error,
                    category: .location,
                    metadata: ["error": error.localizedDescription]
                )
                userActionTracker.track(.onboardingLocationPermissionFailed)
            }
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
            // Complete onboarding without setting user data
            try await completeOnboarding.execute(
                userName: "",
                hasNotifications: false,
                hasLocation: false,
                gender: nil,
                ageGroup: nil
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
    
    public func dismissError() {
        errorMessage = nil
    }
    
    // MARK: - Private Helpers
    
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
