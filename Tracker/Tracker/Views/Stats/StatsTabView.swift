//
//  StatsTabView.swift
//  Tracker
//
//  Lists every group, mirroring the Log tab's grouping; each button with a
//  configured stat type links to its ButtonStatsView, and groups with the pie
//  chart option enabled also link to their GroupPieChartView.
//

import SwiftUI
import SwiftData

struct StatsTabView: View {
    @Query(sort: \ActivityGroup.sortOrder) private var groups: [ActivityGroup]

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Statistiken",
                        systemImage: "chart.bar",
                        description: Text("Sobald du Gruppen und Buttons anlegst und Einträge loggst, erscheinen hier Statistiken.")
                    )
                } else {
                    List {
                        ForEach(groups) { group in
                            // Shares `isCollapsed` with the Log tab's group
                            // header, so collapsing a group in one place stays
                            // in sync everywhere — same reasoning as there:
                            // with many groups, an always-expanded list of
                            // sections gets unscannable fast.
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { !group.isCollapsed },
                                    set: { group.isCollapsed = !$0 }
                                )
                            ) {
                                if group.showsPieChart {
                                    NavigationLink {
                                        GroupPieChartView(group: group)
                                    } label: {
                                        Label("Verteilung (Kreisdiagramm)", systemImage: "chart.pie")
                                    }
                                }
                                ForEach(group.sortedButtons.filter { $0.statKind != .none }) { button in
                                    NavigationLink {
                                        ButtonStatsView(button: button)
                                    } label: {
                                        HStack(spacing: 10) {
                                            Text(button.icon)
                                            Text(button.name)
                                        }
                                    }
                                }
                            } label: {
                                Text(group.name).font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Statistiken")
        }
    }
}

#Preview {
    StatsTabView()
        .modelContainer(for: ActivityGroup.self, inMemory: true)
}
