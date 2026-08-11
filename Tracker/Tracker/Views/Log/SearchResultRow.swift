//
//  SearchResultRow.swift
//  Tracker
//
//  A single row in the fuzzy-search results on the Log tab. Reuses the same tap
//  dispatch as ActivityButtonCell (instant log / open timed sheet), just
//  rendered as a list row with group context instead of a grid tile.
//

import SwiftUI
import SwiftData

struct SearchResultRow: View {
    @Environment(\.modelContext) private var modelContext
    let button: ActivityButton

    @State private var showTimedSheet = false
    @State private var isCoolingDown = false

    var body: some View {
        Button {
            handleTap()
        } label: {
            HStack(spacing: 12) {
                Text(button.icon)
                    .font(.title3)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(button.name).foregroundStyle(.primary)
                    if let groupName = button.group?.name {
                        Text(groupName).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .disabled(isCoolingDown)
        .sheet(isPresented: $showTimedSheet) {
            TimedEntrySheet(button: button)
        }
    }

    private func handleTap() {
        guard !isCoolingDown else { return }
        switch button.loggingMode {
        case .instant:
            let entry = LogEntry(button: button)
            modelContext.insert(entry)
            GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
            isCoolingDown = true
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                isCoolingDown = false
            }
        case .timed:
            showTimedSheet = true
        }
    }
}
