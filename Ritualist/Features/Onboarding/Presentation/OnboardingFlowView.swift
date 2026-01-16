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

    /// Page titles for VoiceOver announcements
    private var pageTitles: [String] {
        [
            Strings.Onboarding.pageWelcome,
            Strings.Onboarding.pageTrackHabits,
            Strings.Onboarding.pageMakeItYours,
            Strings.Onboarding.pageLearnImprove,
            Strings.Onboarding.pageFreePro,
            Strings.Onboarding.pagePermissions
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
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
            .sensoryFeedback(.selection, trigger: viewModel.currentPage) // Haptic on page change

            // Progress indicator
            OnboardingProgressView(currentPage: viewModel.currentPage, totalPages: viewModel.totalPages)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

            // Navigation buttons
            OnboardingNavigationView(viewModel: viewModel, onComplete: onComplete)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .alert(Strings.Common.error, isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(Strings.Common.ok) {
                viewModel.dismissError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: viewModel.currentPage) { _, newPage in
            announcePageChange(newPage)
        }
    }

    /// Announces page change to VoiceOver users
    private func announcePageChange(_ page: Int) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        let pageTitle = page < pageTitles.count ? pageTitles[page] : Strings.Onboarding.pageAnnouncement(page + 1)
        let announcement = Strings.Onboarding.stepAnnouncement(page + 1, viewModel.totalPages, pageTitle)
        UIAccessibility.post(notification: .screenChanged, argument: announcement)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Onboarding.progressLabel(currentPage + 1, totalPages))
        .accessibilityValue(Strings.Onboarding.progressPercent(Int((Double(currentPage + 1) / Double(totalPages)) * 100)))
    }
}

private struct OnboardingNavigationView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Skip button on first page, Back button on subsequent pages
            if viewModel.isFirstPage {
                Button {
                    HapticFeedbackService.shared.trigger(.light)
                    Task {
                        let success = await viewModel.skipOnboarding()
                        if success {
                            onComplete()
                        }
                    }
                } label: {
                    Text(Strings.Onboarding.skip)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.brand)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(AppColors.brand.opacity(0.3), lineWidth: 1.5)
                        )
                }
                .accessibilityIdentifier("onboarding.skip")
                .accessibilityHint(Strings.Onboarding.skipHint)
            } else {
                Button {
                    HapticFeedbackService.shared.trigger(.light)
                    viewModel.previousPage()
                } label: {
                    Text(Strings.Onboarding.back)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.brand)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(AppColors.brand.opacity(0.3), lineWidth: 1.5)
                        )
                }
                .accessibilityIdentifier("onboarding.back")
                .accessibilityHint(Strings.Onboarding.backHint)
            }

            Spacer()

            // Next/Complete button
            Button {
                HapticFeedbackService.shared.trigger(.light)
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
                        Text(viewModel.isLastPage ? Strings.Onboarding.getStarted : Strings.Onboarding.continueButton)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(minHeight: 44)
                .padding(.horizontal, 24)
                .background(AppColors.brand)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(viewModel.canProceedFromCurrentPage && !viewModel.isLoading ? 1 : 0.5)
            }
            .disabled(!viewModel.canProceedFromCurrentPage || viewModel.isLoading)
            .accessibilityIdentifier("onboarding.continue")
            .accessibilityHint(viewModel.isLastPage ? Strings.Onboarding.completeHint : Strings.Onboarding.nextHint)
        }
    }
}

#Preview {
    OnboardingFlowView()
}
