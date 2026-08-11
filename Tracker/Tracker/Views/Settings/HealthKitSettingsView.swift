//
//  HealthKitSettingsView.swift
//  Tracker
//
//  Shows HealthKit connection status and offers to (re-)request authorization,
//  plus a manual retry for any wellbeing entries whose Health mirror failed.
//

import SwiftUI
import SwiftData

struct HealthKitSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WellbeingEntry> { $0.healthKitSynced == false }) private var unsyncedEntries: [WellbeingEntry]

    @State private var isAuthorizing = false
    @State private var isRetrying = false
    @State private var authError: String?

    var body: some View {
        Group {
            if !HealthKitManager.shared.isHealthDataAvailable {
                Label("Health nicht verfügbar auf diesem Gerät", systemImage: "heart.slash")
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    Task {
                        isAuthorizing = true
                        do {
                            try await HealthKitManager.shared.requestAuthorization()
                            authError = nil
                        } catch {
                            authError = "Verbinden fehlgeschlagen: \(error.localizedDescription)"
                        }
                        isAuthorizing = false
                    }
                } label: {
                    Label("Health verbinden", systemImage: "heart")
                }
                .disabled(isAuthorizing)

                if let authError {
                    Text(authError).font(.footnote).foregroundStyle(.red)
                }

                if !unsyncedEntries.isEmpty {
                    Button {
                        Task {
                            isRetrying = true
                            await HealthKitManager.shared.retryFailedWellbeingSyncs(modelContext: modelContext)
                            isRetrying = false
                        }
                    } label: {
                        Label("\(unsyncedEntries.count) Einträge erneut synchronisieren", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(isRetrying)
                }
            }
        }
    }
}
