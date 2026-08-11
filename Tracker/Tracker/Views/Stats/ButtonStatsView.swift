//
//  ButtonStatsView.swift
//  Tracker
//
//  Routes to the right stats panel for a single button, based on the stat type
//  chosen when it was created.
//

import SwiftUI

struct ButtonStatsView: View {
    let button: ActivityButton

    private var color: Color { Color(hex: button.colorHex) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch button.statKind {
                case .bar:
                    let points = button.logEntries.map { (date: $0.startDate, value: 1.0) }
                    BarChartPanel(
                        color: color,
                        dailyPoints: StatsEngine.dailyBuckets(points),
                        weeklyPoints: StatsEngine.weeklyBuckets(points),
                        monthlyPoints: StatsEngine.monthlyBuckets(points),
                        unit: "mal"
                    )
                case .heatmap:
                    HeatmapPanel(
                        entryDates: button.logEntries.map(\.startDate),
                        baseColor: color,
                        maxFrequency: button.heatmapMaxFrequency ?? 5
                    )
                case .none:
                    ContentUnavailableView(
                        "Keine Statistik konfiguriert",
                        systemImage: "chart.bar",
                        description: Text("Lege in den Einstellungen einen Statistik-Typ für diesen Button fest.")
                    )
                }

                NavigationLink {
                    EntryHistoryView(button: button)
                } label: {
                    Label("Verlauf anzeigen", systemImage: "clock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle(button.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
