//
//  BarChartPanel.swift
//  Tracker
//
//  Reusable 3-panel bar chart: last 7 days, recent ISO calendar weeks, and the
//  last 12 calendar months. Used both for activity-button stats (unit "mal")
//  and sleep duration (unit "h") — the panel itself only knows about already-
//  bucketed `BucketPoint`s, all the calendar math lives in StatsEngine.
//

import SwiftUI
import Charts

struct BarChartPanel: View {
    let color: Color
    let dailyPoints: [BucketPoint]
    let weeklyPoints: [BucketPoint]
    let monthlyPoints: [BucketPoint]
    /// Appended after the tapped value, e.g. "3 mal" or "7.5 h".
    let unit: String

    var body: some View {
        VStack(spacing: 20) {
            BarChartSection(title: "Letzte 7 Tage", points: dailyPoints, color: color, unit: unit)
            BarChartSection(title: "Kalenderwochen", points: weeklyPoints, color: color, unit: unit)
            BarChartSection(title: "Letzte 12 Monate", points: monthlyPoints, color: color, unit: unit)
        }
    }
}

/// One of the three panels: a titled card containing a bar chart where tapping
/// a bar reveals its exact value in a small overlay bubble (mirrors the old
/// HTML app's simple tap-to-reveal tooltip, without a full popover system).
private struct BarChartSection: View {
    let title: String
    let points: [BucketPoint]
    let color: Color
    let unit: String

    @State private var selectedLabel: String?

    private var selectedPoint: BucketPoint? {
        points.first { $0.label == selectedLabel }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                if let selectedPoint {
                    Text("\(formattedValue(selectedPoint.value)) \(unit)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                }
            }

            Chart(points) { point in
                BarMark(
                    x: .value("Zeitraum", point.label),
                    y: .value("Wert", point.value)
                )
                .foregroundStyle(color.opacity(point.label == selectedLabel ? 1 : 0.7))
                .cornerRadius(4)
            }
            .frame(height: 140)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    // A plain tap (SpatialTapGesture), not a DragGesture: a
                    // zero-distance drag claims every touch-move immediately,
                    // which hijacks the enclosing ScrollView's pan gesture and
                    // makes the whole stats screen impossible to scroll once a
                    // touch starts over a chart. A discrete tap doesn't compete
                    // with scrolling the same way.
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    let originX = geometry[proxy.plotFrame!].origin.x
                                    let relativeX = value.location.x - originX
                                    if let label: String = proxy.value(atX: relativeX) {
                                        selectedLabel = label
                                    }
                                }
                        )
                }
            }
        }
        .card()
    }

    private func formattedValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}
