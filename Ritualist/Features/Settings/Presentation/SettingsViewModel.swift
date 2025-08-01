import Foundation
import Observation

@MainActor @Observable
public final class SettingsViewModel {
    private let loadProfile: LoadProfileUseCase
    private let saveProfile: SaveProfileUseCase
    private let updateUser: UpdateUserUseCase
    private let requestNotificationPermission: RequestNotificationPermissionUseCase
    private let checkNotificationStatus: CheckNotificationStatusUseCase
    private let signOutUser: SignOutUserUseCase
    private let userSession: any UserSessionProtocol
    private let appContainer: AppContainer

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
    public var currentUser: User? {
        userSession.currentUser
    }
    
    public var isAuthenticated: Bool {
        userSession.isAuthenticated
    }
    
    public var isPremiumUser: Bool {
        userSession.isPremiumUser
    }

    public init(loadProfile: LoadProfileUseCase, 
                saveProfile: SaveProfileUseCase, 
                updateUser: UpdateUserUseCase, 
                requestNotificationPermission: RequestNotificationPermissionUseCase,
                checkNotificationStatus: CheckNotificationStatusUseCase,
                signOutUser: SignOutUserUseCase,
                userSession: any UserSessionProtocol, 
                appContainer: AppContainer) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.updateUser = updateUser
        self.requestNotificationPermission = requestNotificationPermission
        self.checkNotificationStatus = checkNotificationStatus
        self.signOutUser = signOutUser
        self.userSession = userSession
        self.appContainer = appContainer
        
        // With @Observable UserSession, no manual setup needed
    }
    
    
    public func load() async {
        isLoading = true
        error = nil
        do {
            profile = try await loadProfile.execute()
            hasNotificationPermission = await checkNotificationStatus.execute()
        } catch {
            self.error = error
            profile = UserProfile()
            hasNotificationPermission = await checkNotificationStatus.execute()
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
    
    public func requestNotifications() async {
        isRequestingNotifications = true
        error = nil
        
        do {
            let granted = try await requestNotificationPermission.execute()
            hasNotificationPermission = granted
        } catch {
            self.error = error
            hasNotificationPermission = await checkNotificationStatus.execute()
        }
        
        isRequestingNotifications = false
    }
    
    public func refreshNotificationStatus() async {
        hasNotificationPermission = await checkNotificationStatus.execute()
    }
    
    // MARK: - Authentication Methods
    
    public func signOut() async {
        isLoggingOut = true
        error = nil
        
        do {
            try await signOutUser.execute()
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
        updatedUser.subscriptionPlan = SubscriptionPlan.free
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
