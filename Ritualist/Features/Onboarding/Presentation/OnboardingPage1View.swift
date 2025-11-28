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
                            .accessibilityLabel("Ritualist app icon")
                    }

                    // Welcome message
                    VStack(spacing: 8) {
                        Text("Welcome to Ritualist!")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text("Let's start by getting to know you better.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // User profile inputs
                    VStack(spacing: 16) {
                        // Name input
                        VStack(alignment: .trailing, spacing: 4) {
                            TextField("What should we call you?", text: $viewModel.userName)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(AppColors.brand)
                                .multilineTextAlignment(.center)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    isTextFieldFocused = false
                                }
                                .accessibilityLabel("Name")
                                .accessibilityHint("Enter your name to personalize your experience. Maximum \(OnboardingViewModel.maxNameLength) characters.")
                                .modifier(GradientFieldStyle())

                            // Character count (only show when approaching limit)
                            if viewModel.userName.count > OnboardingViewModel.maxNameLength - 10 {
                                Text("\(viewModel.userName.count)/\(OnboardingViewModel.maxNameLength)")
                                    .font(.caption2)
                                    .foregroundStyle(
                                        viewModel.userName.count >= OnboardingViewModel.maxNameLength
                                            ? .red
                                            : .secondary
                                    )
                                    .padding(.trailing, 8)
                                    .accessibilityLabel("\(viewModel.userName.count) of \(OnboardingViewModel.maxNameLength) characters used")
                            }
                        }

                        // Gender and Age Group selectors in a row
                        HStack(spacing: 12) {
                            // Gender picker
                            Menu {
                                ForEach(UserGender.allCases) { gender in
                                    Button(gender.displayName) {
                                        viewModel.gender = gender
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.gender == .preferNotToSay ? "Gender" : viewModel.gender.displayName)
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundStyle(viewModel.gender == .preferNotToSay ? .secondary : AppColors.brand)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .modifier(GradientFieldStyle())
                            }
                            .accessibilityLabel("Gender")
                            .accessibilityValue(viewModel.gender.displayName)

                            // Age group picker
                            Menu {
                                ForEach(UserAgeGroup.allCases) { ageGroup in
                                    Button(ageGroup.displayName) {
                                        viewModel.ageGroup = ageGroup
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.ageGroup == .preferNotToSay ? "Age" : viewModel.ageGroup.displayName)
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundStyle(viewModel.ageGroup == .preferNotToSay ? .secondary : AppColors.brand)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .modifier(GradientFieldStyle())
                            }
                            .accessibilityLabel("Age group")
                            .accessibilityValue(viewModel.ageGroup.displayName)
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
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Gradient Field Style

private struct GradientFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppColors.brand.opacity(0.4),
                                AppColors.brand.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}
