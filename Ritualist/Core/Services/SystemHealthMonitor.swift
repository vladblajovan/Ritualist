import Foundation
import Combine
import SwiftUI

// MARK: - Health Check Types

public enum HealthStatus {
    case healthy
    case warning
    case critical
    case unknown
}

public struct HealthCheck {
    public let name: String
    public let status: HealthStatus
    public let message: String
    public let timestamp: Date
    public let duration: TimeInterval
    
    public init(name: String, status: HealthStatus, message: String, duration: TimeInterval = 0) {
        self.name = name
        self.status = status
        self.message = message
        self.timestamp = Date()
        self.duration = duration
    }
}

public struct SystemHealthReport {
    public let overallStatus: HealthStatus
    public let checks: [HealthCheck]
    public let timestamp: Date
    public let totalDuration: TimeInterval
    
    public init(checks: [HealthCheck]) {
        self.checks = checks
        self.timestamp = Date()
        self.totalDuration = checks.reduce(0) { $0 + $1.duration }
        
        // Determine overall status
        if checks.contains(where: { $0.status == .critical }) {
            self.overallStatus = .critical
        } else if checks.contains(where: { $0.status == .warning }) {
            self.overallStatus = .warning
        } else if checks.allSatisfy({ $0.status == .healthy }) {
            self.overallStatus = .healthy
        } else {
            self.overallStatus = .unknown
        }
    }
}

// MARK: - Health Metrics

public struct HealthMetrics {
    public let memoryUsage: Double // MB
    public let diskSpaceAvailable: Double // MB
    public let networkReachability: Bool
    public let userSessionHealth: HealthStatus
    public let dataIntegrityScore: Double // 0.0 to 1.0
    public let lastBackgroundRefresh: Date?
    public let crashCount: Int
    public let errorRate: Double // Errors per minute
    
    public init(
        memoryUsage: Double = 0,
        diskSpaceAvailable: Double = 0,
        networkReachability: Bool = true,
        userSessionHealth: HealthStatus = .unknown,
        dataIntegrityScore: Double = 1.0,
        lastBackgroundRefresh: Date? = nil,
        crashCount: Int = 0,
        errorRate: Double = 0
    ) {
        self.memoryUsage = memoryUsage
        self.diskSpaceAvailable = diskSpaceAvailable
        self.networkReachability = networkReachability
        self.userSessionHealth = userSessionHealth
        self.dataIntegrityScore = dataIntegrityScore
        self.lastBackgroundRefresh = lastBackgroundRefresh
        self.crashCount = crashCount
        self.errorRate = errorRate
    }
}

// MARK: - System Health Monitor Protocol

public protocol SystemHealthMonitorProtocol: ObservableObject {
    var currentHealth: SystemHealthReport? { get }
    var healthMetrics: HealthMetrics { get }
    var isMonitoring: Bool { get }
    
    /// Start continuous health monitoring
    func startMonitoring() async
    
    /// Stop health monitoring
    func stopMonitoring()
    
    /// Perform immediate health check
    func performHealthCheck() async -> SystemHealthReport
    
    /// Get health history for analysis
    func getHealthHistory() -> [SystemHealthReport]
    
    /// Record an error occurrence for tracking
    func recordError(_ error: Error) async
    
    /// Record a crash occurrence
    func recordCrash() async
    
    /// Reset health metrics
    func resetMetrics() async
}

// MARK: - System Health Monitor Implementation

@MainActor
public final class SystemHealthMonitor: SystemHealthMonitorProtocol, ObservableObject {
    
    @Published public private(set) var currentHealth: SystemHealthReport?
    @Published public private(set) var healthMetrics = HealthMetrics()
    @Published public private(set) var isMonitoring = false
    
    // Dependencies
    private let userSession: any UserSessionProtocol
    private let validationService: StateValidationServiceProtocol
    private let logger: DebugLogger
    private let dateProvider: DateProvider
    
    // Monitoring state
    private var monitoringTask: Task<Void, Never>?
    private var healthHistory: [SystemHealthReport] = []
    private let maxHistoryCount = 100
    private let monitoringInterval: TimeInterval = 30 // 30 seconds
    
    // Error tracking
    private var errorLog: [(Error, Date)] = []
    private var crashCount = 0
    private let errorTrackingWindow: TimeInterval = 3600 // 1 hour
    
    nonisolated public init(
        userSession: any UserSessionProtocol,
        validationService: StateValidationServiceProtocol,
        logger: DebugLogger,
        dateProvider: DateProvider
    ) {
        self.userSession = userSession
        self.validationService = validationService
        self.logger = logger
        self.dateProvider = dateProvider
    }
    
    deinit {
        Task { @MainActor in
            stopMonitoring()
        }
    }
    
    // MARK: - Monitoring Control
    
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.log("System health monitoring started")
        
        // Perform initial health check
        currentHealth = await performHealthCheck()
        
        // Start continuous monitoring
        monitoringTask = Task { [weak self] in
            while let self = self, !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(self.monitoringInterval * 1_000_000_000))
                    
                    _ = await MainActor.run {
                        Task { [weak self] in
                            guard let self = self else { return }
                            self.currentHealth = await self.performHealthCheck()
                        }
                    }
                } catch {
                    break
                }
            }
        }
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
        
        logger.log("System health monitoring stopped")
    }
    
    // MARK: - Health Checks
    
    public func performHealthCheck() async -> SystemHealthReport {
        let startTime = dateProvider.now
        logger.log("Performing system health check")
        
        // Collect all health checks
        let checks = await withTaskGroup(of: HealthCheck.self) { group in
            var results: [HealthCheck] = []
            
            // User session health
            group.addTask { await self.checkUserSessionHealth() }
            
            // Data integrity
            group.addTask { await self.checkDataIntegrity() }
            
            // System resources
            group.addTask { await self.checkSystemResources() }
            
            // Network connectivity
            group.addTask { await self.checkNetworkHealth() }
            
            // Error rates
            group.addTask { await self.checkErrorRates() }
            
            // Performance metrics
            group.addTask { await self.checkPerformanceMetrics() }
            
            for await result in group {
                results.append(result)
            }
            
            return results
        }
        
        let report = SystemHealthReport(checks: checks)
        
        // Update health history
        healthHistory.append(report)
        if healthHistory.count > maxHistoryCount {
            healthHistory.removeFirst()
        }
        
        // Update health metrics
        await updateHealthMetrics(from: report)
        
        let endTime = dateProvider.now
        let duration = endTime.timeIntervalSince(startTime)
        
        logger.log("Health check completed in \(String(format: "%.2f", duration))s - Status: \(report.overallStatus)")
        
        return report
    }
    
    // MARK: - Individual Health Checks
    
    private func checkUserSessionHealth() async -> HealthCheck {
        let startTime = Date()
        
        let validation = await validationService.validateUserSession(userSession.currentUser)
        
        let status: HealthStatus
        let message: String
        
        if validation.isValid {
            status = .healthy
            message = "User session is healthy"
        } else if validation.errors.count > 2 {
            status = .critical
            message = "Critical user session issues: \(validation.errors.count) errors"
        } else {
            status = .warning
            message = "User session warnings: \(validation.errors.count) errors, \(validation.warnings.count) warnings"
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return HealthCheck(name: "User Session", status: status, message: message, duration: duration)
    }
    
    private func checkDataIntegrity() async -> HealthCheck {
        let startTime = Date()
        
        let validation = await validationService.checkDataIntegrity()
        
        let status: HealthStatus
        let message: String
        
        if validation.isValid {
            status = .healthy
            message = "Data integrity verified"
        } else if validation.errors.count > 1 {
            status = .critical
            message = "Data integrity violations detected: \(validation.errors.count) errors"
        } else {
            status = .warning
            message = "Minor data integrity issues: \(validation.warnings.count) warnings"
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return HealthCheck(name: "Data Integrity", status: status, message: message, duration: duration)
    }
    
    private func checkSystemResources() async -> HealthCheck {
        let startTime = Date()
        
        let memoryUsage = getMemoryUsage()
        let diskSpace = getDiskSpaceAvailable()
        
        let status: HealthStatus
        let message: String
        
        if memoryUsage > 500 { // 500MB threshold
            status = .critical
            message = "High memory usage: \(String(format: "%.1f", memoryUsage))MB"
        } else if diskSpace < 100 { // 100MB threshold
            status = .warning
            message = "Low disk space: \(String(format: "%.1f", diskSpace))MB available"
        } else if memoryUsage > 200 { // 200MB threshold
            status = .warning
            message = "Elevated memory usage: \(String(format: "%.1f", memoryUsage))MB"
        } else {
            status = .healthy
            message = "System resources normal"
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return HealthCheck(name: "System Resources", status: status, message: message, duration: duration)
    }
    
    private func checkNetworkHealth() async -> HealthCheck {
        let startTime = Date()
        
        // Simple network check - in production this could be more sophisticated
        let isReachable = await checkNetworkReachability()
        
        let status: HealthStatus = isReachable ? .healthy : .critical
        let message = isReachable ? "Network connectivity available" : "No network connectivity"
        
        let duration = Date().timeIntervalSince(startTime)
        return HealthCheck(name: "Network", status: status, message: message, duration: duration)
    }
    
    private func checkErrorRates() async -> HealthCheck {
        let startTime = Date()
        
        let errorRate = calculateErrorRate()
        
        let status: HealthStatus
        let message: String
        
        if errorRate > 10 { // More than 10 errors per minute
            status = .critical
            message = "High error rate: \(String(format: "%.1f", errorRate)) errors/min"
        } else if errorRate > 2 { // More than 2 errors per minute
            status = .warning
            message = "Elevated error rate: \(String(format: "%.1f", errorRate)) errors/min"
        } else {
            status = .healthy
            message = "Error rate normal: \(String(format: "%.1f", errorRate)) errors/min"
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return HealthCheck(name: "Error Rate", status: status, message: message, duration: duration)
    }
    
    private func checkPerformanceMetrics() async -> HealthCheck {
        let startTime = Date()
        
        // Check if we have recent performance issues
        let recentReports = healthHistory.suffix(5)
        let averageDuration = recentReports.isEmpty ? 0 : recentReports.reduce(0) { $0 + $1.totalDuration } / TimeInterval(recentReports.count)
        
        let status: HealthStatus
        let message: String
        
        if averageDuration > 5.0 { // Health checks taking more than 5 seconds
            status = .warning
            message = "Performance degraded: \(String(format: "%.2f", averageDuration))s avg check time"
        } else {
            status = .healthy
            message = "Performance normal: \(String(format: "%.2f", averageDuration))s avg check time"
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return HealthCheck(name: "Performance", status: status, message: message, duration: duration)
    }
    
    // MARK: - Health Metrics Updates
    
    private func updateHealthMetrics(from report: SystemHealthReport) async {
        let userSessionHealth = report.checks.first { $0.name == "User Session" }?.status ?? .unknown
        let dataIntegrityCheck = report.checks.first { $0.name == "Data Integrity" }?.status
        let dataIntegrityScore = dataIntegrityCheck == .healthy ? 1.0 : (dataIntegrityCheck == .warning ? 0.7 : 0.3)
        
        healthMetrics = HealthMetrics(
            memoryUsage: getMemoryUsage(),
            diskSpaceAvailable: getDiskSpaceAvailable(),
            networkReachability: await checkNetworkReachability(),
            userSessionHealth: userSessionHealth,
            dataIntegrityScore: dataIntegrityScore,
            lastBackgroundRefresh: dateProvider.now,
            crashCount: crashCount,
            errorRate: calculateErrorRate()
        )
    }
    
    // MARK: - Error Tracking
    
    public func recordError(_ error: Error) async {
        let now = Date()
        
        // Clean old errors outside tracking window
        cleanOldErrors(before: now.addingTimeInterval(-errorTrackingWindow))
        
        // Add new error
        errorLog.append((error, now))
        
        logger.log("Error recorded: \(error.localizedDescription)")
    }
    
    public func recordCrash() async {
        crashCount += 1
        logger.log("Crash recorded. Total crashes: \(crashCount)")
    }
    
    public func resetMetrics() async {
        errorLog.removeAll()
        crashCount = 0
        healthHistory.removeAll()
        healthMetrics = HealthMetrics()
        
        logger.log("Health metrics reset")
    }
    
    // MARK: - History Access
    
    public func getHealthHistory() -> [SystemHealthReport] {
        return healthHistory
    }
    
    // MARK: - Utility Methods
    
    private func getMemoryUsage() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(taskInfo.phys_footprint) / (1024 * 1024) // Convert to MB
        }
        
        return 0
    }
    
    private func getDiskSpaceAvailable() -> Double {
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return Double(capacity) / (1024 * 1024) // Convert to MB
            }
        } catch {
            logger.log("Failed to get disk space: \(error.localizedDescription)")
        }
        
        return 0
    }
    
    private func checkNetworkReachability() async -> Bool {
        // Simplified network check - in production you'd use Network framework
        return true
    }
    
    private func calculateErrorRate() -> Double {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        let recentErrors = errorLog.filter { $0.1 > oneMinuteAgo }
        return Double(recentErrors.count)
    }
    
    private func cleanOldErrors(before date: Date) {
        errorLog.removeAll { $0.1 < date }
    }
}