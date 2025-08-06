import SwiftUI

struct OnboardingPage4View: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: adaptiveSpacing(for: geometry.size.height)) {
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                    
                    // Tips icon
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        Text("Learn & Improve")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Get expert tips and insights to help you build better habits and maintain long-term consistency.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, adaptivePadding(for: geometry.size.width))
                    }
                    
                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
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
                    .padding(.horizontal, adaptivePadding(for: geometry.size.width))
                    
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                }
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, adaptivePadding(for: geometry.size.width))
            }
        }
    }
    
    private func adaptiveSpacing(for height: CGFloat) -> CGFloat {
        switch height {
        case 0..<600: return 16  // Small screens - compact spacing
        case 600..<750: return 24  // Medium screens
        default: return 32  // Large screens - original spacing
        }
    }
    
    private func adaptivePadding(for width: CGFloat) -> CGFloat {
        switch width {
        case 0..<350: return 16  // Small screens
        case 350..<400: return 20  // Medium screens  
        default: return 24  // Large screens - original padding
        }
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
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    private func adaptiveSpacing(for height: CGFloat) -> CGFloat {
        switch height {
        case 0..<600: return 16  // Small screens - compact spacing
        case 600..<750: return 24  // Medium screens
        default: return 32  // Large screens - original spacing
        }
    }
    
    private func adaptivePadding(for width: CGFloat) -> CGFloat {
        switch width {
        case 0..<350: return 16  // Small screens
        case 350..<400: return 20  // Medium screens  
        default: return 24  // Large screens - original padding
        }
    }
}