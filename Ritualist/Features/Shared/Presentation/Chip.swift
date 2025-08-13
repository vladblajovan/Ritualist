import SwiftUI
import RitualistCore

public struct Chip: View {
    let text: String
    let emoji: String?
    let color: Color?
    let isSelected: Bool
    
    public init(
        text: String,
        emoji: String? = nil,
        color: Color? = nil,
        isSelected: Bool = false
    ) {
        self.text = text
        self.emoji = emoji
        self.color = color
        self.isSelected = isSelected
    }
    
    public var body: some View {
        HStack(spacing: Spacing.small) {
            if let emoji = emoji {
                Text(emoji)
            }
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            isSelected ? (color ?? AppColors.brand) : .gray.opacity(0.1),
            in: Capsule()
        )
        .foregroundColor(
            isSelected ? .white : .primary
        )
    }
}
