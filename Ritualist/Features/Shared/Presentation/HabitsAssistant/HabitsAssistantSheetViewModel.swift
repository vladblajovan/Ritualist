//
//  HabitsAssistantSheetViewModel.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 02.01.2026.
//

import Foundation
import Observation
import RitualistCore
import TipKit

/// Consolidated ViewModel for HabitsAssistantSheet handling all logic:
/// - Category management
/// - Suggestion display
/// - Limit checking
/// - Immediate habit operations (add/remove execute directly)
/// - Paywall integration
@MainActor @Observable
public final class HabitsAssistantSheetViewModel { // swiftlint:disable:this type_body_length

    // MARK: - Dependencies

    private let getPredefinedCategoriesUseCase: GetPredefinedCategoriesUseCase
    private let getHabitsFromSuggestionsUseCase: GetHabitsFromSuggestionsUseCase
    private let getSuggestionsUseCase: GetSuggestionsUseCase
    private let createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase
    private let removeHabitFromSuggestionUseCase: RemoveHabitFromSuggestionUseCase
    private let checkHabitCreationLimit: CheckHabitCreationLimitUseCase
    private let userService: UserService
    private let trackUserAction: TrackUserActionUseCase?
    private let logger: DebugLogger

    // MARK: - Category State

    public private(set) var categories: [HabitCategory] = []
    public var selectedCategory: HabitCategory?
    public private(set) var categoriesError: Error?

    // MARK: - Suggestion State

    public private(set) var addedSuggestionIds: Set<String> = []
    public private(set) var suggestionToHabitMappings: [String: UUID] = [:]

    /// Cached demographics (fetched once at initialization to avoid Observable loops)
    private var cachedGender: UserGender?
    private var cachedAgeGroup: UserAgeGroup?

    /// Cached suggestions (computed once at initialization)
    private var cachedAllSuggestions: [HabitSuggestion] = []

    // MARK: - Limit State

    /// Whether user can create more habits (for banner display)
    /// Default to false (conservative) until properly initialized
    public private(set) var canCreateMoreHabits = false

    /// Callback to show paywall when limit reached
    public var onShowPaywall: (() -> Void)?

    /// Existing habits passed from parent
    private var existingHabits: [Habit] = []

    /// Flag to track if setExistingHabits has been called
    private var hasSetExistingHabits = false

    /// Flag to track if async initialize has completed
    private var isInitialized = false

    // MARK: - Computed Properties

    /// Current habit count (immediate operations, no pending changes)
    public var projectedHabitCount: Int {
        addedSuggestionIds.count
    }

    /// Should show limit banner for free users
    public var shouldShowLimitBanner: Bool {
        #if ALL_FEATURES_ENABLED
        return false  // Never show in AllFeatures mode
        #else
        return !canCreateMoreHabits
        #endif
    }

    /// Max habits allowed (from BusinessConstants)
    public var maxHabitsAllowed: Int {
        BusinessConstants.freeMaxHabits
    }

    // MARK: - Initialization

    public init(
        getPredefinedCategoriesUseCase: GetPredefinedCategoriesUseCase,
        getHabitsFromSuggestionsUseCase: GetHabitsFromSuggestionsUseCase,
        getSuggestionsUseCase: GetSuggestionsUseCase,
        createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase,
        removeHabitFromSuggestionUseCase: RemoveHabitFromSuggestionUseCase,
        checkHabitCreationLimit: CheckHabitCreationLimitUseCase,
        userService: UserService,
        trackUserAction: TrackUserActionUseCase? = nil,
        logger: DebugLogger
    ) {
        self.getPredefinedCategoriesUseCase = getPredefinedCategoriesUseCase
        self.getHabitsFromSuggestionsUseCase = getHabitsFromSuggestionsUseCase
        self.getSuggestionsUseCase = getSuggestionsUseCase
        self.createHabitFromSuggestionUseCase = createHabitFromSuggestionUseCase
        self.removeHabitFromSuggestionUseCase = removeHabitFromSuggestionUseCase
        self.checkHabitCreationLimit = checkHabitCreationLimit
        self.userService = userService
        self.trackUserAction = trackUserAction
        self.logger = logger
    }

    // MARK: - Initialization Methods

    /// Set existing habits (call immediately when sheet appears)
    /// Demographics and suggestions are loaded async in initialize()
    public func setExistingHabits(_ habits: [Habit]) {
        // Skip if already called (prevents re-initialization on re-renders)
        guard !hasSetExistingHabits else { return }
        hasSetExistingHabits = true

        self.existingHabits = habits
    }

    /// Initialize the sheet (async - loads profile, demographics, and refreshes limit status)
    public func initialize(existingHabits: [Habit]) async {
        // Skip if already initialized (singleton pattern)
        guard !isInitialized else { return }
        isInitialized = true

        // Ensure profile is loaded before accessing demographics
        await userService.loadProfileIfNeeded()

        // Cache demographics once to avoid Observable loops during rendering
        let (gender, ageGroup) = getUserDemographics()
        cachedGender = gender
        cachedAgeGroup = ageGroup

        // Cache all suggestions once
        cachedAllSuggestions = getSuggestionsUseCase.execute(gender: gender, ageGroup: ageGroup)

        // Initialize with existing habits (needs cached suggestions)
        initializeWithExistingHabits(existingHabits)

        logger.log(
            "Initializing Habits Assistant Sheet",
            level: .debug,
            category: .ui,
            metadata: ["existingHabits": existingHabits.map { "\($0.name) (suggestionId: \($0.suggestionId ?? "nil"))" }.joined(separator: ", ")]
        )

        await refreshLimitStatus()
    }

    /// Reset state for next sheet presentation (call on sheet dismiss)
    public func reset() {
        hasSetExistingHabits = false
        isInitialized = false
        existingHabits = []
        cachedAllSuggestions = []
        addedSuggestionIds = []
        suggestionToHabitMappings = [:]
        selectedCategory = nil
    }

    // MARK: - Category Methods

    public func loadCategories() async {
        categoriesError = nil

        do {
            categories = try await getPredefinedCategoriesUseCase.execute()
        } catch {
            categoriesError = error
            categories = []
        }
    }

    public func selectCategory(_ category: HabitCategory) {
        selectedCategory = category
        trackUserAction?.execute(action: .habitsAssistantCategorySelected(category: category.name), context: [:])
    }

    public func clearCategorySelection() {
        selectedCategory = nil
        trackUserAction?.execute(action: .habitsAssistantCategoryCleared, context: [:])
    }

    // MARK: - Suggestion Methods

    /// Get suggestions filtered by selected category (uses cached data)
    public func getSuggestions() -> [HabitSuggestion] {
        if let selectedCategory = selectedCategory {
            return cachedAllSuggestions.filter { $0.categoryId == selectedCategory.id }
        } else {
            return cachedAllSuggestions
        }
    }

    /// Get all suggestions (uses cached data)
    public func getAllSuggestions() -> [HabitSuggestion] {
        cachedAllSuggestions
    }

    private func initializeWithExistingHabits(_ existingHabits: [Habit]) {
        // Use cached suggestions (already computed in setExistingHabits)
        let allSuggestionIds = cachedAllSuggestions.map { $0.id }

        let (addedSuggestions, habitMappings) = getHabitsFromSuggestionsUseCase.execute(
            existingHabits: existingHabits,
            suggestionIds: allSuggestionIds
        )
        addedSuggestionIds = addedSuggestions
        suggestionToHabitMappings = habitMappings
    }

    /// Refresh cached suggestions when demographics change
    /// Note: This is typically not needed since the sheet is dismissed/recreated,
    /// but provided for completeness
    public func refreshSuggestionsCache() {
        let (gender, ageGroup) = getUserDemographics()
        cachedGender = gender
        cachedAgeGroup = ageGroup
        cachedAllSuggestions = getSuggestionsUseCase.execute(gender: gender, ageGroup: ageGroup)
    }

    public func markSuggestionAsAdded(_ suggestionId: String, habitId: UUID) {
        addedSuggestionIds.insert(suggestionId)
        suggestionToHabitMappings[suggestionId] = habitId
    }

    public func markSuggestionAsRemoved(_ suggestionId: String) {
        addedSuggestionIds.remove(suggestionId)
        suggestionToHabitMappings.removeValue(forKey: suggestionId)
    }

    // MARK: - Immediate Habit Operations

    /// Add a habit immediately (creates in database)
    /// Returns true if successful, false if blocked by limit or error
    @discardableResult
    public func addHabit(_ suggestion: HabitSuggestion) async -> Bool {
        // Check limit before adding
        let currentCount = addedSuggestionIds.count
        let canCreate = await checkHabitCreationLimit.execute(currentCount: currentCount)
        if !canCreate {
            onShowPaywall?()
            return false
        }

        // Create the habit immediately
        let result = await createHabitFromSuggestionUseCase.execute(suggestion)

        switch result {
        case .success(let habitId):
            addedSuggestionIds.insert(suggestion.id)
            suggestionToHabitMappings[suggestion.id] = habitId
            trackHabitAdded(habitId: suggestion.id, habitName: suggestion.name, category: suggestion.categoryId)
            await TapHabitTip.firstHabitAdded.donate()
            // Notify other views (Overview) that habits data changed
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)
            logger.log(
                "Habit added successfully",
                level: .info,
                category: .ui,
                metadata: ["suggestionId": suggestion.id, "habitId": habitId.uuidString]
            )
            await refreshLimitStatus()
            return true

        case .alreadyExists(let habitId):
            // Habit already exists, just update our tracking state
            addedSuggestionIds.insert(suggestion.id)
            suggestionToHabitMappings[suggestion.id] = habitId
            logger.log(
                "Habit already existed (idempotent)",
                level: .info,
                category: .ui,
                metadata: ["suggestionId": suggestion.id, "habitId": habitId.uuidString]
            )
            return true

        case .error(let errorMessage):
            trackHabitAddFailed(habitId: suggestion.id, error: errorMessage)
            logger.log(
                "Failed to add habit",
                level: .error,
                category: .ui,
                metadata: ["suggestionId": suggestion.id, "error": errorMessage]
            )
            return false
        }
    }

    /// Remove a habit immediately (deletes from database)
    /// Returns true if successful, false if error
    @discardableResult
    public func removeHabit(_ suggestionId: String) async -> Bool {
        // Find the habitId to delete
        guard let habitId = suggestionToHabitMappings[suggestionId] else {
            logger.log(
                "Cannot remove habit - no habitId found in mappings",
                level: .warning,
                category: .ui,
                metadata: ["suggestionId": suggestionId]
            )
            return false
        }

        // Delete the habit immediately
        let success = await removeHabitFromSuggestionUseCase.execute(suggestionId: suggestionId, habitId: habitId)

        if success {
            addedSuggestionIds.remove(suggestionId)
            suggestionToHabitMappings.removeValue(forKey: suggestionId)
            // Notify other views (Overview) that habits data changed
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)
            logger.log(
                "Habit removed successfully",
                level: .info,
                category: .ui,
                metadata: ["suggestionId": suggestionId, "habitId": habitId.uuidString]
            )
            await refreshLimitStatus()
            return true
        } else {
            trackHabitRemoveFailed(habitId: suggestionId, error: "Delete operation failed")
            logger.log(
                "Failed to remove habit",
                level: .error,
                category: .ui,
                metadata: ["suggestionId": suggestionId, "habitId": habitId.uuidString]
            )
            return false
        }
    }

    /// Refresh the limit status
    public func refreshLimitStatus() async {
        canCreateMoreHabits = await checkHabitCreationLimit.execute(currentCount: addedSuggestionIds.count)
    }

    /// Find suggestionId for a given habitId (used when removing habits)
    public func suggestionId(for habitId: UUID) -> String? {
        suggestionToHabitMappings.first(where: { $0.value == habitId })?.key
    }

    // MARK: - Tracking Methods

    public func trackHabitSuggestionViewed(habitId: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitSuggestionViewed(
            habitId: habitId,
            category: category
        ), context: [:])
    }

    public func trackHabitAdded(habitId: String, habitName: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitAdded(
            habitId: habitId,
            habitName: habitName,
            category: category
        ), context: [:])
    }

    public func trackHabitAddFailed(habitId: String, error: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitAddFailed(
            habitId: habitId,
            error: error
        ), context: [:])
    }

    public func trackHabitRemoved(habitId: String, habitName: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitRemoved(
            habitId: habitId,
            habitName: habitName,
            category: category
        ), context: [:])
    }

    public func trackHabitRemoveFailed(habitId: String, error: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitRemoveFailed(
            habitId: habitId,
            error: error
        ), context: [:])
    }

    // MARK: - Private Methods

    /// Get user demographics from UserService for filtering suggestions
    private func getUserDemographics() -> (gender: UserGender?, ageGroup: UserAgeGroup?) {
        let profile = userService.currentProfile
        let gender: UserGender? = profile.gender.flatMap { UserGender(rawValue: $0) }
        let ageGroup: UserAgeGroup? = profile.ageGroup.flatMap { UserAgeGroup(rawValue: $0) }
        return (gender, ageGroup)
    }
}
