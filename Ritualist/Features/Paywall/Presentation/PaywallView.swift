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
    @State private var showingOfferCodeSuccess = false
    @State private var showingOfferCodeError = false
    @State private var offerCodeSuccessMessage: String?
    @State private var offerCodeErrorMessage: String?
    
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

                            // Discount Banner (shows when active discount exists for selected product)
                            if vm.hasActiveDiscountForSelectedProduct {
                                discountBannerSection
                            }

                            // Offer Code Section
                            if vm.isOfferCodeRedemptionAvailable {
                                offerCodeSection
                            }

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
        .offerCodeRedemption(isPresented: $showingOfferCodeSheet)
        .onChange(of: vm.offerCodeRedemptionState) { _, state in
            handleOfferCodeStateChange(state)
        }
        .alert("Offer Code Redeemed!", isPresented: $showingOfferCodeSuccess) {
            Button("Great!") {
                offerCodeSuccessMessage = nil
                // Dismiss paywall after successful redemption
                dismiss()
            }
        } message: {
            Text(offerCodeSuccessMessage ?? "Your subscription is now active")
        }
        .alert("Redemption Failed", isPresented: $showingOfferCodeError) {
            Button("OK") {
                offerCodeErrorMessage = nil
            }
        } message: {
            Text(offerCodeErrorMessage ?? "Unable to redeem offer code. Please try again.")
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
                            activeDiscount: vm.getActiveDiscount(for: product),
                            discountedPrice: vm.getDiscountedPrice(for: product),
                            onTap: { vm.selectProduct(product) }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Discount Banner Section

    private var discountBannerSection: some View {
        Group {
            if let discount = vm.activeDiscountForSelectedProduct {
                DiscountBannerCard(discount: discount)
            }
        }
    }

    // MARK: - Offer Code Section

    private var offerCodeSection: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, 8)

            Button {
                showingOfferCodeSheet = true
                vm.presentOfferCodeSheet()
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: "giftcard.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32)

                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Have a promo code?")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Redeem your offer code here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
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
    
    // MARK: - Offer Code Handlers

    /// Handle changes to offer code redemption state
    private func handleOfferCodeStateChange(_ state: OfferCodeRedemptionState) {
        switch state {
        case .success(let code, let productId):
            // Show success message
            offerCodeSuccessMessage = "Successfully redeemed code for \(productId)"
            showingOfferCodeSuccess = true
            // Reset sheet state
            showingOfferCodeSheet = false

        case .failed(let message):
            // Show error in dedicated offer code error alert
            offerCodeErrorMessage = message
            showingOfferCodeError = true
            // Reset sheet state
            showingOfferCodeSheet = false

        case .idle, .validating, .redeeming:
            // No action needed for these states
            break
        }
    }

    // MARK: - Helper Properties

    private var purchaseButtonText: String {
        guard let selectedProduct = vm.selectedProduct else { return "Purchase" }

        // Check if there's an active discount for the selected product
        if let discountedPrice = vm.getDiscountedPrice(for: selectedProduct) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            let priceString = formatter.string(from: NSNumber(value: discountedPrice)) ?? "$\(String(format: "%.2f", discountedPrice))"

            if selectedProduct.duration == .annual {
                return "Start Free Trial - \(priceString) after"
            } else {
                return "Get \(selectedProduct.duration.rawValue.capitalized) - \(priceString)"
            }
        }

        // No discount - use standard text
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

// MARK: - Discount Badge

private struct DiscountBadge: View {
    let discount: ActiveDiscount

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag.fill")
                .font(.caption)
                .foregroundColor(.white)

            Text(discountText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [.green, .mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: .green.opacity(0.3), radius: 4, y: 2)
    }

    private var discountText: String {
        switch discount.discountType {
        case .percentage:
            return "\(Int(discount.discountValue))% OFF"
        case .fixed:
            return "$\(Int(discount.discountValue)) OFF"
        }
    }
}

// MARK: - Discount Banner Card

private struct DiscountBannerCard: View {
    let discount: ActiveDiscount

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Celebration icon
                Image(systemName: "party.popper.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Discount info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Discount Applied!")
                            .font(.headline)
                            .fontWeight(.semibold)

                        DiscountBadge(discount: discount)
                    }

                    Text("Code: \(discount.codeId.uppercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [.green.opacity(0.1), .mint.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: CornerRadius.large)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .green.opacity(0.2), radius: 8, y: 4)
        }
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
    let activeDiscount: ActiveDiscount?
    let discountedPrice: Double?
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

                            // Show discount badge if active
                            if let discount = activeDiscount {
                                DiscountBadge(discount: discount)
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
                        // Show discounted price if available
                        if let discountedPrice = discountedPrice {
                            // Original price with strike-through
                            Text(product.localizedPrice)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .strikethrough(true, color: .red)

                            // Discounted price
                            Text(formattedDiscountedPrice(discountedPrice))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)

                            // Savings amount
                            if let savings = calculateSavings(discountedPrice) {
                                Text("Save \(savings)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        } else {
                            // Regular price display
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

    // MARK: - Helper Methods

    private func formattedDiscountedPrice(_ price: Double) -> String {
        // Format as currency (assumes USD for now)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$\(String(format: "%.2f", price))"
    }

    private func calculateSavings(_ discountedPrice: Double) -> String? {
        // Extract original price from localizedPrice string
        let priceString = product.price
        guard let originalPrice = Double(priceString.filter { "0123456789.".contains($0) }) else {
            return nil
        }

        let savings = originalPrice - discountedPrice
        guard savings > 0 else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: savings)) ?? "$\(String(format: "%.2f", savings))"
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
