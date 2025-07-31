import Foundation
import Observation
import Combine

@MainActor @Observable
public final class SettingsViewModel {
    private let loadProfile: LoadProfileUseCase
    private let saveProfile: SaveProfileUseCase
    private let updateUser: UpdateUserUseCase
    private let notificationService: NotificationService
    private let userSession: any UserSessionProtocol
    private let appContainer: AppContainer
    private var cancellables = Set<AnyCancellable>()

    public var profile = UserProfile()
    public private(set) var isLoading = false
    public private(set) var isSaving = false
    public private(set) var error: Error?
    public private(set) var saveSuccess = false
    public private(set) var autoSaveMessage: String?
    public private(set) var hasNotificationPermission = false
    public private(set) var isRequestingNotifications = false
    public private(set) var isLoggingOut = false
    public private(set) var isUpdatingUser = false
    public private(set) var isCancellingSubscription = false
    
    // Reactive properties to track user session state
    public private(set) var currentUser: User?
    public private(set) var isAuthenticated = false
    public private(set) var isPremiumUser = false

    public init(loadProfile: LoadProfileUseCase, saveProfile: SaveProfileUseCase, updateUser: UpdateUserUseCase, notificationService: NotificationService, userSession: any UserSessionProtocol, appContainer: AppContainer) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.updateUser = updateUser
        self.notificationService = notificationService
        self.userSession = userSession
        self.appContainer = appContainer
        
        // Initialize current state
        updateUserSessionState()
        
        // Observe user session changes
        setupUserSessionObservation()
    }
    
    // MARK: - User Session Observation
    
    private func setupUserSessionObservation() {
        // Cast to concrete UserSession type to access objectWillChange
        if let concreteSession = userSession as? UserSession {
            concreteSession.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateUserSessionState()
                }
                .store(in: &cancellables)
        }
    }
    
    private func updateUserSessionState() {
        currentUser = userSession.currentUser
        isAuthenticated = userSession.isAuthenticated  
        isPremiumUser = userSession.isPremiumUser
    }
    
    public func load() async {
        isLoading = true
        error = nil
        do {
            profile = try await loadProfile.execute()
            hasNotificationPermission = await notificationService.checkAuthorizationStatus()
            // Update user session state after loading
            updateUserSessionState()
        } catch {
            self.error = error
            profile = UserProfile()
            hasNotificationPermission = await notificationService.checkAuthorizationStatus()
            // Update user session state even on error
            updateUserSessionState()
        }
        isLoading = false
    }

    public func save() async -> Bool {
        isSaving = true
        error = nil
        saveSuccess = false
        
        do {
            try await saveProfile.execute(profile)
            saveSuccess = true
            
            // Send notification after successful save
            // try? await notificationService.sendImmediate(
            //     title: "Settings Saved",
            //     body: "Your preferences have been updated successfully."
            // )
            
            isSaving = false
            return true
        } catch {
            self.error = error
            isSaving = false
            return false
        }
    }

    public func retry() async {
        await load()
    }

    public func clearSaveSuccess() {
        saveSuccess = false
    }

    public func autoSave() async {
        // Don't auto-save if already saving or loading
        guard !isSaving && !isLoading else { return }

        error = nil
        autoSaveMessage = nil

        do {
            try await saveProfile.execute(profile)
            autoSaveMessage = "Settings saved"
            
            // Send notification after successful auto-save
            // try? await notificationService.sendImmediate(
            //     title: "Settings Auto-Saved",
            //     body: "Your preferences have been automatically updated."
            // )

            // Auto-dismiss message after 3 seconds
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if autoSaveMessage == "Settings saved" {
                        autoSaveMessage = nil
                    }
                }
            }
        } catch {
            self.error = error
        }
    }
    
    public func dismissAutoSaveMessage() {
        autoSaveMessage = nil
    }
    
    public func requestNotificationPermission() async {
        isRequestingNotifications = true
        error = nil
        
        do {
            let granted = try await notificationService.requestAuthorizationIfNeeded()
            hasNotificationPermission = granted
        } catch {
            self.error = error
            hasNotificationPermission = await notificationService.checkAuthorizationStatus()
        }
        
        isRequestingNotifications = false
    }
    
    public func refreshNotificationStatus() async {
        hasNotificationPermission = await notificationService.checkAuthorizationStatus()
    }
    
    // MARK: - Authentication Methods
    
    public func signOut() async {
        isLoggingOut = true
        error = nil
        
        do {
            try await userSession.signOut()
        } catch {
            self.error = error
        }
        
        isLoggingOut = false
    }
    
    public func updateUserName(_ name: String) async {
        guard let currentUser = userSession.currentUser else { return }
        
        isUpdatingUser = true
        error = nil
        
        var updatedUser = currentUser
        updatedUser.name = name
        
        do {
            _ = try await updateUser.execute(updatedUser)
            // The updated user will be reflected automatically through userSession
        } catch {
            self.error = error
        }
        
        isUpdatingUser = false
    }
    
    public func cancelSubscription() async {
        guard let currentUser = userSession.currentUser else { return }
        
        isCancellingSubscription = true
        error = nil
        
        var updatedUser = currentUser
        updatedUser.subscriptionPlan = .free
        updatedUser.subscriptionExpiryDate = nil
        
        do {
            _ = try await updateUser.execute(updatedUser)
            // The updated user will be reflected automatically through userSession
            
            // Clear any stored purchases from the paywall service
            appContainer.paywallService.clearPurchases()
        } catch {
            self.error = error
        }
        
        isCancellingSubscription = false
    }
}
