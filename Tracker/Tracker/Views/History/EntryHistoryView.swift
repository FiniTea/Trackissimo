//
//  EntryHistoryView.swift
//  Tracker
//
//  Chronological list of logged entries, grouped by day. Pass a `button` to
//  scope the list to just that button's history (e.g. from its stats screen);
//  omit it to see everything logged across all buttons.
//

import SwiftUI
import SwiftData

struct EntryHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    /// Nil shows every entry across all buttons; set to scope to one button.
    var button: ActivityButton?

    @Query(sort: \LogEntry.startDate, order: .reverse) private var allEntries: [LogEntry]

    @State private var editingEntry: LogEntry?
    @State private var entryPendingDelete: LogEntry?

    private var entries: [LogEntry] {
        guard let button else { return allEntries }
        return allEntries.filter { $0.button?.id == button.id }
    }

    private var groupedByDay: [(day: Date, entries: [LogEntry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.startDate) }
        return groups.keys.sorted(by: >).map { day in (day, groups[day] ?? []) }
    }

    var body: some View {
        List {
            ForEach(groupedByDay, id: \.day) { section in
                Section(sectionTitle(for: section.day)) {
                    ForEach(section.entries) { entry in
                        row(for: entry)
                            .contentShape(Rectangle())
                            .onTapGesture { editingEntry = entry }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    entryPendingDelete = entry
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(button?.name ?? "Verlauf")
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "Noch keine Einträge",
                    systemImage: "clock",
                    description: Text("Geloggte Aktivitäten erscheinen hier.")
                )
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(entry: entry)
        }
        .confirmationDialog(
            "Eintrag löschen?",
            isPresented: Binding(get: { entryPendingDelete != nil }, set: { if !$0 { entryPendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                if let entry = entryPendingDelete {
                    modelContext.delete(entry)
                    GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
                }
                entryPendingDelete = nil
            }
            Button("Abbrechen", role: .cancel) { entryPendingDelete = nil }
        }
    }

    @ViewBuilder
    private func row(for entry: LogEntry) -> some View {
        HStack(spacing: 12) {
            if let entryButton = entry.button {
                Text(entryButton.icon)
                    .frame(width: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.button?.name ?? "Gelöschter Button")
                Text(timeLabel(for: entry))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func timeLabel(for entry: LogEntry) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let end = entry.endDate {
            return "\(formatter.string(from: entry.startDate)) – \(formatter.string(from: end))"
        }
        return formatter.string(from: entry.startDate)
    }

    private func sectionTitle(for day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Heute" }
        if Calendar.current.isDateInYesterday(day) { return "Gestern" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: day)
    }
}

#Preview {
    NavigationStack {
        EntryHistoryView()
    }
    .modelContainer(for: LogEntry.self, inMemory: true)
}
