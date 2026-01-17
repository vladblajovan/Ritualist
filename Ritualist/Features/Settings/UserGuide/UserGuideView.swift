//
//  UserGuideView.swift
//  Ritualist
//
//  A searchable user guide with organized sections and quick navigation.
//

import SwiftUI
import RitualistCore

/// User guide with searchable sections
struct UserGuideView: View {
    @State private var searchText = ""

    private var filteredSections: [UserGuideSection] {
        if searchText.isEmpty {
            return UserGuideSection.allSections
        }
        return UserGuideSection.allSections.filter { section in
            section.title.localizedCaseInsensitiveContains(searchText) ||
            section.items.contains { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            // Guide Sections
            ForEach(filteredSections) { section in
                Section {
                    ForEach(section.items) { item in
                        UserGuideItemRow(item: item, searchText: searchText)
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .foregroundColor(section.color)
                        Text(section.title)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: Strings.UserGuide.searchPlaceholder)
        .navigationTitle(Strings.UserGuide.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - User Guide Item Row

private struct UserGuideItemRow: View {
    let item: UserGuideItem
    let searchText: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(item.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .textSelection(.enabled)
        } label: {
            HStack(spacing: 12) {
                if let emoji = item.emoji {
                    Text(emoji)
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            // Auto-expand items that match search, collapse when search is cleared
            if !newValue.isEmpty &&
               (item.title.localizedCaseInsensitiveContains(newValue) ||
                item.content.localizedCaseInsensitiveContains(newValue)) {
                isExpanded = true
            } else if newValue.isEmpty {
                isExpanded = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserGuideView()
    }
}
