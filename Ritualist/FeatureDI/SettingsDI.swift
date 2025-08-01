import Foundation

public struct SettingsFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }
    @MainActor public func makeViewModel() -> SettingsViewModel {
        let loadProfile = LoadProfile(repo: container.profileRepository)
        let saveProfile = SaveProfile(repo: container.profileRepository)
        let updateUser = UpdateUser(userSession: container.userSession)
        let requestNotificationPermission = RequestNotificationPermission(notificationService: container.notificationService)
        let checkNotificationStatus = CheckNotificationStatus(notificationService: container.notificationService)
        let signOutUser = SignOutUser(userSession: container.userSession)
        
        return SettingsViewModel(
            loadProfile: loadProfile,
            saveProfile: saveProfile,
            updateUser: updateUser,
            requestNotificationPermission: requestNotificationPermission,
            checkNotificationStatus: checkNotificationStatus,
            signOutUser: signOutUser,
            userSession: container.userSession,
            appContainer: container
        )
    }
}
