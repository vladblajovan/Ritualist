import SwiftUI

public struct OnboardingFlowView: View {
    @Environment(\.appContainer) private var di
    @State private var viewModel: OnboardingViewModel?
    @State private var showingHabitAssistant = false
    @State private var showingPaywall = false
    @State private var paywallItem: PaywallItem?
    @State private var shouldReopenAssistantAfterPaywall = false
    @State private var isHandlingPaywallDismissal = false
    @State private var paywallWasShownFromAssistant = false
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                OnboardingContentView(viewModel: viewModel, onComplete: {
                    di.userActionTracker.track(.habitsAssistantOpened(source: .onboarding))
                    showingHabitAssistant = true
                })
            } else {
                ProgressView()
                    .task {
                        viewModel = di.onboardingFactory.makeViewModel()
                        await viewModel?.loadOnboardingState()
                    }
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingHabitAssistant) {
            HabitAssistantSheet(
                suggestionsService: di.habitSuggestionsService,
                onHabitCreate: { suggestion in
                    await createHabitFromSuggestion(suggestion)
                },
                onShowPaywall: showPaywall,
                userActionTracker: di.userActionTracker
            )
            .onDisappear {
                // Only check for paywall if it wasn't already shown from within the assistant
                if !paywallWasShownFromAssistant {
                    checkIfShouldShowPaywall()
                } else {
                    // Reset the flag for future assistant usage
                    paywallWasShownFromAssistant = false
                }
            }
        }
        .sheet(item: $paywallItem) { item in
            PaywallView(vm: item.viewModel)
        }
        .onChange(of: paywallItem) { oldValue, newValue in
            // When paywall item becomes nil, the sheet is dismissed
            if oldValue != nil && newValue == nil {
                handlePaywallDismissal()
            }
        }
    }
    
    private func createHabitFromSuggestion(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        let habitsFactory = HabitsFactory(container: di)
        let createHabitFromSuggestionUseCase = habitsFactory.makeCreateHabitFromSuggestionUseCase()
        
        return await createHabitFromSuggestionUseCase.execute(suggestion)
    }
    
    private func showPaywall() {
        // Mark that we should reopen assistant after paywall closes
        shouldReopenAssistantAfterPaywall = true
        paywallWasShownFromAssistant = true  // Track that paywall was shown from assistant
        
        Task { @MainActor in
            let factory = PaywallFactory(container: di)
            let vm = factory.makeViewModel()
            await vm.load()
            paywallItem = PaywallItem(viewModel: vm)
        }
    }
    
    private func handlePaywallDismissal() {
        // Guard against multiple calls
        guard !isHandlingPaywallDismissal else {
            return
        }
        
        isHandlingPaywallDismissal = true
        
        if shouldReopenAssistantAfterPaywall {
            // Reset the flag
            shouldReopenAssistantAfterPaywall = false
            
            // Wait longer for paywall dismissal animation to complete before reopening assistant
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showingHabitAssistant = true
                isHandlingPaywallDismissal = false
            }
        } else {
            isHandlingPaywallDismissal = false
            dismiss()
        }
    }
    
    private func checkIfShouldShowPaywall() {
        // Only show paywall for free users after onboarding
        if !di.userSession.isPremiumUser {
            Task { @MainActor in
                let factory = PaywallFactory(container: di)
                let vm = factory.makeViewModel()
                await vm.load()
                
                // Set the paywallItem - this will automatically show the sheet via the binding
                paywallItem = PaywallItem(viewModel: vm)
            }
        } else {
            // Premium users or if paywall dismissed, just complete onboarding
            dismiss()
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
                .padding(.top, 20)
            
            // Page content
            TabView(selection: $viewModel.currentPage) {
                OnboardingPage1View(viewModel: viewModel)
                    .tag(0)
                
                OnboardingPage2View(viewModel: viewModel)
                    .tag(1)
                
                OnboardingPage3View()
                    .tag(2)
                
                OnboardingPage4View()
                    .tag(3)
                
                OnboardingPage5View(viewModel: viewModel)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentPage)
            
            // Navigation buttons
            OnboardingNavigationView(viewModel: viewModel, onComplete: onComplete)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
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
                Circle()
                    .fill(index <= currentPage ? Color.accentColor : Color(.systemGray4))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
    }
}

private struct OnboardingNavigationView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            // Back button
            if !viewModel.isFirstPage {
                Button("Back") {
                    viewModel.previousPage()
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Next/Complete button
            Button(viewModel.isLastPage ? "Get Started" : "Next") {
                if viewModel.isLastPage {
                    Task {
                        await viewModel.finishOnboarding()
                        if viewModel.isCompleted {
                            onComplete()
                        }
                    }
                } else {
                    viewModel.nextPage()
                }
            }
            .disabled(!viewModel.canProceedFromCurrentPage || viewModel.isLoading)
            .buttonStyle(.borderedProminent)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
}