import SwiftUI

struct OnboardingPage3View: View {
    var body: some View {
        VStack(spacing: Spacing.xxlarge) {
            Spacer()
            
            // Customization icon
            Image(systemName: "paintbrush.fill")
                .font(.system(size: Typography.heroIcon))
                .foregroundColor(.purple)
            
            VStack(spacing: Spacing.large) {
                Text("Make It Yours")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Customize your habits with colors, emojis, and flexible scheduling to match " +
                     "your lifestyle and preferences.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.extraLarge)
            }
            
            VStack(spacing: Spacing.large) {
                CustomizationHighlight(
                    icon: "paintpalette.fill",
                    title: "Colors & Emojis",
                    description: "Personalize each habit with colors and emojis"
                )
                
                CustomizationHighlight(
                    icon: "calendar",
                    title: "Flexible Scheduling",
                    description: "Daily, weekly, or custom schedules that fit you"
                )
                
                CustomizationHighlight(
                    icon: "target",
                    title: "Set Your Goals",
                    description: "Binary tracking or numeric targets with units"
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

private struct CustomizationHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
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
