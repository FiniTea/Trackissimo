//
//  WellbeingStatsView.swift
//  Tracker
//
//  Wellbeing (mood-gate) statistics: weekly, monthly and yearly averages, plus
//  an all-weekdays overview in one shared view.
//

import SwiftUI
import SwiftData

struct WellbeingStatsView: View {
    @Query private var entries: [WellbeingEntry]

    private var points: [(date: Date, value: Double)] {
        entries.map { (date: $0.timestamp, value: Double($0.score)) }
    }

    private var weekAverage: Double? {
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return StatsEngine.average(points, in: start...Date.now)
    }

    private var monthAverage: Double? {
        let start = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
        return StatsEngine.average(points, in: start...Date.now)
    }

    private var yearAverage: Double? {
        let start = Calendar.current.dateInterval(of: .year, for: .now)?.start ?? .now
        return StatsEngine.average(points, in: start...Date.now)
    }

    private var weekdayAverages: [WeekdayAverage] {
        StatsEngine.weekdayAverages(points)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Stimmungseinträge",
                        systemImage: "face.smiling",
                        description: Text("Wähle beim nächsten App-Start eine Stimmung, damit hier Statistiken erscheinen.")
                    )
                } else {
                    HStack(spacing: 24) {
                        WellbeingAverageCircle(label: "Woche", average: weekAverage)
                        WellbeingAverageCircle(label: "Monat", average: monthAverage)
                        WellbeingAverageCircle(label: "Jahr", average: yearAverage)
                    }
                    .frame(maxWidth: .infinity)
                    .card()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wochentage").font(.subheadline.weight(.semibold))
                        HStack(spacing: 12) {
                            ForEach(weekdayAverages) { day in
                                WellbeingAverageCircle(label: day.label, average: day.average, size: 44)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .card()
                }
            }
            .padding()
        }
        .navigationTitle("Stimmung")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WellbeingStatsView()
    }
    .modelContainer(for: WellbeingEntry.self, inMemory: true)
}
