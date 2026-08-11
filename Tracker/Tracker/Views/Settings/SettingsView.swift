//
//  SettingsView.swift
//  Tracker
//
//  Root settings list: manage groups/buttons, GitHub backup, HealthKit status.
//  Placeholder body — filled in during the Settings/CRUD, GitHub, and HealthKit milestones.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Gruppen & Buttons") {
                    NavigationLink {
                        GroupListEditView()
                    } label: {
                        Label("Gruppen verwalten", systemImage: "square.grid.2x2")
                    }
                    NavigationLink {
                        EntryHistoryView()
                    } label: {
                        Label("Verlauf", systemImage: "clock")
                    }
                }
                Section("GitHub Backup") {
                    GitHubSettingsView()
                }
                Section("Health") {
                    HealthKitSettingsView()
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    SettingsView()
}
