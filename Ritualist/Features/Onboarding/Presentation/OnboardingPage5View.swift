import SwiftUI

struct OnboardingPage5View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Notification icon
            Image(systemName: viewModel.hasGrantedNotifications ? "bell.fill" : "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(viewModel.hasGrantedNotifications ? .blue : .red)
                .animation(.easeInOut, value: viewModel.hasGrantedNotifications)
            
            VStack(spacing: 16) {
                Text("Stay on Track")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Enable notifications to get gentle reminders for your habits. You can customize " +
                     "or disable them anytime in settings.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 20) {
                NotificationBenefit(
                    icon: "clock",
                    title: "Timely Reminders",
                    description: "Get notified at the perfect time for each habit"
                )
                
                NotificationBenefit(
                    icon: "checkmark.circle",
                    title: "Stay Consistent",
                    description: "Never forget to complete your daily routines"
                )
                
                NotificationBenefit(
                    icon: "gear",
                    title: "Fully Customizable",
                    description: "Turn off or adjust notifications anytime"
                )
                
                // Notification permission button
                if !viewModel.hasGrantedNotifications {
                    Button("Enable Notifications") {
                        Task {
                            await viewModel.requestNotificationPermission()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.top, 8)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications Enabled")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 20)
            
            if !viewModel.hasGrantedNotifications {
                Text("You can skip this step and enable notifications later in settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

private struct NotificationBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
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