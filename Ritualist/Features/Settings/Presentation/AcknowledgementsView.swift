//
//  AcknowledgementsView.swift
//  Ritualist
//
//  Created by Vlad Blajovan Code on 22/12/2025.
//

import SwiftUI

struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section {
                Text("Ritualist uses the following open source libraries:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)

            Section("Factory") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("A new approach to Container-Based Dependency Injection for Swift and SwiftUI.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Link(destination: URL(string: "https://github.com/hmlongco/Factory")!) {
                        Label("View on GitHub", systemImage: "link")
                            .font(.subheadline)
                    }

                    Divider()

                    Text(factoryLicense)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var factoryLicense: String {
        """
        MIT License

        Copyright (c) 2022 Michael Long

        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        """
    }
}

#Preview {
    NavigationStack {
        AcknowledgementsView()
    }
}
