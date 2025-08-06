import SwiftUI

struct OnboardingPage1View: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: adaptiveSpacing(for: geometry.size.height)) {
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                    
                    // Welcome icon
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: Typography.heroIcon))
                        .foregroundColor(.accentColor)
                    
                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        Text("Welcome to Ritualist!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Let's start by getting to know you better. What should we call you?")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, adaptivePadding(for: geometry.size.width))
                    }
                    
                    VStack(spacing: Spacing.small) {
                        TextField("Enter your name", text: $viewModel.userName)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                isTextFieldFocused = false
                                if viewModel.canProceedFromCurrentPage {
                                    viewModel.nextPage()
                                }
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry.size.width) * 2)
                        
                        if viewModel.userName.isEmpty {
                            Text("Don't worry, you can change this later in settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                }
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, adaptivePadding(for: geometry.size.width))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
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
        default: return Spacing.extraLarge  // Large screens - original padding
        }
    }
}
