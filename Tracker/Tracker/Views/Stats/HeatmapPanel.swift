//
//  HeatmapPanel.swift
//  Tracker
//
//  Calendar-style heatmap (GitHub-contributions-like), one month at a time with
//  prev/next navigation. Cell shading comes from HeatmapBucketing, driven by
//  the button's own color and its configured `maxFrequency`.
//

import SwiftUI

/// A single day cell in the grid; `date == nil` for the leading/trailing
/// blank cells that pad the first/last week of the displayed month.
private struct HeatmapDay: Identifiable {
    let id = UUID()
    let date: Date?
}

struct HeatmapPanel: View {
    /// Start timestamps of every log entry for this button (all-time — the
    /// panel filters down to whatever month is displayed).
    let entryDates: [Date]
    let baseColor: Color
    let maxFrequency: Int

    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: .now)

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday-first grid, matching the old app.
        return cal
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: displayedMonth)
    }

    private var gridDays: [HeatmapDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstOfMonth = monthInterval.start
        // How far the 1st of the month sits into its Monday-first week (0 = Monday).
        let weekdayOfFirst = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7

        var days: [HeatmapDay] = Array(repeating: HeatmapDay(date: nil), count: weekdayOfFirst)
        var cursor = firstOfMonth
        while cursor < monthInterval.end {
            days.append(HeatmapDay(date: cursor))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? monthInterval.end
        }
        // Pad the trailing partial week so the grid always ends on a full row.
        while days.count % 7 != 0 {
            days.append(HeatmapDay(date: nil))
        }
        return days
    }

    private func count(on date: Date) -> Int {
        entryDates.filter { calendar.isDate($0, inSameDayAs: date) }.count
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthLabel).font(.subheadline.weight(.semibold))
                Spacer()
                Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                    .disabled(calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(weekdayHeaderSymbols, id: \.self) { symbol in
                    Text(symbol).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(gridDays) { day in
                    dayCell(day)
                }
            }

            legend
        }
        .card()
    }

    @ViewBuilder
    private func dayCell(_ day: HeatmapDay) -> some View {
        if let date = day.date {
            let bucket = HeatmapBucketing.bucket(for: count(on: date), maxFrequency: maxFrequency)
            RoundedRectangle(cornerRadius: 4)
                .fill(HeatmapBucketing.shade(baseColor: baseColor, bucket: bucket))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 9))
                        .foregroundStyle(bucket >= 3 ? .white : .primary)
                )
        } else {
            Color.clear.aspectRatio(1, contentMode: .fit)
        }
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Text("Wenig").font(.caption2).foregroundStyle(.secondary)
            ForEach(0...HeatmapBucketing.shadeBucketCount, id: \.self) { bucket in
                RoundedRectangle(cornerRadius: 3)
                    .fill(HeatmapBucketing.shade(baseColor: baseColor, bucket: bucket))
                    .frame(width: 16, height: 16)
            }
            Text("Viel").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var weekdayHeaderSymbols: [String] {
        ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    }

    private func changeMonth(by delta: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}
