//
//  HealthTabView.swift
//  Tracker
//
//  "Gesundheit" section: wellbeing stats (always available, app-internal data)
//  plus sleep stats (read from HealthKit, filled in during the HealthKit milestone).
//

import SwiftUI

struct HealthTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        WellbeingStatsView()
                    } label: {
                        Label("Stimmung", systemImage: "face.smiling")
                    }
                }
                Section {
                    NavigationLink {
                        SleepStatsView()
                    } label: {
                        Label("Schlaf", systemImage: "bed.double.fill")
                    }
                } footer: {
                    Text("Schlafdaten werden aus Apple Health gelesen. Verbinde Health in den Einstellungen.")
                }
            }
            .navigationTitle("Gesundheit")
        }
    }
}

#Preview {
    HealthTabView()
}
