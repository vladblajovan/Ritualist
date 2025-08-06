import Foundation
import Observation
import FactoryKit

@MainActor @Observable
public final class SettingsViewModel {
    private let loadProfile: LoadProfileUseCase
    private let saveProfile: SaveProfileUseCase
    private let requestNotificationPermission: RequestNotificationPermissionUseCase
    private let checkNotificationStatus: CheckNotificationStatusUseCase
    private let userService: UserService
    @ObservationIgnored @Injected(\.paywallService) var paywallService
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker

    public var profile = UserProfile()
    public private(set) var isLoading = false
    public private(set) var isSaving = false
    public private(set) var error: Error?
    public private(set) var saveSuccess = false
    public private(set) var autoSaveMessage: String?
    public private(set) var hasNotificationPermission = false
    public private(set) var isRequestingNotifications = false
    public private(set) var isCancellingSubscription = false
    public private(set) var isUpdatingUser = false
    
    // Computed properties
    public var isPremiumUser: Bool {
        userService.isPremiumUser
    }

    public init(loadProfile: LoadProfileUseCase, 
                saveProfile: SaveProfileUseCase, 
                requestNotificationPermission: RequestNotificationPermissionUseCase,
                checkNotificationStatus: CheckNotificationStatusUseCase,
                userService: UserService) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.requestNotificationPermission = requestNotificationPermission
        self.checkNotificationStatus = checkNotificationStatus
        self.userService = userService
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
            userActionTracker.trackError(error, context: "settings_load")
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
            
            // Track profile update
            userActionTracker.track(.profileUpdated(field: "general_settings"))
            
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
            userActionTracker.trackError(error, context: "settings_save")
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
            userActionTracker.trackError(error, context: "settings_auto_save")
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
            
            // Track notification settings change
            userActionTracker.track(.notificationSettingsChanged(enabled: granted))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "notification_permission_request")
            hasNotificationPermission = await checkNotificationStatus.execute()
        }
        
        isRequestingNotifications = false
    }
    
    public func refreshNotificationStatus() async {
        hasNotificationPermission = await checkNotificationStatus.execute()
    }
    
    // MARK: - Authentication Methods
    
    // Sign out is no longer needed since there's no authentication
    
    public func updateUserName(_ name: String) async {
        isUpdatingUser = true
        error = nil
        
        // Update both the local profile state and via UserService
        profile.name = name
        profile.updatedAt = Date()
        
        do {
            try await userService.updateProfile(profile)
            // Profile is automatically updated via the single source of truth
            
            // Track user name update
            userActionTracker.track(.profileUpdated(field: "name"))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "user_name_update", additionalProperties: ["name": name])
        }
        
        isUpdatingUser = false
    }
    
    public func cancelSubscription() async {
        isCancellingSubscription = true
        error = nil
        
        do {
            // Cancel subscription through user service
            try await userService.updateSubscription(plan: .free, expiryDate: nil)
            
            // Clear any stored purchases from the paywall service
            paywallService.clearPurchases()
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "subscription_cancellation")
        }
        
        isCancellingSubscription = false
    }
    
    // Method to refresh premium status after purchases
    public func refreshPremiumStatus() {
        // Since UserService is @Observable, accessing isPremiumUser will trigger UI updates
        _ = userService.isPremiumUser
    }
}
