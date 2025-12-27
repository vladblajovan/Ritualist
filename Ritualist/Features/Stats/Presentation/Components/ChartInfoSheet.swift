import SwiftUI
import RitualistCore

/// A reusable info sheet for explaining chart data
struct ChartInfoSheet: View {
    let title: String
    let icon: String
    let description: String
    let details: [String]
    let example: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.brand.opacity(0.12))
                                .frame(width: 56, height: 56)

                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(AppColors.brand)
                        }

                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Description
                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How it works")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ForEach(details, id: \.self) { detail in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.green)

                                Text(detail)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Example
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.body)
                                .foregroundColor(.yellow)

                            Text(example)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.1))
                        )
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("About This Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ChartInfoSheet(
        title: "Progress Trend",
        icon: "chart.line.uptrend.xyaxis",
        description: "Shows your daily habit completion rate over time.",
        details: [
            "Each point represents your completion percentage for a specific date",
            "The line shows how your performance changes day by day",
            "Use this to spot trends - are you improving or declining over time?"
        ],
        example: "If you completed 3 of 5 habits on Dec 20, that day shows as 60%"
    )
}
