//
//  DebugMenuPerformanceSection.swift
//  Ritualist
//

import SwiftUI

#if DEBUG
struct DebugMenuPerformanceSection: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Section("Performance Monitoring") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Performance Statistics")
                        .font(.headline)

                    Spacer()

                    Button {
                        vm.updatePerformanceStats()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                }

                if let memoryMB = vm.memoryUsageMB {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Memory Usage:")
                            Spacer()
                            Text("\(memoryMB, specifier: "%.1f") MB")
                                .fontWeight(.medium)
                                .foregroundColor(memoryColor(for: memoryMB))
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(memoryColor(for: memoryMB))
                                    .frame(width: min(geometry.size.width * (memoryMB / 500.0), geometry.size.width), height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("Typical range: 150-300 MB. Warning at 500+ MB")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func memoryColor(for memoryMB: Double) -> Color {
        if memoryMB < 200 {
            return .green
        } else if memoryMB < 400 {
            return .orange
        } else {
            return .red
        }
    }
}
#endif
