import SwiftUI
import RitualistCore

/// Protocol defining the structure for Overview cards (simplified)
protocol OverviewCardData {
    /// Whether the card should be visible based on current state
    var shouldShow: Bool { get }
}

// Note: CardDesign and cardStyle() are now available from Core/DesignSystem/CardDesign.swift
// This provides unified styling across the entire app