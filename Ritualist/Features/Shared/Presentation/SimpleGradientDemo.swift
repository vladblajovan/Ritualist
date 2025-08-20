import SwiftUI
import RitualistCore

/// Simple demonstration of gradient background integration
/// Shows how to add beautiful gradients to existing views
struct SimpleGradientDemo: View {
    @State private var useGradient = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            if useGradient {
                SimpleGradientBackground()
            } else {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Sample cards
                    sampleCards
                    
                    // Toggle control
                    toggleControl
                    
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Gradient Design Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Beautiful backgrounds for Ritualist")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private var sampleCards: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { index in
                sampleCard(title: "Sample Card \(index + 1)", 
                          description: "This shows how cards look with gradient backgrounds")
            }
        }
    }
    
    @ViewBuilder
    private func sampleCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(AppColors.brand)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text("📱")
                            .font(.title2)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private var toggleControl: some View {
        VStack(spacing: 12) {
            Text("Background Style")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        useGradient = false
                    }
                } label: {
                    Text("Standard")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(useGradient ? .secondary : AppColors.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(useGradient ? Color.clear : AppColors.brand.opacity(0.1))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(useGradient ? Color.secondary.opacity(0.3) : AppColors.brand.opacity(0.3), lineWidth: 1)
                                }
                        }
                }
                
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        useGradient = true
                    }
                } label: {
                    Text("Gradient ✨")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(useGradient ? AppColors.brand : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(useGradient ? AppColors.brand.opacity(0.1) : Color.clear)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(useGradient ? AppColors.brand.opacity(0.3) : Color.secondary.opacity(0.3), lineWidth: 1)
                                }
                        }
                }
            }
            
            Text("Toggle to see the difference between standard and gradient backgrounds")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .cardStyle()
    }
}

#Preview {
    SimpleGradientDemo()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SimpleGradientDemo()
        .preferredColorScheme(.dark)
}