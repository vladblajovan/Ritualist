import SwiftUI
import FactoryKit
import RitualistCore

struct OnboardingPage1View: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool
    let onComplete: (() -> Void)?

    init(viewModel: OnboardingViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)

                    // App icon with animated glow
                    if let uiImage = Bundle.main.appIcon {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .animatedGlow(glowSize: 160)
                    }

                    // Welcome message
                    VStack(spacing: 8) {
                        Text("Welcome to Ritualist!")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Let's start by getting to know you better.\nWhat should we call you?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Name input
                    VStack(spacing: 12) {
                        TextField("Enter your name", text: $viewModel.userName)
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .multilineTextAlignment(.center)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .onSubmit {
                                isTextFieldFocused = false
                                if viewModel.canProceedFromCurrentPage {
                                    viewModel.nextPage()
                                }
                            }

                        if viewModel.userName.isEmpty {
                            Text("You can change this later in settings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }

            #if DEBUG
            // Debug-only Skip button
            Button(action: {
                let logger = Container.shared.debugLogger()
                logger.log("Skip onboarding initiated from debug button", level: .debug, category: .debug)
                Task {
                    let success = await viewModel.skipOnboarding()
                    logger.log("Skip onboarding completed: \(success ? "success" : "failed")", level: success ? .info : .warning, category: .debug)
                    if success {
                        onComplete?()
                    }
                }
            }) {
                Text("Skip")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColors.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.top, 50)
            .padding(.trailing, 20)
            #endif
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}
