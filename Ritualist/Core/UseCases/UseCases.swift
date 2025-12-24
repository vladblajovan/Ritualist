// Re-export all UseCase implementations from RitualistCore
// All UseCase implementations have been moved to RitualistCore package

import Foundation
import RitualistCore
import FactoryKit

// MARK: - Re-export UseCase implementations from RitualistCore
// All implementations are now in RitualistCore/Sources/RitualistCore/UseCases/Implementations/

// Re-export all Core UseCases from RitualistCore
public typealias CreateHabit = RitualistCore.CreateHabit
public typealias GetAllHabits = RitualistCore.GetAllHabits
public typealias UpdateHabit = RitualistCore.UpdateHabit
public typealias DeleteHabit = RitualistCore.DeleteHabit
public typealias ToggleHabitActiveStatus = RitualistCore.ToggleHabitActiveStatus
public typealias ReorderHabits = RitualistCore.ReorderHabits
public typealias ValidateHabitUniqueness = RitualistCore.ValidateHabitUniqueness
public typealias GetHabitsByCategory = RitualistCore.GetHabitsByCategory
public typealias OrphanHabitsFromCategory = RitualistCore.OrphanHabitsFromCategory
public typealias CleanupOrphanedHabits = RitualistCore.CleanupOrphanedHabits
public typealias GetActiveHabits = RitualistCore.GetActiveHabits
public typealias GetHabitCount = RitualistCore.GetHabitCount

// Re-export Log UseCases
public typealias GetLogs = RitualistCore.GetLogs
public typealias GetBatchLogs = RitualistCore.GetBatchLogs
public typealias GetSingleHabitLogs = RitualistCore.GetSingleHabitLogs
public typealias LogHabit = RitualistCore.LogHabit
public typealias DeleteLog = RitualistCore.DeleteLog
public typealias GetLogForDate = RitualistCore.GetLogForDate

// Re-export Profile UseCases
public typealias LoadProfile = RitualistCore.LoadProfile
public typealias SaveProfile = RitualistCore.SaveProfile

// Re-export Tip UseCases
public typealias GetAllTips = RitualistCore.GetAllTips
public typealias GetFeaturedTips = RitualistCore.GetFeaturedTips
public typealias GetTipById = RitualistCore.GetTipById
public typealias GetTipsByCategory = RitualistCore.GetTipsByCategory

// Re-export Category UseCases
public typealias GetAllCategories = RitualistCore.GetAllCategories
public typealias GetCategoryById = RitualistCore.GetCategoryById
public typealias GetActiveCategories = RitualistCore.GetActiveCategories
public typealias GetPredefinedCategories = RitualistCore.GetPredefinedCategories
public typealias GetCustomCategories = RitualistCore.GetCustomCategories
public typealias CreateCustomCategory = RitualistCore.CreateCustomCategory
public typealias UpdateCategory = RitualistCore.UpdateCategory
public typealias DeleteCategory = RitualistCore.DeleteCategory
public typealias ValidateCategoryName = RitualistCore.ValidateCategoryName
public typealias LoadHabitsData = RitualistCore.LoadHabitsData

// Re-export Onboarding UseCases
public typealias GetOnboardingState = RitualistCore.GetOnboardingState
public typealias SaveOnboardingState = RitualistCore.SaveOnboardingState
public typealias CompleteOnboarding = RitualistCore.CompleteOnboarding

// Re-export Calendar UseCases
public typealias GenerateCalendarDays = RitualistCore.GenerateCalendarDays
public typealias GenerateCalendarGrid = RitualistCore.GenerateCalendarGrid

// Re-export Service-based UseCases
public typealias GetCurrentSlogan = RitualistCore.GetCurrentSlogan
public typealias RequestNotificationPermission = RitualistCore.RequestNotificationPermission
public typealias CheckNotificationStatus = RitualistCore.CheckNotificationStatus
public typealias CheckFeatureAccess = RitualistCore.CheckFeatureAccess
public typealias CheckHabitCreationLimit = RitualistCore.CheckHabitCreationLimit
public typealias GetPaywallMessage = RitualistCore.GetPaywallMessage
public typealias TrackUserAction = RitualistCore.TrackUserAction
public typealias TrackHabitLogged = RitualistCore.TrackHabitLogged

// Re-export Paywall UseCases
public typealias LoadPaywallProducts = RitualistCore.LoadPaywallProducts
public typealias PurchaseProduct = RitualistCore.PurchaseProduct
public typealias RestorePurchases = RitualistCore.RestorePurchases
public typealias CheckProductPurchased = RitualistCore.CheckProductPurchased
public typealias ResetPurchaseState = RitualistCore.ResetPurchaseState
public typealias GetPurchaseState = RitualistCore.GetPurchaseState

// Re-export Habit Suggestion UseCases
public typealias CreateHabitFromSuggestion = RitualistCore.CreateHabitFromSuggestion
public typealias RemoveHabitFromSuggestion = RitualistCore.RemoveHabitFromSuggestion

// Re-export User UseCases
public typealias CheckPremiumStatus = RitualistCore.CheckPremiumStatus
public typealias GetCurrentUserProfile = RitualistCore.GetCurrentUserProfile

// Re-export Habit Schedule UseCases
public typealias ValidateHabitSchedule = RitualistCore.ValidateHabitSchedule
public typealias CheckWeeklyTarget = RitualistCore.CheckWeeklyTarget

// Re-export Habit Completion UseCases
public typealias IsHabitCompleted = RitualistCore.IsHabitCompleted
public typealias CalculateDailyProgress = RitualistCore.CalculateDailyProgress
public typealias IsScheduledDay = RitualistCore.IsScheduledDay
public typealias ClearPurchases = RitualistCore.ClearPurchases

// Re-export Analytics UseCases
public typealias CalculateStreakAnalysis = RitualistCore.CalculateStreakAnalysis
public typealias RefreshWidget = RitualistCore.RefreshWidget
public typealias GetHabitLogsForAnalytics = RitualistCore.GetHabitLogsForAnalytics
public typealias GetHabitCompletionStats = RitualistCore.GetHabitCompletionStats

// Re-export Debug UseCases
#if DEBUG
public typealias GetDatabaseStats = RitualistCore.GetDatabaseStats
public typealias ClearDatabase = RitualistCore.ClearDatabase
public typealias PopulateTestData = RitualistCore.PopulateTestData
public typealias TestDataPopulationError = RitualistCore.TestDataPopulationError
#endif

// Re-export Additional UseCases
public typealias CalculateCurrentStreak = RitualistCore.CalculateCurrentStreak
public typealias GetHabitsFromSuggestions = RitualistCore.GetHabitsFromSuggestions