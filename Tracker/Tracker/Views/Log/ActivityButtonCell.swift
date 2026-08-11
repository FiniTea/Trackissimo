//
//  ActivityButtonCell.swift
//  Tracker
//
//  The tappable tile for a single button on the Log tab. Dispatches based on
//  the button's configuration: logs instantly, or opens the timed-entry sheet.
//

import SwiftUI
import SwiftData

struct ActivityButtonCell: View {
    @Environment(\.modelContext) private var modelContext
    let button: ActivityButton

    @State private var showTimedSheet = false
    /// Very short guard against double-fire from a single physical tap (touch
    /// bounce / accidental fast double-tap) — not a visible cooldown, just
    /// disables the button for 300ms after each tap per the user's request.
    @State private var isCoolingDown = false
    @State private var justLogged = false

    var body: some View {
        Button {
            handleTap()
        } label: {
            VStack(spacing: 8) {
                Text(button.icon)
                    .font(.title2)
                Text(button.name)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .card(tint: Color(hex: button.colorHex))
            .scaleEffect(justLogged ? 0.93 : 1)
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
            logInstantly()
        case .timed:
            showTimedSheet = true
        }
    }

    private func logInstantly() {
        let entry = LogEntry(button: button)
        modelContext.insert(entry)
        GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
        Haptics.logged()

        isCoolingDown = true
        withAnimation(.easeOut(duration: 0.1)) { justLogged = true }

        Task {
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeIn(duration: 0.1)) { justLogged = false }
            try? await Task.sleep(for: .milliseconds(180))
            isCoolingDown = false
        }
    }
}
