//
//  DebugMenuBuildInfoSection.swift
//  Ritualist
//

import SwiftUI

#if DEBUG
struct DebugMenuBuildInfoSection: View {
    var body: some View {
        Section("Build Information") {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("App Version:")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Build Number:")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Build Configuration:")
                    Spacer()
                    Text("Debug")
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }

                HStack {
                    Text("All Features Enabled:")
                    Spacer()
                    #if ALL_FEATURES_ENABLED
                    Text("Yes")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    #else
                    Text("No")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    #endif
                }
            }
            .font(.subheadline)
            .padding(.vertical, 4)
        }
    }
}
#endif
