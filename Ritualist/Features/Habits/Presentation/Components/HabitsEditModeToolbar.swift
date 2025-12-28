//
//  HabitsEditModeToolbar.swift
//  Ritualist
//

import SwiftUI
import RitualistCore

struct HabitsEditModeToolbar: View {
    let selectionCount: Int
    let hasActiveSelected: Bool
    let hasInactiveSelected: Bool
    let onActivate: () -> Void
    let onDeactivate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.large) {
            Text("\(selectionCount) selected")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            if hasInactiveSelected {
                Button(action: onActivate) {
                    VStack(spacing: 2) {
                        Image(systemName: "play.circle")
                            .font(.title2)
                        Text("Activate")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.green)
            }

            if hasActiveSelected {
                Button(action: onDeactivate) {
                    VStack(spacing: 2) {
                        Image(systemName: "pause.circle")
                            .font(.title2)
                        Text("Deactivate")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.orange)
            }

            Button(action: onDelete) {
                VStack(spacing: 2) {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("Delete")
                        .font(.caption2)
                }
            }
            .foregroundColor(.red)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, Spacing.medium)
        .padding(.bottom, Spacing.small)
    }
}
