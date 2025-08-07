import SwiftUI

struct InspirationCard: View {
    let message: String
    let slogan: String
    let timeOfDay: TimeOfDay
    let completionPercentage: Double
    let shouldShow: Bool
    let onDismiss: () -> Void
    
    init(message: String, slogan: String, timeOfDay: TimeOfDay, completionPercentage: Double = 0.0, shouldShow: Bool = true, onDismiss: @escaping () -> Void) {
        self.message = message
        self.slogan = slogan
        self.timeOfDay = timeOfDay
        self.completionPercentage = completionPercentage
        self.shouldShow = shouldShow
        self.onDismiss = onDismiss
    }
    
    private var contextualStyle: (gradient: LinearGradient, icon: String, color: Color) {
        // Enhanced context-aware styling
        if completionPercentage >= 1.0 {
            // Perfect day celebration
            return (
                LinearGradient(
                    colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                "party.popper.fill",
                .green
            )
        } else if completionPercentage >= 0.75 {
            // Strong progress celebration
            return (
                LinearGradient(
                    colors: [Color.blue.opacity(0.18), Color.cyan.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                "flame.fill",
                .blue
            )
        } else if completionPercentage >= 0.5 {
            // Midway encouragement
            return (
                LinearGradient(
                    colors: [Color.orange.opacity(0.16), Color.yellow.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                "bolt.fill",
                .orange
            )
        } else {
            // Time-based motivation
            switch timeOfDay {
            case .morning:
                return (
                    LinearGradient(
                        colors: [Color.pink.opacity(0.15), Color.orange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    "sunrise.fill",
                    .pink
                )
            case .noon:
                return (
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.15), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    "sun.max.fill",
                    .indigo
                )
            case .evening:
                return (
                    LinearGradient(
                        colors: [Color.purple.opacity(0.15), Color.indigo.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    "moon.stars.fill",
                    .purple
                )
            }
        }
    }
    
    private var backgroundGradient: LinearGradient {
        contextualStyle.gradient
    }
    
    private var iconName: String {
        contextualStyle.icon
    }
    
    private var iconColor: Color {
        contextualStyle.color
    }
    
    private var contextualMessage: String {
        // Use the personalized message passed from the ViewModel
        return message
    }
    
    var body: some View {
        if shouldShow {
            VStack(spacing: 0) {
                HStack {
                    // Time-based icon
                    Image(systemName: iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: shouldShow)
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: onDismiss) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Main content
                VStack(spacing: 12) {
                    Text(contextualMessage)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                    
                    // Show original slogan as subtitle when message and slogan are different
                    if contextualMessage != slogan && !slogan.isEmpty {
                        Text(slogan)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(iconColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .italic()
                            .padding(.horizontal, 20)
                    }
                    
                    // Subtle animation dots
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(iconColor.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .scaleEffect(1.0)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: shouldShow
                                )
                        }
                    }
                    .padding(.bottom, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                backgroundGradient
                    .clipShape(RoundedRectangle(cornerRadius: CardDesign.cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                    .stroke(iconColor.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: iconColor.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(shouldShow ? 1.0 : 0.95)
            .opacity(shouldShow ? 1.0 : 0.0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1),
                value: shouldShow
            )
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                )
            )
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        InspirationCard(
            message: "Good morning! Ready to make today incredible?",
            slogan: "Rise with purpose, rule your day.",
            timeOfDay: .morning,
            completionPercentage: 0.0,
            shouldShow: true,
            onDismiss: { }
        )
        
        InspirationCard(
            message: "Amazing progress! You're at the halfway mark. Your consistency is paying off! 🎯",
            slogan: "Midday momentum, unstoppable force.",
            timeOfDay: .noon,
            completionPercentage: 0.6,
            shouldShow: true,
            onDismiss: { }
        )
        
        InspirationCard(
            message: "🎊 Perfect day complete! You've shown incredible dedication and consistency!",
            slogan: "End strong, dream bigger.",
            timeOfDay: .evening,
            completionPercentage: 1.0,
            shouldShow: true,
            onDismiss: { }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}