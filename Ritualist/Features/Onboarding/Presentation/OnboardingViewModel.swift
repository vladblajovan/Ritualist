import Foundation
import UserNotifications
import FactoryKit

@MainActor
@Observable
public final class OnboardingViewModel {
    // Use cases
    private let getOnboardingState: GetOnboardingState
    private let saveOnboardingState: SaveOnboardingState
    private let completeOnboarding: CompleteOnboarding
    private let requestNotificationPermission: RequestNotificationPermissionUseCase
    private let checkNotificationStatus: CheckNotificationStatusUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    
    // Current state
    public var currentPage: Int = 0
    public var userName: String = ""
    public var hasGrantedNotifications: Bool = false
    public var isCompleted: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    // Constants
    public let totalPages = 5
    
    public init(getOnboardingState: GetOnboardingState,
                saveOnboardingState: SaveOnboardingState,
                completeOnboarding: CompleteOnboarding,
                requestNotificationPermission: RequestNotificationPermissionUseCase,
                checkNotificationStatus: CheckNotificationStatusUseCase) {
        self.getOnboardingState = getOnboardingState
        self.saveOnboardingState = saveOnboardingState
        self.completeOnboarding = completeOnboarding
        self.requestNotificationPermission = requestNotificationPermission
        self.checkNotificationStatus = checkNotificationStatus
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
    
    public var canProceedFromCurrentPage: Bool {
        switch currentPage {
        case 0: // Name input page
            return !userName.isEmpty
        case 4: // Final page - can always proceed to complete
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
        case 1: return "welcome_habits"
        case 2: return "notifications"
        case 3: return "daily_routine"
        case 4: return "get_started"
        default: return "unknown"
        }
    }
}