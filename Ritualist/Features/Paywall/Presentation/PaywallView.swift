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
    @State private var showingOfferCodeSheet = false
    @State private var showingProductsUnavailableAlert = false

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
                } else if vm.hasProducts {
                    // Only show content when products are available
                    // If no products, the alert will show and dismiss
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            headerSection
                            
                            // Benefits
                            benefitsSection
                            
                            // Pricing Plans
                            pricingSection

                            // Offer Code Section
                            offerCodeSection

                            // Purchase Button
                            purchaseSection

                            // Subscription Terms & Legal Links
                            PaywallLegalSection()

                            // Restore Purchases
                            restoreSection
                        }
                        .padding(.horizontal, Spacing.xlarge)
                        .padding(.vertical, Spacing.large)
                    }
                } else {
                    // No products available - show minimal UI while alert displays
                    // The alert will auto-dismiss the paywall
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .scrollContentBackground(.hidden)
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
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
        .offerCodeRedemption(isPresented: $showingOfferCodeSheet)
        .alert("Unable to Load Subscriptions", isPresented: $showingProductsUnavailableAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("We couldn't load subscription options. Please check your internet connection and try again later.")
        }
        .onChange(of: vm.isLoading) { wasLoading, isLoading in
            // When loading completes (was loading, now not loading)
            // and no products were loaded, show alert and dismiss
            if wasLoading && !isLoading && !vm.hasProducts {
                showingProductsUnavailableAlert = true
            }
        }
        .task {
            // Check on appear: if not loading and no products, show alert
            // This catches the case where loading completed before view appeared
            if !vm.isLoading && !vm.hasProducts {
                // Small delay to let the view render first
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                if !vm.hasProducts {
                    showingProductsUnavailableAlert = true
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

    // MARK: - Offer Code Section

    private var offerCodeSection: some View {
        offerCodeButton(showingOfferCodeSheet: $showingOfferCodeSheet)
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        purchaseContent()
    }

    // MARK: - Helper Properties

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

// MARK: - Legal Section

private struct PaywallLegalSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Apple-mandated subscription disclosure
            Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings in the App Store after purchase.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            // Legal links
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://vladblajovan.github.io/ritualist-legal/privacy.html")!)
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Link("Terms of Service", destination: URL(string: "https://vladblajovan.github.io/ritualist-legal/terms.html")!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    let mockSecureSubscriptionService = MockSecureSubscriptionService()
    let mockPaywallService = MockPaywallService(subscriptionService: mockSecureSubscriptionService)

    let vm = PaywallViewModel(
        loadPaywallProducts: LoadPaywallProducts(paywallService: mockPaywallService),
        purchaseProduct: PurchaseProduct(paywallService: mockPaywallService),
        restorePurchases: RestorePurchases(paywallService: mockPaywallService),
        checkProductPurchased: CheckProductPurchased(paywallService: mockPaywallService)
    )

    PaywallView(vm: vm)
}
