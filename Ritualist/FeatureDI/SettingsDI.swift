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
    
    public func makeCategoryManagementViewModel() -> CategoryManagementViewModel {
        let getAllCategories = GetAllCategories(repo: container.categoryRepository)
        let createCustomCategory = CreateCustomCategory(repo: container.categoryRepository)
        let updateCategory = UpdateCategory(repo: container.categoryRepository)
        let deleteCategory = DeleteCategory(repo: container.categoryRepository)
        let getHabitsByCategory = GetHabitsByCategory(repo: container.habitRepository)
        let orphanHabitsFromCategory = OrphanHabitsFromCategory(repo: container.habitRepository)
        
        return CategoryManagementViewModel(
            getAllCategoriesUseCase: getAllCategories,
            createCustomCategoryUseCase: createCustomCategory,
            updateCategoryUseCase: updateCategory,
            deleteCategoryUseCase: deleteCategory,
            getHabitsByCategoryUseCase: getHabitsByCategory,
            orphanHabitsFromCategoryUseCase: orphanHabitsFromCategory
        )
    }
}
