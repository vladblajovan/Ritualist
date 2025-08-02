import Foundation

public struct SettingsFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }
    @MainActor public func makeViewModel() -> SettingsViewModel {
        let loadProfile = LoadProfile(repo: container.profileRepository)
        let saveProfile = SaveProfile(repo: container.profileRepository)
        let requestNotificationPermission = RequestNotificationPermission(notificationService: container.notificationService)
        let checkNotificationStatus = CheckNotificationStatus(notificationService: container.notificationService)
        
        return SettingsViewModel(
            loadProfile: loadProfile,
            saveProfile: saveProfile,
            requestNotificationPermission: requestNotificationPermission,
            checkNotificationStatus: checkNotificationStatus,
            userService: container.userService,
            appContainer: container
        )
    }
}
