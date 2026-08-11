//
//  LogTabView.swift
//  Tracker
//
//  Main screen: scrollable list of groups (each collapsible), rendering its
//  buttons in a grid, plus a fuzzy search over every button across all groups
//  so a specific button can be found without scrolling once there are many.
//

import SwiftUI
import SwiftData

struct LogTabView: View {
    @Query(sort: \ActivityGroup.sortOrder) private var groups: [ActivityGroup]
    @Query private var allButtons: [ActivityButton]

    @State private var searchQuery = ""

    private var searchResults: [ActivityButton] {
        FuzzyMatch.filter(allButtons, query: searchQuery) { $0.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Gruppen",
                        systemImage: "square.grid.2x2",
                        description: Text("Lege in den Einstellungen deine erste Gruppe und deinen ersten Button an.")
                    )
                } else if !searchQuery.isEmpty {
                    searchResultsList
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(groups) { group in
                                GroupSectionView(group: group)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Tracker")
            .searchable(text: $searchQuery, prompt: "Button suchen…")
        }
    }

    private var searchResultsList: some View {
        List {
            if searchResults.isEmpty {
                ContentUnavailableView.search(text: searchQuery)
            } else {
                ForEach(searchResults) { button in
                    SearchResultRow(button: button)
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    LogTabView()
        .modelContainer(for: ActivityGroup.self, inMemory: true)
}
