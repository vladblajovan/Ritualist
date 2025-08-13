//
//  NotificationService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public protocol NotificationService {
    func requestAuthorizationIfNeeded() async throws -> Bool
    func checkAuthorizationStatus() async -> Bool
    func schedule(for habitID: UUID, times: [ReminderTime]) async throws
    func scheduleWithActions(for habitID: UUID, habitName: String, times: [ReminderTime]) async throws
    func scheduleRichReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, times: [ReminderTime]) async throws
    func schedulePersonalityTailoredReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, personalityProfile: PersonalityProfile, times: [ReminderTime]) async throws
    func sendStreakMilestone(for habitID: UUID, habitName: String, streakDays: Int) async throws
    func cancel(for habitID: UUID) async
    func sendImmediate(title: String, body: String) async throws
    func setupNotificationCategories() async
}