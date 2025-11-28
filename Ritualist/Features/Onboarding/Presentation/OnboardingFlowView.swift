import SwiftUI
import FactoryKit
import RitualistCore

public struct OnboardingFlowView: View {
    @Injected(\.onboardingViewModel) var viewModel

    private let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }

    public var body: some View {
        OnboardingContentView(viewModel: viewModel, onComplete: onComplete)
            .background(Color(.systemBackground))
            .task {
                await viewModel.loadOnboardingState()
            }
    }
}

private struct OnboardingContentView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            OnboardingProgressView(currentPage: viewModel.currentPage, totalPages: viewModel.totalPages)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Page content
            TabView(selection: $viewModel.currentPage) {
                OnboardingPage1View(viewModel: viewModel, onComplete: onComplete)
                    .tag(0)

                OnboardingPage2View(viewModel: viewModel)
                    .tag(1)

                OnboardingPage3View()
                    .tag(2)

                OnboardingPage4View()
                    .tag(3)

                OnboardingPremiumComparisonView()
                    .tag(4)

                OnboardingPage6View(viewModel: viewModel)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentPage)

            // Navigation buttons
            OnboardingNavigationView(viewModel: viewModel, onComplete: onComplete)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

private struct OnboardingProgressView: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? AppColors.brand : Color(.systemGray4))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }
}

private struct OnboardingNavigationView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Back button
            if !viewModel.isFirstPage {
                Button {
                    viewModel.previousPage()
                } label: {
                    Text("Back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.brand)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(AppColors.brand.opacity(0.3), lineWidth: 1.5)
                        )
                }
            }

            Spacer()

            // Next/Complete button
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                if viewModel.isLastPage {
                    Task {
                        let success = await viewModel.finishOnboarding()
                        if success {
                            onComplete()
                        }
                    }
                } else {
                    viewModel.nextPage()
                }
            } label: {
                HStack(spacing: 4) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    } else {
                        Text(viewModel.isLastPage ? "Get Started" : "Continue")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(AppColors.brand)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(viewModel.canProceedFromCurrentPage && !viewModel.isLoading ? 1 : 0.5)
            }
            .disabled(!viewModel.canProceedFromCurrentPage || viewModel.isLoading)
        }
    }
}

#Preview {
    OnboardingFlowView()
}