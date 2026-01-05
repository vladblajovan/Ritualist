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
/// - Intention tracking (deferred add/remove operations)
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

    // MARK: - Intention Tracking State

    /// Original state when sheet opened (suggestionId -> wasAdded)
    private var originalState: [String: Bool] = [:]

    /// User's intended state (suggestionId -> wantsAdded)
    private var userIntentions: [String: Bool] = [:]

    /// Habit IDs for pending removals (suggestionId -> habitId)
    /// Stored because markSuggestionAsRemoved removes from suggestionToHabitMappings
    private var pendingRemovalHabitIds: [String: UUID] = [:]

    // MARK: - Limit State

    /// Whether user can create more habits (for banner display)
    /// Default to false (conservative) until properly initialized
    public private(set) var canCreateMoreHabits = false

    /// Whether operations are being processed
    public private(set) var isProcessingActions = false

    /// Callback to show paywall when limit reached
    public var onShowPaywall: (() -> Void)?

    /// Existing habits passed from parent
    private var existingHabits: [Habit] = []

    /// Flag to track if setExistingHabits has been called
    private var hasSetExistingHabits = false

    /// Flag to track if async initialize has completed
    private var isInitialized = false

    // MARK: - Computed Properties

    /// Delta from user intentions (additions - removals)
    public var intentionDelta: Int {
        var delta = 0
        for (suggestionId, intended) in userIntentions {
            let wasOriginallyAdded = originalState[suggestionId] ?? false
            if intended && !wasOriginallyAdded {
                delta += 1  // User wants to add this
            } else if !intended && wasOriginallyAdded {
                delta -= 1  // User wants to remove this
            }
        }
        return delta
    }

    /// Calculate projected habit count based on user intentions
    public var projectedHabitCount: Int {
        existingHabits.count + intentionDelta
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
        initializeIntentionState()

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
        originalState = [:]
        userIntentions = [:]
        pendingRemovalHabitIds = [:]
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

    // MARK: - Intention Methods

    /// Toggle user's intention for a habit
    /// Returns true if the toggle was allowed, false if blocked by limit
    @discardableResult
    public func toggleHabitIntention(_ suggestionId: String, intended: Bool, habitId: UUID? = nil) async -> Bool {
        if intended {
            let wasAlreadyIntended = userIntentions[suggestionId] ?? false
            let wasOriginallyAdded = originalState[suggestionId] ?? false

            // Only check limit for TRUE new additions (not re-selecting a deselected habit)
            let isNewAddition = !wasAlreadyIntended && !wasOriginallyAdded

            if isNewAddition {
                let canCreate = await checkHabitCreationLimit.execute(currentCount: projectedHabitCount)
                if !canCreate {
                    onShowPaywall?()
                    return false
                }
            }
            pendingRemovalHabitIds.removeValue(forKey: suggestionId)
        } else {
            if let habitId = habitId {
                pendingRemovalHabitIds[suggestionId] = habitId
            }
        }

        userIntentions[suggestionId] = intended

        // Update UI state immediately for visual feedback
        if intended {
            addedSuggestionIds.insert(suggestionId)
        } else {
            addedSuggestionIds.remove(suggestionId)
        }

        // Refresh limit status after intention change
        await refreshLimitStatus()

        return true
    }

    /// Refresh the limit status (call when intentions change)
    public func refreshLimitStatus() async {
        canCreateMoreHabits = await checkHabitCreationLimit.execute(currentCount: projectedHabitCount)
    }

    /// Find suggestionId for a given habitId (used when removing habits)
    public func suggestionId(for habitId: UUID) -> String? {
        suggestionToHabitMappings.first(where: { $0.value == habitId })?.key
    }

    /// Process all intention changes when Done is pressed
    public func processIntentionChanges() async {
        let operations = calculateRequiredOperations()
        logOperations(operations)

        guard !operations.isEmpty else {
            logger.log("No operations to process", level: .debug, category: .ui)
            return
        }

        isProcessingActions = true
        defer { isProcessingActions = false }

        for operation in operations {
            let shouldStop = await executeOperation(operation)
            if shouldStop {
                break
            }
        }
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

    private func initializeIntentionState() {
        let allSuggestions = getAllSuggestions()

        // Reset state
        originalState.removeAll()
        userIntentions.removeAll()
        pendingRemovalHabitIds.removeAll()

        for suggestion in allSuggestions {
            let isCurrentlyAdded = addedSuggestionIds.contains(suggestion.id)
            originalState[suggestion.id] = isCurrentlyAdded
            userIntentions[suggestion.id] = isCurrentlyAdded
        }
    }

    private func calculateRequiredOperations() -> [RequiredOperation] {
        var operations: [RequiredOperation] = []

        for (suggestionId, intendedState) in userIntentions {
            let originalStateForSuggestion = originalState[suggestionId] ?? false

            if intendedState != originalStateForSuggestion {
                if intendedState {
                    // Use case handles duplicates idempotently (returns existing ID if already exists)
                    if let suggestion = getAllSuggestions().first(where: { $0.id == suggestionId }) {
                        operations.append(.add(suggestion))
                    }
                } else {
                    if let habitId = pendingRemovalHabitIds[suggestionId] {
                        operations.append(.remove(suggestionId, habitId))
                    } else if let habitId = suggestionToHabitMappings[suggestionId] {
                        operations.append(.remove(suggestionId, habitId))
                    } else if let suggestion = getAllSuggestions().first(where: { $0.id == suggestionId }),
                              let habit = findHabitMatchingSuggestion(suggestion) {
                        operations.append(.remove(suggestionId, habit.id))
                    }
                }
            }
        }

        return operations
    }

    private func logOperations(_ operations: [RequiredOperation]) {
        let operationsDescription = operations.map { operation -> String in
            switch operation {
            case .add(let suggestion): return "ADD: \(suggestion.name)"
            case .remove(let suggestionId, let habitId): return "REMOVE: \(suggestionId) (habitId: \(habitId))"
            }
        }.joined(separator: ", ")

        logger.log(
            "Processing habit intentions",
            level: .debug,
            category: .ui,
            metadata: [
                "originalState": String(describing: originalState),
                "userIntentions": String(describing: userIntentions),
                "operationCount": operations.count,
                "operations": operationsDescription
            ]
        )
    }

    /// Returns true if an error occurred and processing should stop
    private func executeOperation(_ operation: RequiredOperation) async -> Bool {
        switch operation {
        case .add(let suggestion):
            return await executeAddOperation(suggestion)
        case .remove(let suggestionId, let habitId):
            let success = await removeHabitFromSuggestionUseCase.execute(suggestionId: suggestionId, habitId: habitId)
            if success {
                // Already removed from addedSuggestionIds in toggleHabitIntention
                suggestionToHabitMappings.removeValue(forKey: suggestionId)
                return false
            } else {
                logger.log(
                    "Failed to remove habit, stopping batch processing",
                    level: .warning,
                    category: .ui,
                    metadata: ["suggestionId": suggestionId, "habitId": habitId.uuidString]
                )
                return true  // Stop processing on error to prevent partial state
            }
        }
    }

    /// Returns true if an error occurred and processing should stop
    /// Note: Limit check already performed in toggleHabitIntention, no need to re-check here
    private func executeAddOperation(_ suggestion: HabitSuggestion) async -> Bool {
        let result = await createHabitFromSuggestionUseCase.execute(suggestion)
        switch result {
        case .success(let habitId):
            suggestionToHabitMappings[suggestion.id] = habitId
            trackHabitAdded(habitId: suggestion.id, habitName: suggestion.name, category: suggestion.categoryId)

            // Donate tip event when user adds their first habit
            await TapHabitTip.firstHabitAdded.donate()

            return false
        case .error(let errorMessage):
            trackHabitAddFailed(habitId: suggestion.id, error: errorMessage)
            logger.log(
                "Failed to create habit from suggestion, stopping batch processing",
                level: .warning,
                category: .ui,
                metadata: ["suggestionId": suggestion.id, "error": errorMessage]
            )
            return true  // Stop processing on error to prevent partial state
        }
    }

    private func findHabitMatchingSuggestion(_ suggestion: HabitSuggestion) -> Habit? {
        existingHabits.first { habit in
            habit.name == suggestion.name &&
            habit.emoji == suggestion.emoji &&
            habit.colorHex == suggestion.colorHex &&
            habit.kind == suggestion.kind
        }
    }

    /// Get user demographics from UserService for filtering suggestions
    private func getUserDemographics() -> (gender: UserGender?, ageGroup: UserAgeGroup?) {
        let profile = userService.currentProfile
        let gender: UserGender? = profile.gender.flatMap { UserGender(rawValue: $0) }
        let ageGroup: UserAgeGroup? = profile.ageGroup.flatMap { UserAgeGroup(rawValue: $0) }
        return (gender, ageGroup)
    }
}

// MARK: - Supporting Types

private enum RequiredOperation: Equatable {
    case add(HabitSuggestion)
    case remove(String, UUID) // suggestionId, habitId

    static func == (lhs: RequiredOperation, rhs: RequiredOperation) -> Bool {
        switch (lhs, rhs) {
        case (.add(let lhsSuggestion), .add(let rhsSuggestion)):
            return lhsSuggestion.id == rhsSuggestion.id
        case (.remove(let lhsSuggestionId, let lhsHabitId), .remove(let rhsSuggestionId, let rhsHabitId)):
            return lhsSuggestionId == rhsSuggestionId && lhsHabitId == rhsHabitId
        default:
            return false
        }
    }
}
