import SwiftUI

struct OnboardingPage2View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Habits icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("Track Your Habits")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(personalizedGreeting)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 16) {
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
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
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
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}