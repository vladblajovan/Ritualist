//
//  CompletionPatternAnalyzer.swift
//  Ritualist
//
//  Analyzes user completion patterns for motivation triggers.
//  Extracted for testability and reusability.
//

import Foundation

// MARK: - CompletionPatternAnalyzer Protocol

public protocol CompletionPatternAnalyzerProtocol {
    /// Check if current completion represents a "comeback story"
    /// Returns true if today's completion significantly exceeds yesterday's poor performance
    func checkComebackStory(
        currentCompletion: Double,
        timezone: TimeZone
    ) async -> Bool

    /// Analyze recent completion pattern from today's summary
    func analyzePattern(completionPercentage: Double?) -> CompletionPattern
}

// MARK: - CompletionPatternAnalyzer

public final class CompletionPatternAnalyzer: CompletionPatternAnalyzerProtocol {

    private let getActiveHabits: GetActiveHabitsUseCase
    private let getLogs: GetLogsUseCase
    private let logger: DebugLogger

    /// Minimum improvement over yesterday to qualify as comeback
    private let comebackThreshold: Double = 0.25

    /// Maximum yesterday completion for comeback (if too high, it's not a comeback)
    private let maxYesterdayCompletion: Double = 0.6

    public init(
        getActiveHabits: GetActiveHabitsUseCase,
        getLogs: GetLogsUseCase,
        logger: DebugLogger
    ) {
        self.getActiveHabits = getActiveHabits
        self.getLogs = getLogs
        self.logger = logger
    }

    public func checkComebackStory(
        currentCompletion: Double,
        timezone: TimeZone
    ) async -> Bool {
        let yesterday = CalendarUtils.addDaysLocal(-1, to: Date(), timezone: timezone)

        do {
            let habits = try await getActiveHabits.execute()
            guard !habits.isEmpty else { return false }

            var completedCount = 0

            for habit in habits {
                let logs = try await getLogs.execute(
                    for: habit.id,
                    since: yesterday,
                    until: yesterday,
                    timezone: timezone
                )

                let hasCompletionYesterday = logs.contains { log in
                    let logTimezone = log.resolvedTimezone(fallback: timezone)
                    return CalendarUtils.areSameDayAcrossTimezones(
                        log.date,
                        timezone1: logTimezone,
                        yesterday,
                        timezone2: timezone
                    )
                }

                if hasCompletionYesterday {
                    completedCount += 1
                }
            }

            let yesterdayCompletion = Double(completedCount) / Double(habits.count)

            // Comeback criteria:
            // 1. Today is significantly better than yesterday (+25%)
            // 2. Yesterday was a weak day (<60%)
            let isComebackStory = currentCompletion > yesterdayCompletion + comebackThreshold
                && yesterdayCompletion < maxYesterdayCompletion

            if isComebackStory {
                logger.log(
                    "Comeback story detected",
                    level: .debug,
                    category: .ui,
                    metadata: [
                        "today": String(format: "%.0f%%", currentCompletion * 100),
                        "yesterday": String(format: "%.0f%%", yesterdayCompletion * 100)
                    ]
                )
            }

            return isComebackStory

        } catch {
            logger.log(
                "Comeback story detection failed",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            return false
        }
    }

    public func analyzePattern(completionPercentage: Double?) -> CompletionPattern {
        guard let percentage = completionPercentage else {
            return .insufficient
        }

        if percentage >= 0.8 {
            return .consistent
        } else if percentage >= 0.5 {
            return .improving
        } else if percentage > 0 {
            return .declining
        } else {
            return .insufficient
        }
    }
}

