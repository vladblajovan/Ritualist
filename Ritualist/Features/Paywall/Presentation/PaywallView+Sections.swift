//
//  PaywallView+Sections.swift
//  Ritualist
//
//  Section views for PaywallView
//

import SwiftUI
import RitualistCore

// MARK: - Offer Code Section

extension PaywallView {
    @ViewBuilder
    func offerCodeButton(showingOfferCodeSheet: Binding<Bool>) -> some View {
        Button {
            showingOfferCodeSheet.wrappedValue = true
        } label: {
            HStack(spacing: 12) {
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

extension PaywallView {
    @ViewBuilder
    func purchaseContent() -> some View {
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
                .background(vm.canPurchase ? GradientTokens.purchaseButton : GradientTokens.disabledButton)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xlarge))
            }
            .disabled(!vm.canPurchase)

            purchaseHelperText
        }
    }

    @ViewBuilder
    private var purchaseHelperText: some View {
        if !vm.hasProducts && !vm.isLoading {
            Text("Unable to load products. Please check your connection and try again.")
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
        } else if vm.selectedProduct == nil && vm.hasProducts {
            Text("Select a plan above to continue")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        } else if let trialText = trialInfoText {
            Text(trialText)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    var purchaseButtonText: String {
        guard let selectedProduct = vm.selectedProduct else { return "Purchase" }
        return selectedProduct.duration == .annual ? "Start Free Trial" : "Purchase"
    }

    var trialInfoText: String? {
        guard let selectedProduct = vm.selectedProduct else { return nil }
        if selectedProduct.duration == .annual {
            return "7-day free trial, then \(selectedProduct.localizedPrice). Cancel anytime."
        }
        return nil
    }
}
