import Foundation
import UserNotifications

@MainActor
@Observable
public final class OnboardingViewModel {
    // Use cases
    private let getOnboardingState: GetOnboardingState
    private let saveOnboardingState: SaveOnboardingState
    private let completeOnboarding: CompleteOnboarding
    private let requestNotificationPermission: RequestNotificationPermissionUseCase
    private let checkNotificationStatus: CheckNotificationStatusUseCase
    
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
        } catch {
            errorMessage = "Failed to load onboarding state"
        }
        isLoading = false
    }
    
    public func nextPage() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
    }
    
    public func previousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }
    
    public func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        currentPage = page
    }
    
    public func updateUserName(_ name: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func requestNotificationPermission() async {
        do {
            let granted = try await requestNotificationPermission.execute()
            hasGrantedNotifications = granted
        } catch {
            errorMessage = "Failed to request notification permission"
            hasGrantedNotifications = false
        }
    }
    
    public func finishOnboarding() async {
        isLoading = true
        do {
            try await completeOnboarding.execute(userName: userName.isEmpty ? nil : userName, 
                                               hasNotifications: hasGrantedNotifications)
            isCompleted = true
        } catch {
            errorMessage = "Failed to complete onboarding"
        }
        isLoading = false
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
}