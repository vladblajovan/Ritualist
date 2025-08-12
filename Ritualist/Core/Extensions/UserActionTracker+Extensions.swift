import Foundation
import RitualistCore

public extension UserActionTrackerService {
    /// Convenience method to track errors with context
    func trackError(_ error: Error, context: String, additionalProperties: [String: Any] = [:]) {
        var properties = additionalProperties
        properties["error_type"] = String(describing: type(of: error))
        properties["error_description"] = error.localizedDescription
        
        track(.errorOccurred(error: error.localizedDescription, context: context), context: properties)
    }
    
    /// Track performance metrics with proper formatting
    func trackPerformance(metric: String, value: Double, unit: String, additionalProperties: [String: Any] = [:]) {
        track(.performanceMetric(metric: metric, value: value, unit: unit), context: additionalProperties)
    }
    
    /// Track crash reports
    func trackCrash(_ error: Error, additionalProperties: [String: Any] = [:]) {
        var properties = additionalProperties
        properties["error_type"] = String(describing: type(of: error))
        
        track(.crashReported(error: error.localizedDescription), context: properties)
    }
}