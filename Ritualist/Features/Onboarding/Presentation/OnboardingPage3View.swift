import SwiftUI
import RitualistCore

struct OnboardingPage3View: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: adaptiveSpacing(for: geometry.size.height)) {
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                    
                    // Customization icon
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: Typography.heroIcon))
                        .foregroundColor(.purple)
                    
                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        Text("Make It Yours")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Customize your habits with colors, emojis, and flexible scheduling to match " +
                             "your lifestyle and preferences.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, adaptivePadding(for: geometry.size.width))
                    }
                    
                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
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
        default: return Spacing.xxlarge  // Large screens - original spacing
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
        default: return Spacing.xxlarge  // Large screens - original spacing
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
