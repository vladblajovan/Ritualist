import Foundation

public struct SettingsFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }
    @MainActor public func makeViewModel() -> SettingsViewModel {
        let loadProfile = LoadProfile(repo: container.profileRepository)
        let saveProfile = SaveProfile(repo: container.profileRepository)
        let updateUser = UpdateUser(userSession: container.userSession)
        
        return SettingsViewModel(
            loadProfile: loadProfile,
            saveProfile: saveProfile,
            updateUser: updateUser,
            notificationService: container.notificationService,
            userSession: container.userSession,
            appContainer: container
        )
    }
}
