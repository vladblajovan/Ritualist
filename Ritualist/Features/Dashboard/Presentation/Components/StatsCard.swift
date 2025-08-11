import SwiftUI

public struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public init(title: String, value: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    HStack {
        StatsCard(
            title: "Total Habits",
            value: "12",
            icon: "list.bullet",
            color: .blue
        )
        
        StatsCard(
            title: "Completed Today",
            value: "8",
            icon: "checkmark.circle.fill",
            color: .green
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}