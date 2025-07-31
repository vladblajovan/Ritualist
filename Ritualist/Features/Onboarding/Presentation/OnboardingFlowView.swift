import SwiftUI

public struct OnboardingFlowView: View {
    @Environment(\.appContainer) private var di
    @State private var viewModel: OnboardingViewModel?
    @State private var showingHabitAssistant = false
    @State private var showingPaywall = false
    @State private var paywallViewModel: PaywallViewModel?
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
                userActionTracker: di.userActionTracker
            )
            .onDisappear {
                checkIfShouldShowPaywall()
            }
        }
        .sheet(item: Binding<PaywallItem?>(
            get: { 
                guard let vm = paywallViewModel else { return nil }
                return PaywallItem(viewModel: vm)
            },
            set: { _ in 
                paywallViewModel = nil
            }
        )) { item in
            PaywallView(vm: item.viewModel)
                .onDisappear {
                    dismiss() // Dismiss onboarding after paywall
                }
        }
    }
    
    private func createHabitFromSuggestion(_ suggestion: HabitSuggestion) async -> Bool {
        do {
            let habit = suggestion.toHabit()
            try await di.habitRepository.create(habit)
            return true
        } catch {
            return false
        }
    }
    
    private func checkIfShouldShowPaywall() {
        print("🔍 checkIfShouldShowPaywall called")
        print("🔍 isPremiumUser: \(di.userSession.isPremiumUser)")
        
        // Only show paywall for free users after onboarding
        if !di.userSession.isPremiumUser {
            print("🏭 Creating factory in checkIfShouldShowPaywall...")
            Task { @MainActor in
                let factory = PaywallFactory(container: di)
                print("🎯 Creating viewModel in checkIfShouldShowPaywall...")
                let vm = factory.makeViewModel()
                print("✅ ViewModel created in checkIfShouldShowPaywall")
                await vm.load()
                print("🔄 ViewModel loaded")
                
                // Set the viewModel - this will automatically show the sheet via the binding
                paywallViewModel = vm
                print("🎭 Paywall sheet should now show with viewModel")
            }
        } else {
            print("⚠️ User is premium, dismissing")
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