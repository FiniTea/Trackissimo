//
//  GitHubSettingsView.swift
//  Tracker
//
//  PAT entry (stored in the Keychain, never elsewhere), manual backup/restore
//  actions, and a passive sync-status row.
//

import SwiftUI
import SwiftData

struct GitHubSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    private var backupService: GitHubBackupService { GitHubBackupService.shared }

    @State private var tokenInput = ""
    @State private var hasStoredToken = KeychainStore.read() != nil
    @State private var restoreSummary: String?
    @State private var isRestoring = false

    var body: some View {
        Group {
            if hasStoredToken {
                HStack {
                    Label("Token gespeichert", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Button("Entfernen", role: .destructive) {
                        KeychainStore.delete()
                        hasStoredToken = false
                    }
                    .font(.footnote)
                }

                statusRow

                Button {
                    Task { await backupService.pushSnapshot(modelContext: modelContext) }
                } label: {
                    Label("Jetzt sichern", systemImage: "arrow.up.doc")
                }
                .disabled(backupService.isSyncing)

                Button {
                    Task {
                        isRestoring = true
                        defer { isRestoring = false }
                        do {
                            let result = try await backupService.restore(modelContext: modelContext)
                            restoreSummary = "\(result.groups) Gruppen, \(result.buttons) Buttons, \(result.entries) Einträge, \(result.wellbeing) Stimmungseinträge importiert."
                        } catch {
                            restoreSummary = "Wiederherstellen fehlgeschlagen: \(error.localizedDescription)"
                        }
                    }
                } label: {
                    Label("Von GitHub wiederherstellen", systemImage: "arrow.down.doc")
                }
                .disabled(isRestoring)

                if let restoreSummary {
                    Text(restoreSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                SecureField("GitHub Personal Access Token", text: $tokenInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                Button("Token speichern") {
                    guard !tokenInput.isEmpty else { return }
                    KeychainStore.save(tokenInput)
                    tokenInput = ""
                    hasStoredToken = true
                }
                .disabled(tokenInput.isEmpty)
            }
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        HStack {
            Text("Letzte Sicherung")
            Spacer()
            if backupService.isSyncing {
                ProgressView()
            } else if let lastSync = backupService.lastSyncDate {
                Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            } else {
                Text("Noch nie").foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
        if let error = backupService.lastSyncError {
            Text(error).font(.footnote).foregroundStyle(.red)
        }
    }
}
