import Foundation
import FactoryKit

// MARK: - ViewModels Container Extensions

extension Container {
    
    // MARK: - Main ViewModels
    
    @MainActor
    var habitsViewModel: Factory<HabitsViewModel> {
        self { @MainActor in
            HabitsViewModel()
        }
        .singleton
    }
    
    @MainActor
    var habitsAssistantViewModel: Factory<HabitsAssistantViewModel> {
        self { @MainActor in
            HabitsAssistantViewModel(
                getPredefinedCategoriesUseCase: self.getPredefinedCategoriesUseCase(),
                getHabitsFromSuggestionsUseCase: self.getHabitsFromSuggestionsUseCase(),
                suggestionsService: self.habitSuggestionsService(),
                userActionTracker: self.userActionTracker()
            )
        }
        .singleton
    }
    
    // MARK: - Parameterized ViewModels (for editing)
    
    @MainActor
    func habitDetailViewModel(for habit: Habit?) -> HabitDetailViewModel {
        HabitDetailViewModel(habit: habit)
    }
    
    @MainActor
    var categoryManagementViewModel: Factory<CategoryManagementViewModel> {
        self { @MainActor in
            CategoryManagementViewModel(
                getAllCategoriesUseCase: self.getAllCategories(),
                createCustomCategoryUseCase: self.createCustomCategory(),
                updateCategoryUseCase: self.updateCategory(),
                deleteCategoryUseCase: self.deleteCategory(),
                getHabitsByCategoryUseCase: self.getHabitsByCategory(),
                orphanHabitsFromCategoryUseCase: self.orphanHabitsFromCategory()
            )
        }
    }
    
    @MainActor
    var overviewViewModel: Factory<OverviewViewModel> {
        self { @MainActor in
            OverviewViewModel(
                getActiveHabits: self.getActiveHabits(),
                getLogs: self.getLogs(),
                getLogForDate: self.getLogForDate(),
                calculateCurrentStreak: self.calculateCurrentStreak(),
                calculateBestStreak: self.calculateBestStreak(),
                loadProfile: self.loadProfile(),
                generateCalendarDays: self.generateCalendarDays(),
                generateCalendarGrid: self.generateCalendarGrid(),
                toggleHabitLog: self.toggleHabitLog(),
                getCurrentSlogan: self.getCurrentSlogan(),
                trackUserAction: self.trackUserAction(),
                trackHabitLogged: self.trackHabitLogged(),
                checkFeatureAccess: self.checkFeatureAccess(),
                checkHabitCreationLimit: self.checkHabitCreationLimit(),
                getPaywallMessage: self.getPaywallMessage(),
                validateHabitSchedule: self.validateHabitSchedule(),
                checkWeeklyTarget: self.checkWeeklyTarget()
            )
        }
        .singleton
    }
    
    @MainActor
    var tipsViewModel: Factory<TipsViewModel> {
        self { @MainActor in
            TipsViewModel(
                getAllTips: self.getAllTips(),
                getFeaturedTips: self.getFeaturedTips(),
                getTipById: self.getTipById(),
                getTipsByCategory: self.getTipsByCategory()
            )
        }
    }
    
    @MainActor
    var paywallViewModel: Factory<PaywallViewModel> {
        self { @MainActor in
            PaywallViewModel(
                loadPaywallProducts: self.loadPaywallProducts(),
                purchaseProduct: self.purchaseProduct(),
                restorePurchases: self.restorePurchases(),
                checkProductPurchased: self.checkProductPurchased(),
                resetPurchaseState: self.resetPurchaseState(),
                getPurchaseState: self.getPurchaseState(),
                updateProfileSubscription: self.updateProfileSubscription(),
                userService: self.userService()
            )
        }
    }
    
    @MainActor
    var settingsViewModel: Factory<SettingsViewModel> {
        self { @MainActor in
            SettingsViewModel(
                loadProfile: self.loadProfile(),
                saveProfile: self.saveProfile(),
                requestNotificationPermission: self.requestNotificationPermission(),
                checkNotificationStatus: self.checkNotificationStatus(),
                userService: self.userService()
            )
        }
        .singleton
    }
    
    @MainActor
    var onboardingViewModel: Factory<OnboardingViewModel> {
        self { @MainActor in
            OnboardingViewModel(
                getOnboardingState: self.getOnboardingState(),
                saveOnboardingState: self.saveOnboardingState(),
                completeOnboarding: self.completeOnboarding(),
                requestNotificationPermission: self.requestNotificationPermission(),
                checkNotificationStatus: self.checkNotificationStatus()
            )
        }
    }
    
    // MARK: - Dashboard ViewModels
    
    @MainActor
    var dashboardViewModel: Factory<DashboardViewModel> {
        self { @MainActor in
            DashboardViewModel()
        }
        .singleton
    }
    
    // MARK: - Personality ViewModels
    
    @MainActor
    var personalityInsightsViewModel: Factory<PersonalityInsightsViewModel> {
        self { @MainActor in
            PersonalityInsightsViewModel(
                analyzePersonalityUseCase: self.analyzePersonalityUseCase(),
                getPersonalityProfileUseCase: self.getPersonalityProfileUseCase(),
                validateAnalysisDataUseCase: self.validateAnalysisDataUseCase(),
                personalityRepository: self.personalityAnalysisRepository(),
                scheduler: self.personalityAnalysisScheduler(),
                loadProfile: self.loadProfile()
            )
        }
        .singleton
    }
}