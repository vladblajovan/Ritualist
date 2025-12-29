import SwiftUI
import RitualistCore

public struct Chip: View {
    let text: String
    let emoji: String?
    let color: Color?
    let unselectedBackgroundColor: Color
    let isSelected: Bool
    let accessibilityIdentifier: String?

    // Scaled padding for Dynamic Type support
    @ScaledMetric(relativeTo: .subheadline) private var horizontalPadding: CGFloat = 20
    @ScaledMetric(relativeTo: .subheadline) private var verticalPadding: CGFloat = 12

    public init(
        text: String,
        emoji: String? = nil,
        color: Color? = nil,
        unselectedBackgroundColor: Color = AppColors.chipUnselectedBackground,
        isSelected: Bool = false,
        accessibilityIdentifier: String? = nil
    ) {
        self.text = text
        self.emoji = emoji
        self.color = color
        self.unselectedBackgroundColor = unselectedBackgroundColor
        self.isSelected = isSelected
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    public var body: some View {
        HStack(spacing: Spacing.small) {
            if let emoji = emoji {
                Text(emoji)
                    .accessibilityHidden(true) // Decorative emoji
            }
            Text(text)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(isSelected ? (color ?? AppColors.brand) : unselectedBackgroundColor)
        )
        .foregroundColor(
            isSelected ? .white : .primary
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text)\(isSelected ? ", selected" : "")")
        .accessibilityHint("Double-tap to \(isSelected ? "deselect" : "select")")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(accessibilityIdentifier ?? "chip_\(text)")
    }
}
