//
//  DebugOfferCodesView.swift
//  Ritualist
//
//  Created on 2025-11-18
//

#if DEBUG
import SwiftUI
import RitualistCore

/// Debug view for managing and testing offer codes
///
/// This view provides a complete testing environment for offer codes:
/// - Quick redemption interface
/// - Visual code management
/// - Create custom codes
/// - View redemption history
/// - Reset/clear functionality
///
struct DebugOfferCodesView: View {

    // MARK: - State

    @State private var offerCodeStorage = MockOfferCodeStorageService()
    @State private var offerCodes: [OfferCode] = []
    @State private var redemptionHistory: [OfferCodeRedemption] = []
    @State private var showingCreateSheet = false
    @State private var showingRedemptionHistory = false
    @State private var codeToRedeem: String = ""
    @State private var isRedeeming = false
    @State private var redemptionMessage: String?
    @State private var showingRedemptionAlert = false

    // MARK: - Dependencies

    let paywallService: PaywallService
    let subscriptionService: SecureSubscriptionService

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                Text("Manage and test offer codes for subscription testing. Create custom codes with different discounts, expiration dates, and eligibility rules.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Quick Redeem Section
            Section("Quick Redeem") {
                HStack {
                    TextField("Enter code", text: $codeToRedeem)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Button {
                        redeemCode()
                    } label: {
                        if isRedeeming {
                            ProgressView()
                        } else {
                            Text("Redeem")
                        }
                    }
                    .disabled(codeToRedeem.isEmpty || isRedeeming)
                    .buttonStyle(.borderedProminent)
                }
            }

            // Available Codes
            Section("Available Codes (\(offerCodes.count))") {
                if offerCodes.isEmpty {
                    Text("No offer codes available")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(offerCodes) { code in
                        OfferCodeRow(code: code, onRedeem: {
                            codeToRedeem = code.id
                            redeemCode()
                        })
                    }
                    .onDelete(perform: deleteCodes)
                }
            }

            // Actions
            Section("Actions") {
                Button {
                    showingCreateSheet = true
                } label: {
                    Label("Create New Code", systemImage: "plus.circle")
                }

                Button {
                    showingRedemptionHistory = true
                } label: {
                    Label("Redemption History (\(redemptionHistory.count))", systemImage: "clock.arrow.circlepath")
                }

                Button(role: .destructive) {
                    resetAllCodes()
                } label: {
                    Label("Reset to Default Codes", systemImage: "arrow.counterclockwise")
                }

                Button(role: .destructive) {
                    clearRedemptionHistory()
                } label: {
                    Label("Clear Redemption History", systemImage: "trash")
                }
                .disabled(redemptionHistory.isEmpty)
            }
        }
        .navigationTitle("Offer Codes Testing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateOfferCodeView(storage: offerCodeStorage) {
                Task {
                    await loadData()
                }
            }
        }
        .sheet(isPresented: $showingRedemptionHistory) {
            RedemptionHistoryView(
                history: redemptionHistory,
                codes: offerCodes
            )
        }
        .alert("Redemption Result", isPresented: $showingRedemptionAlert) {
            Button("OK") {
                redemptionMessage = nil
            }
        } message: {
            if let message = redemptionMessage {
                Text(message)
            }
        }
    }

    // MARK: - Methods

    private func loadData() async {
        offerCodes = (try? await offerCodeStorage.getAllOfferCodes()) ?? []
        redemptionHistory = (try? await offerCodeStorage.getRedemptionHistory()) ?? []
    }

    private func redeemCode() {
        guard !codeToRedeem.isEmpty else { return }

        isRedeeming = true

        Task {
            do {
                // Cast to MockPaywallService to access redeemOfferCode
                guard let mockService = paywallService as? MockPaywallService else {
                    redemptionMessage = "❌ Redemption only available in mock mode"
                    isRedeeming = false
                    showingRedemptionAlert = true
                    return
                }

                let success = try await mockService.redeemOfferCode(codeToRedeem)

                if success {
                    redemptionMessage = "✅ Successfully redeemed code: \(codeToRedeem)"
                    codeToRedeem = ""
                    await loadData()
                }
            } catch let error as PaywallError {
                redemptionMessage = "❌ \(error.errorDescription ?? "Redemption failed")"
            } catch {
                redemptionMessage = "❌ Unexpected error: \(error.localizedDescription)"
            }

            isRedeeming = false
            showingRedemptionAlert = true
        }
    }

    private func deleteCodes(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let code = offerCodes[index]
                try? await offerCodeStorage.deleteOfferCode(code.id)
            }
            await loadData()
        }
    }

    private func resetAllCodes() {
        Task {
            await offerCodeStorage.clearAllCodes()
            await offerCodeStorage.loadDefaultTestCodes()
            await loadData()
        }
    }

    private func clearRedemptionHistory() {
        Task {
            await offerCodeStorage.clearRedemptionHistory()
            await loadData()
        }
    }
}

// MARK: - Offer Code Row

struct OfferCodeRow: View {
    let code: OfferCode
    let onRedeem: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(code.id)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(code.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status Badge
                statusBadge
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text(productName(for: code.productId))
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    if let expiry = code.expirationDate {
                        Text("Expires: \(expiry, style: .date)")
                            .font(.caption)
                    } else {
                        Text("No expiration")
                            .font(.caption)
                    }
                }

                if let maxRedemptions = code.maxRedemptions {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.purple)
                            .frame(width: 20)
                        Text("\(code.redemptionCount)/\(maxRedemptions) used")
                            .font(.caption)
                    }
                }

                if code.isNewSubscribersOnly {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("New subscribers only")
                            .font(.caption)
                    }
                }

                // Offer details
                if code.offerType == .discount, let discount = code.discount {
                    HStack {
                        Image(systemName: "percent")
                            .foregroundColor(.red)
                            .frame(width: 20)
                        Text(discount.description)
                            .font(.caption)
                    }
                } else if code.offerType == .freeTrial {
                    HStack {
                        Image(systemName: "gift")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("Free Trial")
                            .font(.caption)
                    }
                }
            }
            .padding(.top, 4)

            // Quick redeem button
            if code.isValid {
                Button(action: onRedeem) {
                    Text("Quick Redeem")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if !code.isActive {
            Text("INACTIVE")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.gray)
                .foregroundColor(.white)
                .clipShape(Capsule())
        } else if code.isExpired {
            Text("EXPIRED")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.red)
                .foregroundColor(.white)
                .clipShape(Capsule())
        } else if code.isRedemptionLimitReached {
            Text("LIMIT REACHED")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange)
                .foregroundColor(.white)
                .clipShape(Capsule())
        } else {
            Text("ACTIVE")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.green)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }

    private func productName(for productId: String) -> String {
        switch productId {
        case StoreKitProductID.monthly:
            return "Monthly"
        case StoreKitProductID.annual:
            return "Annual"
        case StoreKitProductID.lifetime:
            return "Lifetime"
        default:
            return "Unknown"
        }
    }
}

// MARK: - Create Offer Code View

struct CreateOfferCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let storage: MockOfferCodeStorageService
    let onSave: () -> Void

    @State private var codeId: String = ""
    @State private var displayName: String = ""
    @State private var selectedProduct: String = StoreKitProductID.annual
    @State private var offerType: OfferCode.OfferType = .freeTrial
    @State private var discountType: OfferCode.OfferDiscount.DiscountType = .percentage
    @State private var discountValue: String = "50"
    @State private var hasExpiration: Bool = true
    @State private var expirationDays: String = "90"
    @State private var isNewSubscribersOnly: Bool = false
    @State private var hasMaxRedemptions: Bool = false
    @State private var maxRedemptions: String = "100"

    var body: some View {
        NavigationStack {
            Form {
                Section("Code Details") {
                    TextField("Code ID (e.g., SUMMER2025)", text: $codeId)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    TextField("Display Name", text: $displayName)
                }

                Section("Product") {
                    Picker("Target Product", selection: $selectedProduct) {
                        Text("Monthly").tag(StoreKitProductID.monthly)
                        Text("Annual").tag(StoreKitProductID.annual)
                        Text("Lifetime").tag(StoreKitProductID.lifetime)
                    }
                }

                Section("Offer Type") {
                    Picker("Type", selection: $offerType) {
                        Text("Free Trial").tag(OfferCode.OfferType.freeTrial)
                        Text("Discount").tag(OfferCode.OfferType.discount)
                    }

                    if offerType == .discount {
                        Picker("Discount Type", selection: $discountType) {
                            Text("Percentage").tag(OfferCode.OfferDiscount.DiscountType.percentage)
                            Text("Fixed Amount").tag(OfferCode.OfferDiscount.DiscountType.fixed)
                        }

                        TextField(
                            discountType == .percentage ? "Percentage (0-100)" : "Amount",
                            text: $discountValue
                        )
                        .keyboardType(.decimalPad)
                    }
                }

                Section("Expiration") {
                    Toggle("Has Expiration", isOn: $hasExpiration)

                    if hasExpiration {
                        TextField("Days until expiration", text: $expirationDays)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Redemption Limits") {
                    Toggle("New Subscribers Only", isOn: $isNewSubscribersOnly)

                    Toggle("Max Redemptions", isOn: $hasMaxRedemptions)

                    if hasMaxRedemptions {
                        TextField("Maximum redemptions", text: $maxRedemptions)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Create Offer Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCode()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !codeId.isEmpty && !displayName.isEmpty
    }

    private func saveCode() {
        let expiration: Date? = hasExpiration
            ? Date().addingTimeInterval(Double(expirationDays) ?? 90 * 24 * 60 * 60)
            : nil

        let discount: OfferCode.OfferDiscount? = offerType == .discount
            ? OfferCode.OfferDiscount(
                type: discountType,
                value: Double(discountValue) ?? 0,
                duration: 1
            )
            : nil

        let code = OfferCode(
            id: codeId.uppercased(),
            displayName: displayName,
            productId: selectedProduct,
            offerType: offerType,
            discount: discount,
            expirationDate: expiration,
            isNewSubscribersOnly: isNewSubscribersOnly,
            maxRedemptions: hasMaxRedemptions ? Int(maxRedemptions) : nil
        )

        Task {
            try? await storage.saveOfferCode(code)
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}

// MARK: - Redemption History View

struct RedemptionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let history: [OfferCodeRedemption]
    let codes: [OfferCode]

    var body: some View {
        NavigationStack {
            List {
                if history.isEmpty {
                    ContentUnavailableView(
                        "No Redemptions",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Redeemed offer codes will appear here")
                    )
                } else {
                    ForEach(history) { redemption in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(redemption.codeId)
                                    .font(.headline)

                                Spacer()

                                Text(redemption.redeemedAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let code = codes.first(where: { $0.id == redemption.codeId }) {
                                Text(code.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text("Product: \(productName(for: redemption.productId))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Redemption History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func productName(for productId: String) -> String {
        switch productId {
        case StoreKitProductID.monthly:
            return "Monthly"
        case StoreKitProductID.annual:
            return "Annual"
        case StoreKitProductID.lifetime:
            return "Lifetime"
        default:
            return productId
        }
    }
}

#endif
