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
            .accessibilityIdentifier(AccessibilityID.HabitDetail.startDatePicker)
        } header: {
            Text(Strings.Habits.startDate)
        } footer: {
            footerContent
        }
        .accessibilityIdentifier(AccessibilityID.HabitDetail.startDateSection)
    }

    @ViewBuilder
    private var footerContent: some View {
        if vm.earliestLogDateLoadFailed {
            // Show error when loading validation data fails
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(Strings.Habits.failedToLoadHistory)
                }
                .font(.caption)
                .foregroundStyle(.red)

                Button {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await vm.loadEarliestLogDate()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text(Strings.Button.retry)
                    }
                    .font(.caption)
                }
            }
        } else if vm.isLoadingEarliestLogDate {
            // Show loading state
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                Text(Strings.Habits.loadingHistory)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if !vm.isStartDateValid {
            // Show error when start date is after existing logs
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(Strings.Habits.startDateAfterLogs)
            }
            .font(.caption)
            .foregroundStyle(.red)
        } else {
            Text(Strings.Habits.startDateFooter)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
