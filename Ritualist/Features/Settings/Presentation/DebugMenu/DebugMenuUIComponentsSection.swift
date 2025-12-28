//
//  DebugMenuUIComponentsSection.swift
//  Ritualist
//

import SwiftUI

#if DEBUG
struct DebugMenuUIComponentsSection: View {
    @Binding var showingMotivationCardDemo: Bool

    var body: some View {
        Section("UI Components") {
            GenericRowView.settingsRow(
                title: "Motivation Cards Demo",
                subtitle: "View all message variants and trigger types",
                icon: "sparkles",
                iconColor: .orange
            ) {
                showingMotivationCardDemo = true
            }
        }
    }
}
#endif
