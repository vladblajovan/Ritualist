//
//  PersonalityAnalysisScheduler.swift
//  RitualistCore
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Service responsible for scheduling automatic personality analysis based on user preferences
/// Uses actor isolation to ensure thread-safe access to mutable state (scheduledUsers, lastAnalysisDates, etc.)
public actor PersonalityAnalysisScheduler: PersonalityAnalysisSchedulerProtocol {
    
    // MARK: - Dependencies

    private let personalityRepository: PersonalityAnalysisRepositoryProtocol
    private let analyzePersonalityUseCase: AnalyzePersonalityUseCase
    private let validateAnalysisDataUseCase: ValidateAnalysisDataUseCase
    private let notificationService: NotificationService
    private let userDefaults: UserDefaultsService
    private let errorHandler: ErrorHandler?
    private let logger: DebugLogger
    
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
        notificationService: NotificationService,
        userDefaults: UserDefaultsService = DefaultUserDefaultsService(),
        errorHandler: ErrorHandler? = nil,
        logger: DebugLogger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "personality")
    ) {
        self.personalityRepository = personalityRepository
        self.analyzePersonalityUseCase = analyzePersonalityUseCase
        self.validateAnalysisDataUseCase = validateAnalysisDataUseCase
        self.notificationService = notificationService
        self.userDefaults = userDefaults
        self.errorHandler = errorHandler
        self.logger = logger

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
        await notificationService.cancelPersonalityAnalysis(userId: userId)
        
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
        do {
            // Get user preferences
            guard let preferences = try await personalityRepository.getAnalysisPreferences(for: userId),
                  preferences.isCurrentlyActive else {
                return
            }
            
            // Check if user has sufficient data
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            if !eligibility.isEligible {
                return
            }
            
            await performAnalysis(for: userId)
            
            let endTimestamp = Date().timeIntervalSince1970
            
        } catch {
            logger.log("Error during forced manual analysis: \(error)", level: .error, category: .personality)
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
        
        // Schedule notification using the protocol service
        do {
            try await notificationService.schedulePersonalityAnalysis(
                userId: userId, 
                at: nextAnalysisDate, 
                frequency: preferences.analysisFrequency
            )
        } catch {
            // Failed to schedule notification
        }
    }
    
    private func calculateNextAnalysisDate(from lastDate: Date, frequency: AnalysisFrequency) -> Date {
        let now = Date()

        let nextDate: Date
        switch frequency {
        case .daily:
            nextDate = CalendarUtils.addDaysLocal(1, to: lastDate, timezone: .current)
        case .weekly:
            nextDate = CalendarUtils.addWeeksLocal(1, to: lastDate, timezone: .current)
        case .monthly:
            nextDate = CalendarUtils.addMonthsLocal(1, to: lastDate, timezone: .current)
        case .manual:
            return Date.distantFuture // Never automatically schedule
        }

        // Ensure next date is in the future (addMinutes is timezone-agnostic)
        return max(nextDate, CalendarUtils.addMinutes(5, to: now))
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
            try await notificationService.sendPersonalityAnalysisCompleted(userId: userId, profile: profile)
            
            // Schedule next analysis
            if let preferences = try await personalityRepository.getAnalysisPreferences(for: userId) {
                await scheduleNextAnalysis(for: userId, preferences: preferences)
            }
            
        } catch {
            // Failed automatic personality analysis - fail silently
            // No notifications for insufficient data scenarios
        }
    }
    
    // MARK: - Persistence
    
    private func saveSchedulerState() {
        let encoder = JSONEncoder()

        if let scheduledData = try? encoder.encode(Array(scheduledUsers)) {
            userDefaults.set(scheduledData, forKey: UserDefaultsKeys.personalitySchedulerUsers)
        }

        if let datesData = try? encoder.encode(lastAnalysisDates) {
            userDefaults.set(datesData, forKey: UserDefaultsKeys.personalitySchedulerDates)
        }

        if let hashData = try? encoder.encode(lastDataHashes) {
            userDefaults.set(hashData, forKey: UserDefaultsKeys.personalitySchedulerHashes)
        }
    }

    private func loadSchedulerState() {
        let decoder = JSONDecoder()

        if let scheduledData = userDefaults.data(forKey: UserDefaultsKeys.personalitySchedulerUsers),
           let scheduledArray = try? decoder.decode([UUID].self, from: scheduledData) {
            scheduledUsers = Set(scheduledArray)
        }

        if let datesData = userDefaults.data(forKey: UserDefaultsKeys.personalitySchedulerDates),
           let dates = try? decoder.decode([UUID: Date].self, from: datesData) {
            lastAnalysisDates = dates
        }

        if let hashData = userDefaults.data(forKey: UserDefaultsKeys.personalitySchedulerHashes),
           let hashes = try? decoder.decode([UUID: String].self, from: hashData) {
            lastDataHashes = hashes
        }
    }
}