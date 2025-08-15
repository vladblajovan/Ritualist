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
                .font(.system(size: 15, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(isSelected ? (color ?? AppColors.brand) : Color(.secondarySystemBackground))
        )
        .foregroundColor(
            isSelected ? .white : .primary
        )
    }
}
