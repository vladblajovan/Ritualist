//
//  StartDateSection.swift
//  Ritualist
//
//  Allows editing the habit's start date for retroactive logging.
//

import SwiftUI
import RitualistCore

/// Section for editing habit start date.
/// Only shown in edit mode - allows users to backdate habits for retroactive logging.
struct StartDateSection: View {
    @Bindable var vm: HabitDetailViewModel

    var body: some View {
        Section {
            DatePicker(
                "Started",
                selection: $vm.startDate,
                in: ...Date(), // Cannot be in the future
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .accessibilityIdentifier("habitDetail.startDate.picker")
        } header: {
            Text("Start Date")
        } footer: {
            footerContent
        }
        .accessibilityIdentifier("habitDetail.startDate.section")
    }

    @ViewBuilder
    private var footerContent: some View {
        if !vm.isStartDateValid {
            // Show error when start date is after existing logs
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Start date cannot be after existing logs.")
            }
            .font(.caption)
            .foregroundStyle(.red)
        } else {
            Text("Set an earlier date to log habits retroactively. Logging before this date is not allowed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
