//
//  RefreshTrigger.swift
//  Ritualist
//
//  Created by Claude on 30.07.2025.
//

import SwiftUI

public final class RefreshTrigger: ObservableObject {
    @Published public var overviewNeedsRefresh = false
    @Published public var habitCountNeedsRefresh = false
    
    public init() {}
    
    @MainActor
    public func triggerOverviewRefresh() {
        overviewNeedsRefresh = true
    }
    
    @MainActor
    public func resetOverviewRefresh() {
        overviewNeedsRefresh = false
    }
    
    @MainActor
    public func triggerHabitCountRefresh() {
        habitCountNeedsRefresh = true
    }
    
    @MainActor
    public func resetHabitCountRefresh() {
        habitCountNeedsRefresh = false
    }
}

// Environment key for refresh trigger
private struct RefreshTriggerKey: EnvironmentKey {
    static let defaultValue = RefreshTrigger()
}

public extension EnvironmentValues {
    var refreshTrigger: RefreshTrigger {
        get { self[RefreshTriggerKey.self] }
        set { self[RefreshTriggerKey.self] = newValue }
    }
}