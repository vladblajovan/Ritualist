import SwiftUI

struct OnboardingPage6View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: adaptiveSpacing(for: geometry.size.height)) {
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)

                    // Permission icons
                    HStack(spacing: 20) {
                        Image(systemName: viewModel.hasGrantedNotifications ? "bell.fill" : "bell.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(viewModel.hasGrantedNotifications ? .blue : .secondary)
                            .animation(.easeInOut, value: viewModel.hasGrantedNotifications)

                        Image(systemName: viewModel.hasGrantedLocation ? "location.fill" : "location.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(viewModel.hasGrantedLocation ? .green : .secondary)
                            .animation(.easeInOut, value: viewModel.hasGrantedLocation)
                    }

                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        Text("Stay on Track")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Enable notifications and location-aware habits to get reminders at the right time and place. " +
                             "You can customize or disable them anytime in settings.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, adaptivePadding(for: geometry.size.width))
                    }
                    
                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        NotificationBenefit(
                            icon: "clock",
                            title: "Timely Reminders",
                            description: "Get notified at the perfect time for each habit"
                        )

                        NotificationBenefit(
                            icon: "location.circle.fill",
                            title: "Location-Aware Habits",
                            description: "Get reminders when you arrive at specific places"
                        )

                        NotificationBenefit(
                            icon: "checkmark.circle",
                            title: "Stay Consistent",
                            description: "Never forget to complete your daily routines"
                        )

                        NotificationBenefit(
                            icon: "gear",
                            title: "Fully Customizable",
                            description: "Turn off or adjust permissions anytime"
                        )

                        // Permission buttons
                        VStack(spacing: 12) {
                            // Notification permission button
                            if !viewModel.hasGrantedNotifications {
                                Button {
                                    Task {
                                        await viewModel.requestNotificationPermission()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "bell.fill")
                                        Text("Enable Notifications")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Notifications Enabled")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.green)
                            }

                            // Location permission button
                            if !viewModel.hasGrantedLocation {
                                Button {
                                    Task {
                                        await viewModel.requestLocationPermission()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "location.fill")
                                        Text("Enable Location-Aware Habits")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Location-Aware Habits Enabled")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.green)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, adaptivePadding(for: geometry.size.width))

                    if !viewModel.hasGrantedNotifications || !viewModel.hasGrantedLocation {
                        Text("You can skip and enable permissions later in settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, adaptivePadding(for: geometry.size.width) * 2)
                    }
                    
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                }
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, adaptivePadding(for: geometry.size.width))
            }
        }
        .task {
            // Check permissions when page loads (handles pre-granted permissions)
            await viewModel.checkPermissions()
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