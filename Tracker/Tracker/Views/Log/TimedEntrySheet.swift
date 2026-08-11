//
//  TimedEntrySheet.swift
//  Tracker
//
//  Shown when a "timed" button (e.g. "Sofie") is tapped: asks for a start and
//  end time via two native wheel pickers, snapped to 15-minute steps. Supports
//  ranges that cross midnight (e.g. 22:00 -> 02:00) by simply requiring the end
//  clock-time to roll onto the next day whenever it isn't after the start
//  clock-time — the user doesn't need to pick a date explicitly.
//

import SwiftUI
import SwiftData

/// The 15-minute steps offered in the minute wheel.
private let quarterHourSteps = [0, 15, 30, 45]

struct TimedEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let button: ActivityButton
    /// Called after a successful save, in addition to dismissing this sheet —
    /// lets callers distinguish an actual save from a cancel.
    var onSave: () -> Void = {}

    @State private var startHour: Int
    @State private var startQuarter: Int
    @State private var endHour: Int
    @State private var endQuarter: Int

    init(button: ActivityButton, onSave: @escaping () -> Void = {}) {
        self.button = button
        self.onSave = onSave
        let now = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let nowHour = now.hour ?? 12
        let nowQuarter = Self.nearestQuarter(for: now.minute ?? 0)
        _startHour = State(initialValue: nowHour)
        _startQuarter = State(initialValue: nowQuarter)
        _endHour = State(initialValue: nowHour)
        _endQuarter = State(initialValue: nowQuarter)
    }

    private static func nearestQuarter(for minute: Int) -> Int {
        quarterHourSteps.min(by: { abs($0 - minute) < abs($1 - minute) }) ?? 0
    }

    /// True when the end clock-time rolls onto the next calendar day (i.e. isn't
    /// strictly after the start clock-time within the same day).
    private var crossesMidnight: Bool {
        (endHour * 60 + endQuarter) <= (startHour * 60 + startQuarter)
    }

    private var durationLabel: String {
        let startMinutes = startHour * 60 + startQuarter
        var endMinutes = endHour * 60 + endQuarter
        if crossesMidnight { endMinutes += 24 * 60 }
        let totalMinutes = endMinutes - startMinutes
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes) Min." }
        if minutes == 0 { return "\(hours) Std." }
        return "\(hours) Std. \(minutes) Min."
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Start") {
                    timeWheel(hour: $startHour, quarter: $startQuarter)
                }
                Section {
                    timeWheel(hour: $endHour, quarter: $endQuarter)
                } header: {
                    Text("Ende")
                } footer: {
                    if crossesMidnight {
                        Text("Endet am nächsten Tag · Dauer: \(durationLabel)")
                    } else {
                        Text("Dauer: \(durationLabel)")
                    }
                }
            }
            .navigationTitle(button.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func timeWheel(hour: Binding<Int>, quarter: Binding<Int>) -> some View {
        HStack {
            Picker("Stunde", selection: hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d Uhr", h)).tag(h)
                }
            }
            .pickerStyle(.wheel)

            Picker("Minute", selection: quarter) {
                ForEach(quarterHourSteps, id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 110)
    }

    private func save() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(bySettingHour: startHour, minute: startQuarter, second: 0, of: today) ?? .now
        var end = calendar.date(bySettingHour: endHour, minute: endQuarter, second: 0, of: today) ?? .now
        if crossesMidnight {
            end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        }

        let entry = LogEntry(startDate: start, endDate: end, button: button)
        modelContext.insert(entry)
        GitHubBackupService.shared.scheduleSync(modelContext: modelContext)

        onSave()
        dismiss()
    }
}
