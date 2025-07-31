import SwiftUI

public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: PaywallViewModel
    @State private var showingError = false
    
    public init(vm: PaywallViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading Ritualist Pro...")
                            .font(.headline)
                        Text("Setting up your premium experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Debug info
                        Text("Products: \(vm.products.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Benefits: \(vm.benefits.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.hasError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Unable to Load")
                            .font(.headline)
                        Text(vm.errorMessage ?? "An error occurred")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await vm.load()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            headerSection
                            
                            // Benefits
                            benefitsSection
                            
                            // Pricing Plans
                            pricingSection
                            
                            // Purchase Button
                            purchaseSection
                            
                            // Restore Purchases
                            restoreSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Ritualist Pro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await vm.load()
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") {
                vm.dismissError()
            }
        } message: {
            Text(vm.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: vm.hasError) { _, hasError in
            showingError = hasError
        }
        .onChange(of: vm.purchaseState) { _, state in
            if case .success = state {
                // Only dismiss when purchase is successful AND user update is complete
                Task {
                    // Wait for user update to complete
                    while vm.isUpdatingUser {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                    
                    // Now dismiss with the updated user state
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Unlock Your Full Potential")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get unlimited habits, advanced analytics, and premium features")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("What's Included")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(vm.benefits) { benefit in
                    BenefitCard(benefit: benefit)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Choose Your Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if vm.isLoading {
                ProgressView("Loading plans...")
                    .frame(height: 200)
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.products) { product in
                        PricingCard(
                            product: product,
                            isSelected: vm.isSelected(product),
                            onTap: { vm.selectProduct(product) }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await vm.purchase()
                }
            } label: {
                HStack {
                    if vm.isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                        Text("Processing...")
                    } else {
                        Text("Start Free Trial")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(vm.isPurchasing || vm.selectedProduct == nil)
            
            Text("7-day free trial, then \(vm.selectedProduct?.localizedPrice ?? ""). Cancel anytime.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Restore Section
    
    private var restoreSection: some View {
        Button("Restore Purchases") {
            Task {
                await vm.restorePurchases()
            }
        }
        .font(.subheadline)
        .foregroundColor(.blue)
        .padding(.bottom, 20)
    }
}

// MARK: - Benefit Card

private struct BenefitCard: View {
    let benefit: PaywallBenefit
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: benefit.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(height: 24)
            
            Text(benefit.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text(benefit.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(benefit.isHighlighted ? .blue : .clear, lineWidth: 2)
        )
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(product.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if product.isPopular {
                                Text("POPULAR")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                        }
                        
                        Text(product.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.localizedPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if let discount = product.discount {
                            Text(discount)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Features preview
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(product.features.prefix(3)), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
            .overlay(
                // Selection indicator
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                        }
                        .padding(12)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    let mockService = MockPaywallService()
    let mockAuthService = MockAuthenticationService()
    let mockUserSession = UserSession(authService: mockAuthService)
    let secureDefaults = SecureUserDefaults()
    let stateCoordinator = StateCoordinator(
        paywallService: mockService,
        authService: mockAuthService,
        userSession: mockUserSession,
        secureDefaults: secureDefaults
    )
    let vm = PaywallViewModel(
        paywallService: mockService,
        userSession: mockUserSession,
        stateCoordinator: stateCoordinator
    )
    
    PaywallView(vm: vm)
}