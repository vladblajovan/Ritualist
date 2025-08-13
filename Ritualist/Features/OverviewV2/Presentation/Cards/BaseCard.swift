import SwiftUI
import RitualistCore

/// Protocol defining the structure for Overview cards (simplified)
protocol OverviewCardData {
    /// Whether the card should be visible based on current state
    var shouldShow: Bool { get }
}
