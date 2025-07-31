import SwiftUI

struct OnboardingPage4View: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Tips icon
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 16) {
                Text("Learn & Improve")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get expert tips and insights to help you build better habits and maintain long-term consistency.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 16) {
                TipHighlight(
                    icon: "book.fill",
                    title: "Science-Based Tips",
                    description: "Learn proven techniques for habit formation"
                )
                
                TipHighlight(
                    icon: "chart.bar.fill",
                    title: "Track Your Progress",
                    description: "Visualize your journey with streaks and insights"
                )
                
                TipHighlight(
                    icon: "arrow.up.right.circle.fill",
                    title: "Stay Motivated",
                    description: "Discover strategies to maintain momentum"
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

private struct TipHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}