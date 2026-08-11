//
//  StatsEngine.swift
//  Tracker
//
//  Shared time-bucketing logic for every chart in the app (activity bar charts,
//  sleep duration, wellbeing averages). Deliberately pure Swift/Foundation, no
//  SwiftUI or SwiftData imports — callers fetch their own raw data (SwiftData
//  #Predicate can't do calendar-component math like "this ISO week" or "this
//  weekday", so we don't fight that: pull a coarse date-bounded array, then
//  bucket it here with plain Calendar arithmetic).
//

import Foundation

/// One bucketed data point ready to plot (a day, an ISO week, or a month).
struct BucketPoint: Identifiable {
    let id = UUID()
    /// Short axis label, e.g. "Mo", "KW32", "Aug".
    let label: String
    /// The bucket's representative date (its start), used for sorting/tooltips.
    let date: Date
    /// Summed/aggregated value for this bucket (a count, or a duration in hours).
    let value: Double
}

/// A weekday-keyed average, used by the "all weekdays" wellbeing view.
struct WeekdayAverage: Identifiable {
    /// 1 = Sunday ... 7 = Saturday, matching `Calendar.component(.weekday)`.
    let weekday: Int
    let label: String
    let average: Double?

    var id: Int { weekday }
}

enum StatsEngine {
    /// An ISO-8601 calendar (Monday-first weeks, week 1 = the week containing
    /// the year's first Thursday) used everywhere week-of-year math happens, so
    /// results don't shift based on the device's region settings.
    static var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar
    }

    // MARK: - Daily (rolling last N days)

    /// Counts/sums `points` per calendar day for the last `days` days
    /// (inclusive of today), oldest first. Days with no data get value 0 so bar
    /// charts always show a full, evenly-spaced axis.
    static func dailyBuckets(_ points: [(date: Date, value: Double)], days: Int = 7, calendar: Calendar = .current) -> [BucketPoint] {
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        formatter.locale = Locale(identifier: "de_DE")

        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let sum = points
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.value }
            return BucketPoint(label: formatter.string(from: day), date: day, value: sum)
        }
    }

    // MARK: - ISO calendar weeks (rolling last N weeks)

    static func weeklyBuckets(_ points: [(date: Date, value: Double)], weeks: Int = 12) -> [BucketPoint] {
        let calendar = isoCalendar
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now

        return (0..<weeks).reversed().compactMap { offset -> BucketPoint? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeekStart) else { return nil }
            let weekNumber = calendar.component(.weekOfYear, from: weekStart)
            let sum = points
                .filter { calendar.isDate($0.date, equalTo: weekStart, toGranularity: .weekOfYear) }
                .reduce(0) { $0 + $1.value }
            return BucketPoint(label: "KW\(weekNumber)", date: weekStart, value: sum)
        }
    }

    // MARK: - Calendar months (rolling last N months)

    static func monthlyBuckets(_ points: [(date: Date, value: Double)], months: Int = 12, calendar: Calendar = .current) -> [BucketPoint] {
        let currentMonthStart = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "de_DE")

        return (0..<months).reversed().compactMap { offset -> BucketPoint? in
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentMonthStart) else { return nil }
            let sum = points
                .filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
                .reduce(0) { $0 + $1.value }
            return BucketPoint(label: formatter.string(from: monthStart), date: monthStart, value: sum)
        }
    }

    // MARK: - Weekday grouping (for the wellbeing "all weekdays" view)

    static func weekdayAverages(_ points: [(date: Date, value: Double)], calendar: Calendar = .current) -> [WeekdayAverage] {
        let symbols = ["", "So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"] // index 1...7 matches Calendar.component(.weekday)
        return (1...7).map { weekday in
            let matching = points.filter { calendar.component(.weekday, from: $0.date) == weekday }
            let average = matching.isEmpty ? nil : matching.reduce(0) { $0 + $1.value } / Double(matching.count)
            return WeekdayAverage(weekday: weekday, label: symbols[weekday], average: average)
        }
    }

    // MARK: - Plain range average (for wellbeing week/month/year averages)

    static func average(_ points: [(date: Date, value: Double)], in range: ClosedRange<Date>) -> Double? {
        let matching = points.filter { range.contains($0.date) }
        guard !matching.isEmpty else { return nil }
        return matching.reduce(0) { $0 + $1.value } / Double(matching.count)
    }
}
