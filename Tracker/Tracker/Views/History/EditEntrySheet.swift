//
//  EditEntrySheet.swift
//  Tracker
//
//  Correct a past LogEntry's timestamp(s) — e.g. if a button was tapped by
//  accident at the wrong time, or a timed entry's range needs adjusting.
//

import SwiftUI
import SwiftData

struct EditEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let entry: LogEntry

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isTimed: Bool

    init(entry: LogEntry) {
        self.entry = entry
        _startDate = State(initialValue: entry.startDate)
        _endDate = State(initialValue: entry.endDate ?? entry.startDate)
        _isTimed = State(initialValue: entry.isTimed)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(entry.button?.name ?? "Eintrag") {
                    DatePicker("Start", selection: $startDate)
                    if isTimed {
                        DatePicker("Ende", selection: $endDate, in: startDate...)
                    }
                }
            }
            .navigationTitle("Eintrag bearbeiten")
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

    private func save() {
        entry.startDate = startDate
        entry.endDate = isTimed ? endDate : nil
        GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
        dismiss()
    }
}
