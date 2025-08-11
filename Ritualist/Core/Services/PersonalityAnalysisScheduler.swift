//
//  PersonalityAnalysisScheduler.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import RitualistCore
import UserNotifications

/// Service responsible for scheduling automatic personality analysis based on user preferences
public final class PersonalityAnalysisScheduler: PersonalityAnalysisSchedulerProtocol {
    
    // MARK: - Dependencies
    
    private let personalityRepository: PersonalityAnalysisRepositoryProtocol
    private let analyzePersonalityUseCase: AnalyzePersonalityUseCase
    private let validateAnalysisDataUseCase: ValidateAnalysisDataUseCase
    private let notificationCenter: UNUserNotificationCenter
    
    // MARK: - State
    
    private var scheduledUsers: Set<UUID> = []
    private var lastAnalysisDates: [UUID: Date] = [:]
    private var lastDataHashes: [UUID: String] = [:]
    
    // MARK: - Constants
    
    private static let schedulerIdentifierPrefix = "personality_analysis_"
    private static let minimumDataChangeThreshold = 0.1 // 10% data change to trigger analysis
    
    // MARK: - Initialization
    
    public init(
        personalityRepository: PersonalityAnalysisRepositoryProtocol,
        analyzePersonalityUseCase: AnalyzePersonalityUseCase,
        validateAnalysisDataUseCase: ValidateAnalysisDataUseCase,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.personalityRepository = personalityRepository
        self.analyzePersonalityUseCase = analyzePersonalityUseCase
        self.validateAnalysisDataUseCase = validateAnalysisDataUseCase
        self.notificationCenter = notificationCenter
        
        loadSchedulerState()
    }
    
    // MARK: - Public Methods
    
    public func startScheduling(for userId: UUID) async {
        guard !scheduledUsers.contains(userId) else { return }
        
        do {
            // Get user preferences
            guard let preferences = try await personalityRepository.getAnalysisPreferences(for: userId),
                  preferences.isCurrentlyActive else {
                return
            }
            
            scheduledUsers.insert(userId)
            await scheduleNextAnalysis(for: userId, preferences: preferences)
            saveSchedulerState()
            
            
        } catch {
            // Failed to start scheduling - preferences might not be set
        }
    }
    
    public func stopScheduling(for userId: UUID) async {
        guard scheduledUsers.contains(userId) else { return }
        
        scheduledUsers.remove(userId)
        lastAnalysisDates.removeValue(forKey: userId)
        lastDataHashes.removeValue(forKey: userId)
        
        // Cancel any pending notifications
        let identifier = Self.schedulerIdentifierPrefix + userId.uuidString
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        saveSchedulerState()
        
    }
    
    public func triggerAnalysisCheck(for userId: UUID) async {
        do {
            guard try await shouldRunAnalysis(for: userId) else {
                return
            }
            
            await performAnalysis(for: userId)
            
        } catch {
            // Error during analysis check
        }
    }
    
    /// Forces analysis to run for manual mode, bypassing frequency checks
    public func forceManualAnalysis(for userId: UUID) async {
        let timestamp = Date().timeIntervalSince1970
        print("🔄 forceManualAnalysis called at \(timestamp) for user \(userId)")
        
        do {
            // Get user preferences
            guard let preferences = try await personalityRepository.getAnalysisPreferences(for: userId),
                  preferences.isCurrentlyActive else {
                return
            }
            
            
            // Check if user has sufficient data
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            guard eligibility.isEligible else {
                return
            }
            
            await performAnalysis(for: userId)
            
            let endTimestamp = Date().timeIntervalSince1970
            // Force manual analysis completed
            
        } catch {
            // Error during forced manual analysis
        }
    }
    
    public func shouldRunAnalysis(for userId: UUID) async throws -> Bool {
        // Get user preferences
        guard let preferences = try await personalityRepository.getAnalysisPreferences(for: userId),
              preferences.isCurrentlyActive else {
            return false
        }
        
        // Check if user has sufficient data
        let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
        guard eligibility.isEligible else {
            return false
        }
        
        // Check frequency-based timing
        guard await isFrequencyTimeMet(for: userId, frequency: preferences.analysisFrequency) else {
            return false
        }
        
        // Check if enough data has changed
        guard await hasSignificantDataChange(for: userId) else {
            return false
        }
        
        return true
    }
    
    public func updateScheduling(for userId: UUID, preferences: PersonalityAnalysisPreferences) async {
        if preferences.isCurrentlyActive {
            // Update existing scheduling or start new
            await scheduleNextAnalysis(for: userId, preferences: preferences)
            if !scheduledUsers.contains(userId) {
                scheduledUsers.insert(userId)
            }
        } else {
            // Stop scheduling if disabled
            await stopScheduling(for: userId)
        }
        
        saveSchedulerState()
    }
    
    public func getNextScheduledAnalysis(for userId: UUID) async -> Date? {
        do {
            guard let preferences = try await personalityRepository.getAnalysisPreferences(for: userId),
                  preferences.isCurrentlyActive,
                  let lastAnalysis = lastAnalysisDates[userId] else {
                return nil
            }
            
            return calculateNextAnalysisDate(from: lastAnalysis, frequency: preferences.analysisFrequency)
            
        } catch {
            // Error getting next scheduled analysis
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func scheduleNextAnalysis(for userId: UUID, preferences: PersonalityAnalysisPreferences) async {
        let nextAnalysisDate = calculateNextAnalysisDate(
            from: lastAnalysisDates[userId] ?? Date(),
            frequency: preferences.analysisFrequency
        )
        
        // Schedule local notification
        await scheduleNotification(for: userId, at: nextAnalysisDate, frequency: preferences.analysisFrequency)
        
    }
    
    private func calculateNextAnalysisDate(from lastDate: Date, frequency: AnalysisFrequency) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        let nextDate: Date
        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? now
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: lastDate) ?? now
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: lastDate) ?? now
        case .manual:
            return Date.distantFuture // Never automatically schedule
        }
        
        // Ensure next date is in the future
        return max(nextDate, calendar.date(byAdding: .minute, value: 5, to: now) ?? now)
    }
    
    private func isFrequencyTimeMet(for userId: UUID, frequency: AnalysisFrequency) async -> Bool {
        guard frequency != .manual else { return false }
        
        guard let lastAnalysis = lastAnalysisDates[userId] else {
            return true // First analysis
        }
        
        let nextScheduled = calculateNextAnalysisDate(from: lastAnalysis, frequency: frequency)
        return Date() >= nextScheduled
    }
    
    private func hasSignificantDataChange(for userId: UUID) async -> Bool {
        do {
            // Get current habit analysis input to create a data fingerprint
            let input = try await personalityRepository.getHabitAnalysisInput(for: userId)
            let currentHash = createDataHash(from: input)
            
            guard let lastHash = lastDataHashes[userId] else {
                lastDataHashes[userId] = currentHash
                return true // First time, consider it changed
            }
            
            let hasChanged = currentHash != lastHash
            if hasChanged {
                lastDataHashes[userId] = currentHash
            }
            
            return hasChanged
            
        } catch {
            // Error checking data changes
            return false
        }
    }
    
    private func createDataHash(from input: HabitAnalysisInput) -> String {
        // Create a simple hash of key data points
        var hashComponents: [String] = []
        
        hashComponents.append("habits:\(input.activeHabits.count)")
        hashComponents.append("tracking:\(input.trackingDays)")
        hashComponents.append("custom_habits:\(input.customHabits.count)")
        hashComponents.append("custom_categories:\(input.customCategories.count)")
        hashComponents.append("data_points:\(input.totalDataPoints)")
        
        // Add completion rates
        let avgCompletion = input.completionRates.reduce(0.0, +) / Double(max(input.completionRates.count, 1))
        hashComponents.append("completion:\(Int(avgCompletion * 100))")
        
        return hashComponents.joined(separator:"|")
    }
    
    private func performAnalysis(for userId: UUID) async {
        do {
            
            let profile = try await analyzePersonalityUseCase.execute(for: userId)
            
            // CRITICAL: Save the profile to the database!
            try await personalityRepository.savePersonalityProfile(profile)
            // Personality profile saved to database
            
            lastAnalysisDates[userId] = Date()
            saveSchedulerState()
            
            
            // Send rich notification about the completed analysis
            await sendAnalysisCompletedNotification(for: userId, profile: profile)
            
            // Schedule next analysis
            if let preferences = try await personalityRepository.getAnalysisPreferences(for: userId) {
                await scheduleNextAnalysis(for: userId, preferences: preferences)
            }
            
        } catch {
            // Failed automatic personality analysis - fail silently
            // No notifications for insufficient data scenarios
        }
    }
    
    private func sendAnalysisCompletedNotification(for userId: UUID, profile: PersonalityProfile) async {
        let identifier = "personality_completed_\(userId.uuidString)"
        
        // Generate rich notification content based on the analysis results
        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)
        
        // Minimal delay to ensure proper notification center persistence (iOS requirement)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
        } catch {
            // Failed to send analysis notification
        }
    }
    
    
    private func scheduleNotification(for userId: UUID, at date: Date, frequency: AnalysisFrequency) async {
        let identifier = Self.schedulerIdentifierPrefix + userId.uuidString
        
        // Remove existing notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // Create simpler scheduling notification
        let content = UNMutableNotificationContent()
        content.title = "🔍 Checking Your Habits..."
        content.body = "We're analyzing your recent habit patterns for personality insights."
        content.sound = .default
        
        // Add deep link for scheduled analysis
        content.userInfo = [
            "type": "personality_analysis",
            "action": "check_analysis",
            "scheduled": true
        ]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
        } catch {
            // Failed to schedule notification
        }
    }
    
    // MARK: - Persistence
    
    private func saveSchedulerState() {
        let encoder = JSONEncoder()
        
        if let scheduledData = try? encoder.encode(Array(scheduledUsers)) {
            UserDefaults.standard.set(scheduledData, forKey: "personality_scheduler_users")
        }
        
        if let datesData = try? encoder.encode(lastAnalysisDates) {
            UserDefaults.standard.set(datesData, forKey: "personality_scheduler_dates")
        }
        
        if let hashData = try? encoder.encode(lastDataHashes) {
            UserDefaults.standard.set(hashData, forKey: "personality_scheduler_hashes")
        }
    }
    
    private func loadSchedulerState() {
        let decoder = JSONDecoder()
        
        if let scheduledData = UserDefaults.standard.data(forKey: "personality_scheduler_users"),
           let scheduledArray = try? decoder.decode([UUID].self, from: scheduledData) {
            scheduledUsers = Set(scheduledArray)
        }
        
        if let datesData = UserDefaults.standard.data(forKey: "personality_scheduler_dates"),
           let dates = try? decoder.decode([UUID: Date].self, from: datesData) {
            lastAnalysisDates = dates
        }
        
        if let hashData = UserDefaults.standard.data(forKey: "personality_scheduler_hashes"),
           let hashes = try? decoder.decode([UUID: String].self, from: hashData) {
            lastDataHashes = hashes
        }
        
    }
}