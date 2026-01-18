//
//  InspirationCardViewModel.swift
//  Ritualist
//
//  Extracted from OverviewViewModel for Single Responsibility Principle.
//  Handles inspiration card display and personalized messaging.
//

import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

// MARK: - Configuration Input

public struct InspirationCardConfiguration {
    public let activeStreaks: [StreakInfo]
    public let todaysSummary: TodaysSummary?
    public let displayTimezone: TimeZone
    public let isViewingToday: Bool
    public let totalHabitsCount: Int
    public let userName: String?

    public init(
        activeStreaks: [StreakInfo],
        todaysSummary: TodaysSummary?,
        displayTimezone: TimeZone,
        isViewingToday: Bool,
        totalHabitsCount: Int,
        userName: String?
    ) {
        self.activeStreaks = activeStreaks
        self.todaysSummary = todaysSummary
        self.displayTimezone = displayTimezone
        self.isViewingToday = isViewingToday
        self.totalHabitsCount = totalHabitsCount
        self.userName = userName
    }
}

// MARK: - InspirationCardViewModel

@MainActor
@Observable
public final class InspirationCardViewModel {

    // MARK: - Observable Properties

    /// Whether to show the inspiration card/carousel
    public var showInspirationCard: Bool = false

    /// Multiple inspiration items for carousel display, sorted by priority
    public var inspirationItems: [InspirationItem] = []

    // MARK: - Internal State

    @ObservationIgnored private var lastShownInspirationTrigger: InspirationTrigger?
    @ObservationIgnored private var dismissedTriggersToday: Set<InspirationTrigger> = []
    @ObservationIgnored private var cachedInspirationMessage: String?
    @ObservationIgnored private var lastEvaluatedTriggerSet: Set<InspirationTrigger> = []
    @ObservationIgnored private var cachedUserName: String?

    /// Tracks the current inspiration check task to prevent concurrent executions (Task storm prevention)
    @ObservationIgnored private var inspirationCheckTask: Task<Void, Never>?

    // MARK: - Dependencies

    @ObservationIgnored @Injected(\.personalizedMessageGenerator) private var personalizedMessageGenerator
    @ObservationIgnored @Injected(\.getCurrentSlogan) private var getCurrentSlogan
    @ObservationIgnored @Injected(\.getPersonalityProfileUseCase) private var getPersonalityProfileUseCase
    @ObservationIgnored @Injected(\.isPersonalityAnalysisEnabledUseCase) private var isPersonalityAnalysisEnabledUseCase
    @ObservationIgnored @Injected(\.getCurrentUserProfile) private var getCurrentUserProfile
    @ObservationIgnored @Injected(\.inspirationDismissalStore) private var dismissalStore
    @ObservationIgnored @Injected(\.completionPatternAnalyzer) private var patternAnalyzer
    @ObservationIgnored @Injected(\.debugLogger) private var logger

    // MARK: - Context (provided by parent ViewModel)

    @ObservationIgnored private var activeStreaks: [StreakInfo] = []
    @ObservationIgnored private var todaysSummary: TodaysSummary?
    @ObservationIgnored private var displayTimezone: TimeZone = .current
    @ObservationIgnored private var isViewingToday: Bool = true
    @ObservationIgnored private var totalHabitsCount: Int = 0

    // MARK: - Computed Properties

    public var shouldShowInspirationCard: Bool {
        guard isViewingToday else { return false }
        return showInspirationCard
    }

    public var currentInspirationMessage: String {
        cachedInspirationMessage ?? getCurrentSlogan.execute()
    }

    public var currentTimeOfDay: TimeOfDay {
        TimeOfDay.current()
    }

    public var currentSlogan: String {
        getCurrentSlogan.execute()
    }

    // MARK: - Initialization

    public init() {
        resetDismissedTriggersIfNewDay()
    }

    // MARK: - Context Configuration

    public func configure(with configuration: InspirationCardConfiguration) {
        self.activeStreaks = configuration.activeStreaks
        self.todaysSummary = configuration.todaysSummary
        self.displayTimezone = configuration.displayTimezone
        self.isViewingToday = configuration.isViewingToday
        self.totalHabitsCount = configuration.totalHabitsCount
        self.cachedUserName = configuration.userName
    }

    // MARK: - Public Methods

    public func showInspiration() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showInspirationCard = true
        }
    }

    public func triggerMotivation() {
        let trigger: InspirationTrigger = {
            guard let summary = todaysSummary else { return .morningMotivation }

            let completionRate = summary.completionPercentage

            if completionRate >= 1.0 {
                return .perfectDay
            } else if completionRate >= 0.75 {
                return .strongFinish
            } else if completionRate >= 0.5 {
                return .halfwayPoint
            } else {
                switch currentTimeOfDay {
                case .morning: return .morningMotivation
                case .noon: return .strugglingMidDay
                case .evening: return .eveningReflection
                }
            }
        }()

        showInspirationWithTrigger(trigger)
    }

    public func hideInspiration() {
        if let currentTrigger = lastShownInspirationTrigger {
            dismissedTriggersToday.insert(currentTrigger)
            saveDismissedTriggers()
        }
        showInspirationCard = false
        inspirationItems = []
    }

    public func dismissInspirationItem(_ item: InspirationItem) {
        dismissedTriggersToday.insert(item.trigger)
        saveDismissedTriggers()

        inspirationItems.removeAll { $0.id == item.id }
        lastEvaluatedTriggerSet.remove(item.trigger)

        if inspirationItems.isEmpty {
            showInspirationCard = false
            cachedInspirationMessage = nil
            lastEvaluatedTriggerSet = []
        } else {
            cachedInspirationMessage = inspirationItems.first?.message
        }

        logger.log(
            "Dismissed inspiration item",
            level: .debug,
            category: .ui,
            metadata: [
                "trigger": item.trigger.displayName,
                "remaining_count": inspirationItems.count
            ]
        )
    }

    public func dismissAllInspirationItems() {
        for item in inspirationItems {
            dismissedTriggersToday.insert(item.trigger)
        }
        saveDismissedTriggers()

        lastEvaluatedTriggerSet = []
        showInspirationCard = false
        cachedInspirationMessage = nil
        inspirationItems = []

        logger.log(
            "Dismissed all inspiration items",
            level: .debug,
            category: .ui,
            metadata: ["dismissed_count": dismissedTriggersToday.count]
        )
    }

    public func checkAndShowInspirationCard() {
        // CRITICAL: Always cancel previous task FIRST, even before early-return guards
        // Without this, navigating to past dates leaves old tasks running checkComebackStory()
        // which fetches ALL habits individually, causing app freezing during rapid scrolling
        inspirationCheckTask?.cancel()

        guard isViewingToday, let summary = todaysSummary else {
            return
        }

        guard totalHabitsCount > 0 else {
            return
        }

        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        inspirationCheckTask = Task { @MainActor in
            // Early exit if task was cancelled while waiting to start
            guard !Task.isCancelled else { return }

            let now = Date()
            let isComebackStory = await patternAnalyzer.checkComebackStory(
                currentCompletion: summary.completionPercentage,
                timezone: displayTimezone
            )

            // Check cancellation after async work
            guard !Task.isCancelled else { return }

            let context = InspirationTriggerEvaluator.Context(
                completionRate: summary.completionPercentage,
                completedCount: summary.completedHabitsCount,
                totalHabits: summary.totalHabits,
                totalHabitsInApp: totalHabitsCount,
                hour: CalendarUtils.hourComponentLocal(from: now),
                timeOfDay: currentTimeOfDay,
                isWeekend: [1, 7].contains(CalendarUtils.weekdayComponentLocal(from: now)),
                isComebackStory: isComebackStory
            )

            let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)
            let availableTriggers = InspirationTriggerEvaluator.filterAndSort(
                triggers: triggers,
                dismissedToday: dismissedTriggersToday
            )

            // Check cancellation before state updates
            guard !Task.isCancelled else { return }

            if !availableTriggers.isEmpty {
                let newTriggerSet = Set(availableTriggers)
                if newTriggerSet == lastEvaluatedTriggerSet && showInspirationCard && !inspirationItems.isEmpty {
                    return
                }

                lastEvaluatedTriggerSet = newTriggerSet
                await showInspirationWithTriggers(availableTriggers)
            } else {
                lastEvaluatedTriggerSet = []
            }
        }
    }

    public func resetDismissedTriggersIfNewDay() {
        if dismissalStore.resetIfNewDay(timezone: displayTimezone) {
            dismissedTriggersToday.removeAll()
            lastEvaluatedTriggerSet = []
        } else {
            dismissedTriggersToday = dismissalStore.loadDismissedTriggers()
        }
    }

    // MARK: - Private Methods - Display

    private func showInspirationWithTrigger(_ trigger: InspirationTrigger) {
        let delay = InspirationTriggerEvaluator.animationDelay(for: trigger)

        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(delay))

            let message = await getPersonalizedMessage(for: trigger)
            self.cachedInspirationMessage = message
            self.lastShownInspirationTrigger = trigger

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.showInspirationCard = true
            }
        }
    }

    private func showInspirationWithTriggers(_ triggers: [InspirationTrigger]) async {
        guard let primaryTrigger = triggers.first else { return }
        let delay = InspirationTriggerEvaluator.animationDelay(for: primaryTrigger)

        try? await Task.sleep(for: .milliseconds(delay))

        var items: [InspirationItem] = []
        let uniqueSlogans = getCurrentSlogan.getUniqueSlogans(count: triggers.count, for: currentTimeOfDay)
        var seenMessages: Set<String> = []
        var sloganIndex = 0

        for trigger in triggers {
            let message = await getPersonalizedMessage(for: trigger)

            guard !seenMessages.contains(message) else { continue }
            seenMessages.insert(message)

            let slogan = sloganIndex < uniqueSlogans.count
                ? uniqueSlogans[sloganIndex]
                : getCurrentSlogan.execute()
            sloganIndex += 1

            if let item = InspirationItem(trigger: trigger, message: message, slogan: slogan) {
                items.append(item)
            }
        }

        self.inspirationItems = items
        self.cachedInspirationMessage = items.first?.message
        self.lastShownInspirationTrigger = primaryTrigger

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.showInspirationCard = true
        }
    }

    // MARK: - Private Methods - Personalization

    private func getPersonalizedMessage(for trigger: InspirationTrigger) async -> String {
        let personalityProfile = await loadPersonalityProfileForMessage()
        let currentStreakValue = activeStreaks.first?.currentStreak ?? 0
        let pattern = patternAnalyzer.analyzePattern(completionPercentage: todaysSummary?.completionPercentage)

        let context = MessageContext(
            trigger: trigger,
            personality: personalityProfile,
            completionPercentage: todaysSummary?.completionPercentage ?? 0.0,
            timeOfDay: currentTimeOfDay,
            userName: cachedUserName,
            currentStreak: currentStreakValue,
            recentPattern: pattern
        )

        let message = await personalizedMessageGenerator.generateMessage(for: context)
        return message.content
    }

    private func loadPersonalityProfileForMessage() async -> PersonalityProfile? {
        let userId = await getCurrentUserProfile.execute().id

        do {
            let isEnabled = try await isPersonalityAnalysisEnabledUseCase.execute(for: userId)
            guard isEnabled else { return nil }
            return try await getPersonalityProfileUseCase.execute(for: userId)
        } catch {
            return nil
        }
    }

    // MARK: - Private Methods - Persistence

    private func saveDismissedTriggers() {
        dismissalStore.saveDismissedTriggers(dismissedTriggersToday)
    }
}
