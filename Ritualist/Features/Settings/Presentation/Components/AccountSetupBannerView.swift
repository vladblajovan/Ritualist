//
//  AccountSetupBannerView.swift
//  Ritualist
//
//  Informational banner showing account setup issues that might affect purchases.
//

import SwiftUI
import RitualistCore

/// Informational rows showing account setup status
/// Displays only when there are issues that might affect purchases
struct AccountSetupBannerView: View {
    let issues: [AccountSetupIssue]

    var body: some View {
        ForEach(issues) { issue in
            HStack {
                Label(issue.title, systemImage: issue.icon)
                    .foregroundStyle(issue.isCritical ? .red : .orange)

                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview("With Issues") {
    List {
        Section {
            AccountSetupBannerView(issues: [
                .iCloudNotSignedIn,
                .noNetwork
            ])
        }
    }
}

#Preview("All Issues") {
    List {
        Section {
            AccountSetupBannerView(issues: AccountSetupIssue.allCases)
        }
    }
}

#Preview("No Issues") {
    List {
        Section {
            AccountSetupBannerView(issues: [])
            Text("No banner shown when no issues")
        }
    }
}
