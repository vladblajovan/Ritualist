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
    private let requestNotificationPermission: RequestNotificationPermissionUseCase
    private let checkNotificationStatus: CheckNotificationStatusUseCase
    private let requestLocationPermissions: RequestLocationPermissionsUseCase
    private let getLocationAuthStatus: GetLocationAuthStatusUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker

    // Current state
    public var currentPage: Int = 0
    public var userName: String = ""
    public var hasGrantedNotifications: Bool = false
    public var hasGrantedLocation: Bool = false
    public var isCompleted: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    // Constants
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
        hasGrantedNotifications = await checkNotificationStatus.execute()
        let locationStatus = await getLocationAuthStatus.execute()
        hasGrantedLocation = (locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse)
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
            } else {
                userActionTracker.track(.onboardingNotificationPermissionDenied)
            }
        } catch {
            errorMessage = "Failed to request notification permission"
            hasGrantedNotifications = false
            userActionTracker.track(.onboardingNotificationPermissionDenied)
        }
    }

    public func requestLocationPermission() async {
        // Track permission request
        userActionTracker.track(.onboardingLocationPermissionRequested)

        // Request "When In Use" permission (requestAlways: false) for location-aware habits
        _ = await requestLocationPermissions.execute(requestAlways: false)

        // Check status after request
        let locationStatus = await getLocationAuthStatus.execute()
        hasGrantedLocation = (locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse)

        // Track permission result
        if hasGrantedLocation {
            userActionTracker.track(.onboardingLocationPermissionGranted(status: String(describing: locationStatus)))
        } else {
            userActionTracker.track(.onboardingLocationPermissionDenied)
        }
    }
    
    public func finishOnboarding() async -> Bool {
        isLoading = true
        do {
            try await completeOnboarding.execute(userName: userName.isEmpty ? nil : userName, 
                                               hasNotifications: hasGrantedNotifications)
            isCompleted = true
            
            // Track onboarding completion
            userActionTracker.track(.onboardingCompleted)
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to complete onboarding"
            isLoading = false
            return false
        }
    }
    
    #if DEBUG
    /// Skip onboarding entirely - debug builds only
    public func skipOnboarding() async -> Bool {
        print("[DEBUG] skipOnboarding() called")
        isLoading = true
        do {
            print("[DEBUG] About to call completeOnboarding.execute")
            // Complete onboarding with debug user name and no notifications
            try await completeOnboarding.execute(userName: "Debug User", hasNotifications: false)
            print("[DEBUG] completeOnboarding.execute succeeded")
            isCompleted = true
            print("[DEBUG] Set isCompleted = true")
            
            // Track as skipped for debug metrics
            userActionTracker.track(.onboardingCompleted)
            print("[DEBUG] Tracked onboarding completion")
            
            isLoading = false
            print("[DEBUG] Skip onboarding completed successfully")
            return true
        } catch {
            print("[DEBUG] Skip onboarding failed with error: \(error)")
            errorMessage = "Failed to skip onboarding"
            isLoading = false
            return false
        }
    }
    #endif
    
    public var canProceedFromCurrentPage: Bool {
        switch currentPage {
        case 0: // Name input page
            return !userName.isEmpty
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
