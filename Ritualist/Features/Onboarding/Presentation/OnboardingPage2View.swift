import SwiftUI

struct OnboardingPage2View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: adaptiveSpacing(for: geometry.size.height)) {
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                    
                    // Habits icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        Text("Track Your Habits")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(personalizedGreeting)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, adaptivePadding(for: geometry.size.width))
                    }
                    
                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        FeatureHighlight(
                            icon: "calendar",
                            title: "Daily Tracking",
                            description: "Mark habits as complete each day"
                        )

                        FeatureHighlight(
                            icon: "chart.bar.fill",
                            title: "Progress Visualization",
                            description: "See your streaks and patterns over time"
                        )

                        FeatureHighlight(
                            icon: "bell",
                            title: "Smart Reminders",
                            description: "Get notified when it's time for your habits"
                        )
                    }
                    .padding(.horizontal, adaptivePadding(for: geometry.size.width))

                    // Subtle info badge
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Free plan: 5 habits")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Pro: unlimited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.top, adaptiveSpacing(for: geometry.size.height) / 4)

                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                }
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, adaptivePadding(for: geometry.size.width))
            }
        }
    }
    
    private var personalizedGreeting: String {
        let baseMessage = "Build lasting habits by tracking them daily. Ritualist helps you stay consistent " +
                         "with visual progress tracking and smart reminders."
        
        if !viewModel.userName.isEmpty {
            return "Hi, \(viewModel.userName). \(baseMessage)"
        } else {
            return baseMessage
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

private struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
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
}