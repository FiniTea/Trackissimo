//
//  GroupPieChartView.swift
//  Tracker
//
//  Pie chart configured at the group level: share of each button's log count
//  within the group's total, over a selectable time range. Uses Swift Charts'
//  SectorMark, which cleanly expresses this without any hand-rolled arc math.
//

import SwiftUI
import Charts

struct GroupPieChartView: View {
    let group: ActivityGroup

    private enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Woche", month = "Monat", all = "Gesamt"
        var id: String { rawValue }
    }

    @State private var timeRange: TimeRange = .week

    private var dateRange: ClosedRange<Date>? {
        switch timeRange {
        case .week: return (Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now)...Date.now
        case .month: return (Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now)...Date.now
        case .all: return nil
        }
    }

    private var slices: [(button: ActivityButton, count: Int)] {
        group.sortedButtons
            .map { button in
                let entries = dateRange.map { range in button.logEntries.filter { range.contains($0.startDate) } } ?? button.logEntries
                return (button, entries.count)
            }
            .filter { $0.count > 0 }
    }

    private var total: Int { slices.reduce(0) { $0 + $1.1 } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Zeitraum", selection: $timeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                if slices.isEmpty {
                    ContentUnavailableView(
                        "Keine Einträge",
                        systemImage: "chart.pie",
                        description: Text("Für diesen Zeitraum wurden noch keine Aktivitäten dieser Gruppe geloggt.")
                    )
                    .frame(height: 200)
                } else {
                    Chart(slices, id: \.button.id) { slice in
                        SectorMark(
                            angle: .value("Anzahl", slice.count),
                            innerRadius: .ratio(0.55),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color(hex: slice.button.colorHex))
                        .cornerRadius(3)
                    }
                    .frame(height: 240)

                    legend
                }
            }
            .padding()
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var legend: some View {
        VStack(spacing: 10) {
            ForEach(slices, id: \.button.id) { slice in
                HStack {
                    Circle().fill(Color(hex: slice.button.colorHex)).frame(width: 10, height: 10)
                    Text(slice.button.name)
                    Spacer()
                    Text("\(slice.count)").foregroundStyle(.secondary)
                    Text(percentLabel(for: slice.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }
            }
        }
        .card()
    }

    private func percentLabel(for count: Int) -> String {
        guard total > 0 else { return "0%" }
        let percent = Double(count) / Double(total) * 100
        return String(format: "%.0f%%", percent)
    }
}
