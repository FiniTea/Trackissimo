//
//  GroupEditSheet.swift
//  Tracker
//
//  Create or edit a single ActivityGroup: name, accent color, and whether it
//  shows the group-level pie chart on the Stats tab.
//

import SwiftUI
import SwiftData

struct GroupEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// Nil when creating a new group; set when editing an existing one.
    var groupToEdit: ActivityGroup?

    @State private var name: String = ""
    @State private var colorHex: String = "#3B82F6"
    @State private var showsPieChart: Bool = false

    private var isEditing: Bool { groupToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z.B. Badezimmer", text: $name)
                }

                Section {
                    ColorPickerRow(colorHex: $colorHex)
                }

                Section {
                    Toggle("Kreisdiagramm anzeigen", isOn: $showsPieChart)
                } footer: {
                    Text("Zeigt in den Statistiken den Anteil jedes Buttons dieser Gruppe an allen Einträgen der Gruppe.")
                }
            }
            .navigationTitle(isEditing ? "Gruppe bearbeiten" : "Neue Gruppe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let group = groupToEdit else { return }
        name = group.name
        colorHex = group.colorHex ?? "#3B82F6"
        showsPieChart = group.showsPieChart
    }

    private func save() {
        if let group = groupToEdit {
            group.name = name
            group.colorHex = colorHex
            group.showsPieChart = showsPieChart
        } else {
            let maxSortOrder = (try? modelContext.fetch(FetchDescriptor<ActivityGroup>()))?.map(\.sortOrder).max() ?? -1
            let newGroup = ActivityGroup(name: name, sortOrder: maxSortOrder + 1, colorHex: colorHex, showsPieChart: showsPieChart)
            modelContext.insert(newGroup)
        }
        GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
        dismiss()
    }
}

#Preview {
    GroupEditSheet()
        .modelContainer(for: ActivityGroup.self, inMemory: true)
}
