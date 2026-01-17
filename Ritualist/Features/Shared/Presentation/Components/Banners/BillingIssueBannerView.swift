//
//  BillingIssueBannerView.swift
//  Ritualist
//
//  Banner shown when user has a billing issue (payment failed, in grace period).
//  Prompts user to update their payment method before subscription expires.
//

import SwiftUI
import RitualistCore

/// Banner displayed when user has a billing issue (grace period or billing retry)
///
/// **Why this exists:**
/// When a payment fails, Apple's billing dialog appears once. To avoid annoying users
/// with repeated dialogs, we suppress it for 24 hours. This banner provides a
/// non-intrusive reminder in Settings so users know they need to fix their payment.
///
/// **User Flow:**
/// 1. Payment fails → Apple shows billing dialog
/// 2. User dismisses dialog (taps "Cancel" or "Not Now")
/// 3. User retains premium access (grace period)
/// 4. This banner appears in Settings as a reminder
/// 5. User can tap to go to subscription management and fix payment
///
struct BillingIssueBannerView: View {
    let onResolveTap: () -> Void

    var body: some View {
        Button(action: onResolveTap) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Subscription.billingIssueTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(Strings.Subscription.billingIssueSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Billing Issue Banner") {
    List {
        Section {
            BillingIssueBannerView(onResolveTap: {})
        } header: {
            Text("Subscription")
        }
    }
}

#Preview("In Context") {
    List {
        Section {
            // Simulating a premium user with billing issue
            HStack {
                Label("Monthly", systemImage: "star.circle.fill")
                Spacer()
                Text("PRO")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
            }

            BillingIssueBannerView(onResolveTap: {})

            Button {} label: {
                HStack {
                    Label("Manage Subscription", systemImage: "gearshape")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Subscription")
        }
    }
}
