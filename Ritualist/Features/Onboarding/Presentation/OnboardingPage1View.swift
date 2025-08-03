import SwiftUI

struct OnboardingPage1View: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: Spacing.xxlarge) {
                Spacer()
                
                // Welcome icon
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: Typography.heroIcon))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: Spacing.large) {
                    Text("Welcome to Ritualist!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's start by getting to know you better. What should we call you?")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.extraLarge)
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
                        .padding(.horizontal, Spacing.xxxlarge)
                    
                    if viewModel.userName.isEmpty {
                        Text("Don't worry, you can change this later in settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, Spacing.xlarge)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}
