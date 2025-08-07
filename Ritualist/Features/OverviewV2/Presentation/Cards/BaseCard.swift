import SwiftUI

/// Protocol defining the structure for Overview cards (simplified)
protocol OverviewCardData {
    /// Whether the card should be visible based on current state
    var shouldShow: Bool { get }
}

/// Shared card styling modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(CardDesign.cardPadding)
            .background(CardDesign.cardBackground)
            .cornerRadius(CardDesign.cornerRadius)
            .shadow(color: CardDesign.shadowColor, radius: CardDesign.shadowRadius, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

/// Card colors and design tokens
struct CardDesign {
    static let cornerRadius: CGFloat = 16
    static let shadowColor = Color.black.opacity(0.05)
    static let shadowRadius: CGFloat = 5
    static let cardPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 16
    
    // Progress colors
    static let progressGreen = Color(hex: "#4CAF50") ?? .green
    static let progressOrange = Color(hex: "#FF9800") ?? .orange
    static let progressRed = Color(hex: "#F44336") ?? .red
    
    // Background colors
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.systemGray6)
}