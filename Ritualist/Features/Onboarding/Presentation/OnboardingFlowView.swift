import SwiftUI

public struct OnboardingFlowView: View {
    @Environment(\.appContainer) private var di
    @State private var viewModel: OnboardingViewModel?
    
    private let onComplete: () -> Void
    
    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                OnboardingContentView(viewModel: viewModel, onComplete: onComplete)
            } else {
                ProgressView()
                    .task {
                        viewModel = di.onboardingFactory.makeViewModel()
                        await viewModel?.loadOnboardingState()
                    }
            }
        }
        .background(Color(.systemBackground))
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
                        let success = await viewModel.finishOnboarding()
                        if success {
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