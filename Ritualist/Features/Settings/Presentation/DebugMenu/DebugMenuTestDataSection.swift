//
//  DebugMenuTestDataSection.swift
//  Ritualist
//

import SwiftUI

#if DEBUG
struct DebugMenuTestDataSection: View {
    @Bindable var vm: SettingsViewModel
    @Binding var showingScenarios: Bool

    var body: some View {
        Section("Test Data") {
            GenericRowView.settingsRow(
                title: "Test Data Scenarios",
                subtitle: "Populate database with test user journeys",
                icon: "cylinder.split.1x2",
                iconColor: .blue
            ) {
                showingScenarios = true
            }

            if vm.isPopulatingTestData {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundColor(.blue)

                        Text(vm.testDataProgressMessage.isEmpty ? "Populating test data..." : vm.testDataProgressMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    ProgressView(value: vm.testDataProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
                .padding(.vertical, 4)
            }
        }
    }
}
#endif
