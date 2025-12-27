//
//  DeepLinkHandler.swift
//  Ritualist
//
//  Extracted from RitualistApp.swift for SRP compliance
//

import Foundation
import SwiftUI
import RitualistCore
import FactoryKit

/// Handles deep links from widgets and other sources
@MainActor
public final class DeepLinkHandler {
    private let urlValidationService: URLValidationService
    private let navigationService: NavigationService
    private let logger: DebugLogger

    public init(
        urlValidationService: URLValidationService,
        navigationService: NavigationService,
        logger: DebugLogger
    ) {
        self.urlValidationService = urlValidationService
        self.navigationService = navigationService
        self.logger = logger
    }

    /// Handle deep links from widget taps
    /// Navigates to appropriate habit or overview section with enhanced validation
    public func handleDeepLink(_ url: URL) {
        let validationResult = urlValidationService.validateDeepLinkURL(url)

        guard validationResult.isValid else {
            logger.log(
                "🔗 Deep link validation failed",
                level: .warning,
                category: .system,
                metadata: ["url": url.absoluteString, "reason": validationResult.description]
            )
            handleOverviewDeepLink()
            return
        }

        switch url.host {
        case "habit":
            handleHabitDeepLink(url)
        case "overview":
            handleOverviewDeepLink()
        default:
            handleOverviewDeepLink()
        }
    }

    /// Handle habit-specific deep links from widget
    /// Formats:
    /// - Legacy: ritualist://habit/{habitId}
    /// - Enhanced: ritualist://habit/{habitId}?date={ISO8601}&action={action}
    private func handleHabitDeepLink(_ url: URL) {
        guard let habitId = urlValidationService.extractHabitId(from: url) else {
            logger.log(
                "🔗 Failed to extract valid habit ID",
                level: .warning,
                category: .system,
                metadata: ["url": url.absoluteString]
            )
            handleOverviewDeepLink()
            return
        }

        let targetDate = urlValidationService.extractDate(from: url)
        let action = urlValidationService.extractAction(from: url)

        Task { @MainActor in
            if let targetDate = targetDate {
                navigationService.navigateToOverview(shouldRefresh: true)

                switch action {
                case .progress:
                    await handleProgressDeepLinkAction(habitId: habitId, targetDate: targetDate)
                case .view:
                    logger.log(
                        "🔗 View action requested",
                        level: .info,
                        category: .system,
                        metadata: ["habitId": habitId.uuidString, "date": targetDate.ISO8601Format()]
                    )
                    await navigateToDateInOverview(targetDate)
                }
            } else {
                navigationService.navigateToOverview(shouldRefresh: true)
                logger.log(
                    "🔗 Legacy deep link - navigated to overview",
                    level: .info,
                    category: .system,
                    metadata: ["habitId": habitId.uuidString]
                )
            }
        }
    }

    /// Handle progress deep link action for numeric habits
    private func handleProgressDeepLinkAction(habitId: UUID, targetDate: Date) async {
        logger.log(
            "🔗 Progress action requested",
            level: .info,
            category: .system,
            metadata: ["habitId": habitId.uuidString, "date": targetDate.ISO8601Format()]
        )

        do {
            let habitRepository = Container.shared.habitRepository()
            let habits = try await habitRepository.fetchAllHabits()

            guard let habit = habits.first(where: { $0.id == habitId }),
                  habit.kind == .numeric else {
                logger.log(
                    "🔗 Habit not found or not numeric",
                    level: .warning,
                    category: .system,
                    metadata: ["habitId": habitId.uuidString]
                )
                return
            }

            let navigationService = Container.shared.navigationService()
            navigationService.navigateToOverview(shouldRefresh: true)

            let overviewViewModel = Container.shared.overviewViewModel()
            await navigateToDateInOverview(targetDate)
            overviewViewModel.setPendingNumericHabit(habit)
        } catch {
            logger.log(
                "🔗 Error fetching habit for progress action",
                level: .warning,
                category: .system,
                metadata: ["habitId": habitId.uuidString, "error": error.localizedDescription]
            )
        }
    }

    /// Navigate to a specific date in the Overview
    private func navigateToDateInOverview(_ targetDate: Date) async {
        let overviewViewModel = Container.shared.overviewViewModel()
        await overviewViewModel.loadData()
        overviewViewModel.viewingDate = CalendarUtils.startOfDayLocal(
            for: targetDate,
            timezone: overviewViewModel.displayTimezone
        )
    }

    /// Handle overview deep links from widget
    private func handleOverviewDeepLink() {
        Task { @MainActor in
            navigationService.navigateToOverview(shouldRefresh: true)
        }
    }
}
