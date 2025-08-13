import Foundation

// MARK: - Error Event Model

public struct ErrorEvent {
    public let id: UUID
    public let error: Error
    public let context: String
    public let timestamp: Date
    public let userId: String?
    public let additionalProperties: [String: Any]
    
    public init(
        error: Error,
        context: String,
        timestamp: Date = Date(),
        userId: String? = nil,
        additionalProperties: [String: Any] = [:]
    ) {
        self.id = UUID()
        self.error = error
        self.context = context
        self.timestamp = timestamp
        self.userId = userId
        self.additionalProperties = additionalProperties
    }
}

// MARK: - Error Handling Actor

public actor ErrorHandlingActor {
    private var errorLog: [ErrorEvent] = []
    private let maxLogSize: Int
    private let analyticsEnabled: Bool
    
    public init(maxLogSize: Int = 1000, analyticsEnabled: Bool = true) {
        self.maxLogSize = maxLogSize
        self.analyticsEnabled = analyticsEnabled
    }
    
    // MARK: - Public Interface
    
    /// Log an error with context and optional user information
    public func logError(
        _ error: Error,
        context: String,
        userId: String? = nil,
        additionalProperties: [String: Any] = [:]
    ) async {
        let event = ErrorEvent(
            error: error,
            context: context,
            userId: userId,
            additionalProperties: additionalProperties
        )
        
        // Add to internal log
        errorLog.append(event)
        
        // Trim log if it exceeds max size
        if errorLog.count > maxLogSize {
            errorLog.removeFirst(errorLog.count - maxLogSize)
        }
        
        // Send to analytics if enabled
        if analyticsEnabled {
            await sendToAnalytics(event)
        }
        
        // Log to console for debugging
        await logToConsole(event)
    }
    
    /// Get recent errors with optional filtering
    public func getRecentErrors(
        limit: Int = 50,
        context: String? = nil,
        userId: String? = nil
    ) async -> [ErrorEvent] {
        var filteredEvents = errorLog
        
        // Filter by context if provided
        if let context = context {
            filteredEvents = filteredEvents.filter { $0.context == context }
        }
        
        // Filter by userId if provided
        if let userId = userId {
            filteredEvents = filteredEvents.filter { $0.userId == userId }
        }
        
        // Return most recent first
        return Array(filteredEvents.suffix(limit).reversed())
    }
    
    /// Get error statistics
    public func getErrorStatistics() async -> ErrorStatistics {
        let now = Date()
        let last24Hours = now.addingTimeInterval(-24 * 60 * 60)
        let lastHour = now.addingTimeInterval(-60 * 60)
        
        let recent24h = errorLog.filter { $0.timestamp >= last24Hours }
        let recentHour = errorLog.filter { $0.timestamp >= lastHour }
        
        // Count errors by context
        var contextCounts: [String: Int] = [:]
        for event in recent24h {
            contextCounts[event.context, default: 0] += 1
        }
        
        return ErrorStatistics(
            totalErrors: errorLog.count,
            errorsLast24Hours: recent24h.count,
            errorsLastHour: recentHour.count,
            topErrorContexts: contextCounts.sorted { $0.value > $1.value }
        )
    }
    
    /// Clear old errors (cleanup method)
    public func clearOldErrors(olderThan days: Int) async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        errorLog = errorLog.filter { $0.timestamp >= cutoffDate }
    }
    
    // MARK: - Private Methods
    
    private func sendToAnalytics(_ event: ErrorEvent) async {
        // TODO: Integrate with actual analytics service
        // For now, we'll simulate analytics sending
        
        #if DEBUG
        // In debug, just log that we would send analytics
        print("📊 [Analytics] Would send error event: \(event.context) - \(event.error.localizedDescription)")
        #else
        // In production, integrate with real analytics
        // Example: await analyticsService.trackError(event)
        #endif
    }
    
    private func logToConsole(_ event: ErrorEvent) async {
        let timestamp = DateFormatter.errorLogFormatter.string(from: event.timestamp)
        let userInfo = event.userId != nil ? " [User: \(event.userId!)]" : ""
        let properties = event.additionalProperties.isEmpty ? "" : " \(event.additionalProperties)"
        
        print("🚨 [Error] \(timestamp) [\(event.context)]\(userInfo) \(event.error.localizedDescription)\(properties)")
        
        // Also print stack trace in debug mode
        #if DEBUG
        if let nsError = event.error as NSError? {
            print("   Stack: \(nsError.userInfo)")
        }
        #endif
    }
}

// MARK: - Error Statistics

public struct ErrorStatistics {
    public let totalErrors: Int
    public let errorsLast24Hours: Int
    public let errorsLastHour: Int
    public let topErrorContexts: [(key: String, value: Int)]
    
    public var errorRate24h: Double {
        Double(errorsLast24Hours) / 24.0 // errors per hour
    }
    
    public var isHighErrorRate: Bool {
        errorRate24h > 5.0 // More than 5 errors per hour
    }
    
    public init(totalErrors: Int, errorsLast24Hours: Int, errorsLastHour: Int, topErrorContexts: [(key: String, value: Int)]) {
        self.totalErrors = totalErrors
        self.errorsLast24Hours = errorsLast24Hours
        self.errorsLastHour = errorsLastHour
        self.topErrorContexts = topErrorContexts
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let errorLogFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Error Context Constants

public struct ErrorContext {
    public static let paywall = "paywall"
    public static let dataLayer = "data_layer"
    public static let networking = "networking"
    public static let persistence = "persistence"
    public static let authentication = "authentication"
    public static let userInterface = "user_interface"
    public static let analytics = "analytics"
    public static let notifications = "notifications"
    public static let sync = "sync"
    public static let personalityAnalysis = "personality_analysis"
}

// MARK: - Data Source Errors

public enum CategoryDataSourceError: Error {
    case categoryAlreadyExists
    case categoryNotFound
}