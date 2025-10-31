import SwiftUI
import RitualistCore

// MARK: - PaywallItem
public struct PaywallItem: Identifiable, Equatable {
    public let id = UUID()
    public let viewModel: PaywallViewModel
    
    public init(viewModel: PaywallViewModel) {
        self.viewModel = viewModel
    }
    
    public static func == (lhs: PaywallItem, rhs: PaywallItem) -> Bool {
        lhs.id == rhs.id
    }
}

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
                        .padding(.horizontal, Spacing.xlarge)
                        .padding(.vertical, Spacing.large)
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
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: Typography.largeIcon))
                .foregroundStyle(GradientTokens.premiumCrown)
            
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
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: adaptiveColumnCount), spacing: 16) {
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
                        Text(purchaseButtonText)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(GradientTokens.purchaseButton)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xlarge))
            }
            .disabled(vm.isPurchasing || vm.selectedProduct == nil)
            
            if let trialText = trialInfoText {
                Text(trialText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var purchaseButtonText: String {
        guard let selectedProduct = vm.selectedProduct else { return "Purchase" }
        return selectedProduct.duration == .annual ? "Start Free Trial" : "Purchase"
    }
    
    private var trialInfoText: String? {
        guard let selectedProduct = vm.selectedProduct else { return nil }
        if selectedProduct.duration == .annual {
            return "7-day free trial, then \(selectedProduct.localizedPrice). Cancel anytime."
        }
        return nil
    }
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveColumnCount: Int {
        switch horizontalSizeClass {
        case .compact:
            return 2  // iPhone portrait
        case .regular:
            return 3  // iPad or iPhone landscape
        default:
            return 2
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
                .lineLimit(2)
                .frame(minHeight: 40)
            
            Text(benefit.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .top)
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 130)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xlarge)
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
                // Header section with title and popular badge
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
                    
                    Spacer()
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
                
                // Price section at the bottom
                HStack {
                    Spacer()
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
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xlarge))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xlarge)
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
    let mockSecureSubscriptionService = MockSecureSubscriptionService()
    let mockBusinessService = MockPaywallBusinessService()
    let mockUserService = MockUserService()
    let updateProfileSubscription = UpdateProfileSubscription(
        userService: mockUserService,
        paywallService: MockPaywallService(subscriptionService: mockSecureSubscriptionService) // Legacy for now
    )
    
    let mockPaywallService = MockPaywallService(subscriptionService: mockSecureSubscriptionService)
    
    let vm = PaywallViewModel(
        loadPaywallProducts: LoadPaywallProducts(paywallService: mockPaywallService),
        purchaseProduct: PurchaseProduct(paywallService: mockPaywallService),
        restorePurchases: RestorePurchases(paywallService: mockPaywallService),
        checkProductPurchased: CheckProductPurchased(paywallService: mockPaywallService),
        updateProfileSubscription: updateProfileSubscription
    )
    
    PaywallView(vm: vm)
}
